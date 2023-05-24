/*
 * function : take packets with ethernet frames from NoC and output write
 *            requests to DDR3 on an avalon bus
 * author   : Mohamed S. Abdelfattah
 * date     : 13-MAR-2015
 */

module tb_pkts_to_ddr();


// AVL SIDE ////////////
parameter AVL_ADDR_WIDTH = 29;
parameter AVL_DATA_WIDTH = 512;
parameter AVL_BYTE_EN_WIDTH = AVL_DATA_WIDTH/8;
parameter FRAME_ID_WIDTH = 4+28; //4 bits for each port, and 14 bits for each frame 2^14 = 16384
parameter BIN_ADDR_WIDTH = 8;    // how many frame buffers will we have
parameter FRAME_OFFSET_WIDTH = 5;  // what is the maximum frame length in (4-flit) cycles?
                                       // the frame offset is log2 that value

// NOC SIDE ////////////
parameter WIDTH_PKT = AVL_DATA_WIDTH+1+1+FRAME_ID_WIDTH; //this is the data width after the translator strips away the flit headers

reg clk;
reg rst;

// NOC SIDE ////////////////////////////

//packets coming out of NoC (fp output)
//use depacketizer_sop to allow variable-length packets
wire [WIDTH_PKT-1:0] noc_data_in;
wire           [3:0] noc_valid_in;
wire                 noc_ready_out;
wire           [3:0] noc_sop_in;
wire           [3:0] noc_eop_in;

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

assign avl_waitrequest = 0;

initial 
begin
    clk = 0;
    rst = 1;
    #20
    rst = 0;
end


always #5 clk = ~clk;



pkt_generator #() pkt_gen( .* );

avl_shim #() avl_shim_inst( .* );

pkts_to_ddr_sm #() dut(
    .clk(clk),
    .rst(rst),

    .noc_data_in(noc_data_out),
    .noc_valid_in(noc_valid_out),
    .noc_ready_out(noc_ready_in),
    .noc_sop_in(noc_sop_out),
    .noc_eop_in(noc_eop_out),

    .avl_writedata(avl_writedata),
    .avl_address(avl_address),
    .avl_write(avl_write),
    .avl_read(avl_read),
    .avl_readdata(avl_readdata),
    .avl_byteenable(avl_byteenable),
    .avl_readdatavalid(avl_readdatavalid),

    .avl_waitrequest(avl_waitrequest)

);


endmodule
