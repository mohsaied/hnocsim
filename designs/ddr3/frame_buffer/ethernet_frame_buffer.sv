/*
 * function : take packets with ethernet frames from NoC and output write
 *            requests to DDR3 on an avalon bus
 * author   : Mohamed S. Abdelfattah
 * date     : 13-MAR-2015
 */


`timescale 1 ps / 1 ps

module ethernet_frame_buffer #(
 
    // AVL SIDE ////////////
    parameter AVL_ADDR_WIDTH = 29,
    parameter AVL_DATA_WIDTH = 512,
    parameter AVL_BYTE_EN_WIDTH = AVL_DATA_WIDTH/8,
    parameter FRAME_ID_WIDTH = 4+28, //4 bits for each port, and 14 bits for each frame
    parameter BIN_ADDR_WIDTH = 8,    // how many frame buffers will we have
    parameter FRAME_OFFSET_WIDTH = 5,  // what is the maximum frame length in nocunits?                                         // the frame offset is log2 that value

    // NOC SIDE ////////////
    parameter NOC_ADDR_WIDTH = 4,
	parameter WIDTH_PKT = AVL_DATA_WIDTH+1+1+FRAME_ID_WIDTH //this is the data width after the translator strips away the flit headers
)
(
    output wire clk,
    output wire rst,

    input wire [WIDTH_PKT-1:0] top_noc_data_in,
    input wire           [3:0] top_noc_valid_in,
    output wire                top_noc_ready_out,
    input wire           [3:0] top_noc_sop_in,
    input wire           [3:0] top_noc_eop_in,

    output wire      [WIDTH_PKT-1:0] top_noc_data_out,
    output wire [NOC_ADDR_WIDTH-1:0] top_noc_dest_out,
    output wire                [3:0] top_noc_valid_out,
    input wire                       top_noc_ready_in,
    output wire                [3:0] top_noc_sop_out,
    output wire                [3:0] top_noc_eop_out
);



wire [WIDTH_PKT-1:0] noc_data_out;
wire           [3:0] noc_valid_out;
wire                 noc_ready_in;
wire           [3:0] noc_sop_out;
wire           [3:0] noc_eop_out;


// DDR3 AVL SIDE ///////////////////////
    
//slave

wire    [AVL_DATA_WIDTH-1:0] avl_writedata;
wire    [AVL_ADDR_WIDTH-1:0] avl_address;
wire                         avl_write;
wire                         avl_read;
wire    [AVL_DATA_WIDTH-1:0] avl_readdata;
wire [AVL_BYTE_EN_WIDTH-1:0] avl_byteenable;
wire                         avl_readdatavalid;

wire                         avl_waitrequest;



avl_shim #() noc_to_avl(
    .clk(clk),
    .rst(rst),
    
    .noc_data_in(top_noc_data_in),
	.noc_valid_in(top_noc_valid_in),
	.noc_ready_out(top_noc_ready_out),
    .noc_sop_in(top_noc_sop_in),
    .noc_eop_in(top_noc_eop_in),
    
    .noc_data_out(noc_data_out),
    .noc_valid_out(noc_valid_out),
    .noc_ready_in(noc_ready_in),
    .noc_sop_out(noc_sop_out),
    .noc_eop_out(noc_eop_out)
);


frame_buffer #() dut(
    .clk(clk),
    .rst(rst),
    
    .noc_data_in(noc_data_out),
    .noc_valid_in(noc_valid_out),
    .noc_ready_out(noc_ready_in),
    .noc_sop_in(noc_sop_out),
    .noc_eop_in(noc_eop_out),

    .noc_data_out(top_noc_data_out),
    .noc_valid_out(top_noc_valid_out),
    .noc_ready_in(top_noc_ready_in),
    .noc_sop_out(top_noc_sop_out),
    .noc_eop_out(top_noc_eop_out),
    .noc_dest_out(top_noc_dest_out),

    .avl_writedata(avl_writedata),
    .avl_address(avl_address),
    .avl_write(avl_write),
    .avl_read(avl_read),
    .avl_readdata(avl_readdata),
    .avl_byteenable(avl_byteenable),
    .avl_readdatavalid(avl_readdatavalid),
    .avl_waitrequest(avl_waitrequest)
);


wire rstn;
assign rst = ~rstn;

ddr3_top ddr3_inst(
    .e0_afi_clk_clk               (clk),                      // avl_clock.clk
	.e0_afi_reset_reset           (rstn),                     // avl_reset.reset_n
	.d0_avl_waitrequest           (avl_waitrequest),          //       avl.waitrequest_n
	.d0_avl_address               (avl_address),              //          .address
	.d0_avl_burstcount            (avl_burstcount),           //          .burstcount
	.d0_avl_writedata             (avl_writedata),            //          .writedata
	.d0_avl_readdata              (avl_readdata),             //          .readdata
	.d0_avl_write                 (avl_write),                //          .write
	.d0_avl_read                  (avl_read),                 //          .read
	.d0_avl_readdatavalid         (avl_readdatavalid),        //          .readdatavalid
	.d0_avl_byteenable            (avl_byteenable)            //          .byteenable
);

endmodule
