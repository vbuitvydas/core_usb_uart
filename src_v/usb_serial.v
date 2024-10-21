module usb_serial
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter BAUDRATE         = 1000000
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
      output          uart_rx_o
    , input           uart_tx_i

    // ULPI Interface
    , output          ulpi_reset_o
    , inout [7:0]     ulpi_data_io
    , output          ulpi_stp_o
    , input           ulpi_nxt_i
    , input           ulpi_dir_i
    , input           ulpi_clk60_i
    , input           reset_in 
    , output          reset_out
);

// USB clock / reset
wire usb_clk_w;
wire usb_rst_w;

wire clk_bufg_w;
//IBUF u_ibuf ( .I(ulpi_clk60_i), .O(clk_bufg_w) );
//BUFG u_bufg ( .I(clk_bufg_w),   .O(usb_clk_w) );

assign usb_clk_w = ulpi_clk60_i;

reg [3:0] count_q = 4'b0;
reg       rst_q   = 1'b1;

always @(posedge usb_clk_w) 
if (reset_in) 
    count_q <= 0;
else if (count_q != 4'hF)
    count_q <= count_q + 4'd1;


always @(posedge usb_clk_w) 
if (reset_in) 
    rst_q <= 1'b1;
else if (count_q == 4'hF)
    rst_q <= 1'b0;

assign usb_rst_w = rst_q;
assign reset_out = usb_rst_w;

// ULPI Buffers
wire [7:0] ulpi_out_w;
wire [7:0] ulpi_in_w;
wire       ulpi_stp_w;

genvar i;
generate  
for (i=0; i < 8; i=i+1)  
begin: gen_buf
    IOBUF 
    #(
        .DRIVE(12),
        .IOSTANDARD("DEFAULT"),
        .SLEW("FAST")
    )
    IOBUF_inst
    (
        .T(ulpi_dir_i),
        .I(ulpi_out_w[i]),
        .O(ulpi_in_w[i]),
        .IO(ulpi_data_io[i])
    );
end  
endgenerate  

OBUF 
#(
    .DRIVE(12),
    .IOSTANDARD("DEFAULT"),
    .SLEW("FAST")
)
OBUF_stp
(
    .I(ulpi_stp_w),
    .O(ulpi_stp_o)
);

// USB Core
usb_cdc_top
#( .BAUDRATE(BAUDRATE) )
u_usb
(
     .clk_i(usb_clk_w)
    ,.rst_i(usb_rst_w)

    // ULPI
    ,.ulpi_data_out_i(ulpi_in_w)
    ,.ulpi_dir_i(ulpi_dir_i)
    ,.ulpi_nxt_i(ulpi_nxt_i)
    ,.ulpi_data_in_o(ulpi_out_w)
    ,.ulpi_stp_o(ulpi_stp_w)

    ,.tx_i(uart_tx_i)
    ,.rx_o(uart_rx_o)
);

assign ulpi_reset_o = !reset_in;

endmodule