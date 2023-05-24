/*
 * function : take packets with ethernet frames from NoC and output write
 *            requests to DDR3 on an avalon bus
 * author   : Mohamed S. Abdelfattah
 * date     : 13-MAR-2015
 */


`timescale 1 ps / 1 ps

module testbench();


// AVL SIDE ////////////
parameter AVL_ADDR_WIDTH = 29;
parameter AVL_DATA_WIDTH = 512;
parameter AVL_BYTE_EN_WIDTH = AVL_DATA_WIDTH/8;
parameter FRAME_ID_WIDTH = 4+28; //4 bits for each port, and 14 bits for each frame 2^14 = 16384
parameter BIN_ADDR_WIDTH = 8;    // how many frame buffers will we have
parameter FRAME_OFFSET_WIDTH = 5;  // what is the maximum frame length in (4-flit) cycles?
                                       // the frame offset is log2 that value

// NOC SIDE ////////////
parameter NOC_ADDR_WIDTH = 4;
parameter WIDTH_PKT = AVL_DATA_WIDTH+1+1+FRAME_ID_WIDTH; //this is the data width after the translator strips away the flit headers

reg clk;
reg rst;

// NOC SIDE ////////////////////////////

// top-level ports
wire [WIDTH_PKT-1:0] top_noc_data_in;
wire           [3:0] top_noc_valid_in;
wire                 top_noc_ready_out;
wire           [3:0] top_noc_sop_in;
wire           [3:0] top_noc_eop_in;

wire      [WIDTH_PKT-1:0] top_noc_data_out;
wire [NOC_ADDR_WIDTH-1:0] top_noc_dest_out;
wire                [3:0] top_noc_valid_out;
wire                      top_noc_ready_in;
wire                [3:0] top_noc_sop_out;
wire                [3:0] top_noc_eop_out;

integer i;
reg ready;

initial 
begin
    clk = 0;
    rst = 1;
    #20
    rst = 0;
    
    ready = 0;
    for(i = 0; i < 3;i=i+1)
        @(posedge clk);
    ready=1;
    for(i = 0; i < 3;i=i+1)
        @(posedge clk);
    ready=0;
    for(i = 0; i < 3;i=i+1)
        @(posedge clk);
    ready=1;
end

assign top_noc_ready_in = ready;


always #5 clk = ~clk;


pkt_generator #() pkt_gen( 
    
    .clk(clk),
    .rst(rst),

    .noc_data_in(top_noc_data_in),
    .noc_valid_in(top_noc_valid_in),
    .noc_ready_out(top_noc_ready_out),
    .noc_sop_in(top_noc_sop_in),
    .noc_eop_in(top_noc_eop_in)
);

avl_shim #() noc_to_avl(
    .clk(clk),
    .rst(rst),
    
    .noc_data_in(top_noc_data_in),
	.noc_valid_in(top_noc_valid_in),
	.noc_ready_out(top_noc_ready_out),
    .noc_sop_in(top_noc_sop_in),
    .noc_eop_in(top_noc_eop_in),
    
    .noc_data_out(top_noc_data_out),
    .noc_valid_out(top_noc_valid_out),
    .noc_ready_in(top_noc_ready_in),
    .noc_sop_out(top_noc_sop_out),
    .noc_eop_out(top_noc_eop_out)
);

endmodule
