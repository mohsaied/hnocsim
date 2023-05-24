/*
 * function : translate avalon MM interface to fabricport (lynx) protocol
 * author   : Mohamed S. Abdelfattah
 * date     : 08-MAR-2015
 */

module avalon_mm_shim
#(
    // AVL SIDE ////////////
    parameter AVL_ADDR_WIDTH = 29,
    parameter AVL_DATA_WIDTH = 512,
    parameter AVL_BYTE_EN_WIDTH = AVL_DATA_WIDTH/8,
    
    // NOC SIDE ////////////
	parameter WIDTH_PKT = 36
)
(
    input clk,
    input rst,

    // AVL SIDE ///////////////////////
    
    //master
    input  wire    [AVL_DATA_WIDTH-1:0] avlm_writedata,
    input  wire    [AVL_ADDR_WIDTH-1:0] avlm_address,
    input  wire                         avlm_write, //noc valid is write & read
    input  wire                         avlm_read,
    output wire    [AVL_DATA_WIDTH-1:0] avlm_readdata,
    input  wire [AVL_BYTE_EN_WIDTH-1:0] avlm_byteenable,
    output wire                         avlm_readdatavalid,
    
    input  wire                         avlm_ready_in, // I invented this signal!
    output wire                         avlm_ready_out, // I invented this signal!

    //slave
    output wire    [AVL_DATA_WIDTH-1:0] avls_writedata,
    output wire    [AVL_ADDR_WIDTH-1:0] avls_address,
    output wire                         avls_write,
    output wire                         avls_read,
    input  wire    [AVL_DATA_WIDTH-1:0] avls_readdata,
    output wire [AVL_BYTE_EN_WIDTH-1:0] avls_byteenable,
    input  wire                         avls_readdatavalid,

    input  wire                         avls_waitrequest,
    //need to be able to stop the ddr3 module with backpressure from noc
    //but it does not respond to backpressure!
    //this means that I have to do something smart
    //for example: buffer all read requests until the reply is accepted at the NoC


    // NOC SIDE ///////////////////////

    //master

    //packets going in NoC (fp input)
    output wire [WIDTH_PKT-1:0] nocm_data_out,
	output wire                 nocm_valid_out,
	input  wire                 nocm_ready_in,
	
    //packets coming out of NoC (fp output)
	input  wire [WIDTH_PKT-1:0] nocm_data_in,
	input  wire                 nocm_valid_in,
	output wire                 nocm_ready_out,

    //slave

    //packets going in NoC (fp input)
    output wire [WIDTH_PKT-1:0] nocs_data_out,
	output wire                 nocs_valid_out,
	input  wire                 nocs_ready_in,
	
    //packets coming out of NoC (fp output)
	input  wire [WIDTH_PKT-1:0] nocs_data_in,
	input  wire                 nocs_valid_in,
	output wire                 nocs_ready_out
);

//-------------------------------------------------------------------------
// Implementation
//-------------------------------------------------------------------------

// byte enable encoding/decoding
// assume that we always get contiguous bytes
// so we only encode the most significant one

localparam BIN_BYTE_EN_WIDTH = $clog2(AVL_BYTE_EN_WIDTH);
// at which bit does each piece of data start?
localparam DATA_POS    = 0;
localparam ADDR_POS    = DATA_POS + AVL_DATA_WIDTH;
localparam WRITE_POS   = ADDR_POS + AVL_ADDR_WIDTH;
localparam READ_POS    = WRITE_POS + 1;
localparam BYTE_EN_POS = READ_POS + AVL_ADDR_WIDTH;

wire [BIN_BYTE_EN_WIDTH-1:0] bin_byteenable_out;

encoder #(
    .num_ports(AVL_BYTE_EN_WIDTH)
) enc_inst (
    .data_in(avlm_byteenable),
    .data_out(bin_byteenable_out)
);

decoder #(
    .num_ports(AVL_BYTE_EN_WIDTH)
) dec_inst (
    .data_in(nocs_data_in[BYTE_EN_POS -: BIN_BYTE_EN_WIDTH]),
    .data_out(avls_byteenable)
);

//-----------------------------------------------------
// AVL MASTER --> NOC
//-----------------------------------------------------

assign nocm_valid_out = (avlm_read | avlm_write) & avlm_ready_in; 
assign nocm_data_out  = {avlm_writedata, avlm_address, avlm_write, avlm_read, bin_byteenable_out};
assign avlm_ready_out = nocm_ready_in; 

//-----------------------------------------------------
// AVL MASTER <-- NOC
//-----------------------------------------------------

assign avlm_readdata      = nocm_data_in[DATA_POS -: AVL_DATA_WIDTH];
assign avlm_readdatavalid = nocm_valid_in;
assign nocm_ready_out     = avlm_ready_in; 

//-----------------------------------------------------
// NOC --> AVL SLAVE
//-----------------------------------------------------

assign avls_writedata = nocs_data_in[DATA_POS  -: AVL_DATA_WIDTH];
assign avls_address   = nocs_data_in[ADDR_POS  -: AVL_ADDR_WIDTH];
assign avls_write     = nocs_data_in[WRITE_POS -: 1] & nocs_valid_in;
assign avls_read      = nocs_data_in[READ_POS  -: 1] & nocs_valid_in;
assign nocs_ready_out = ~avls_waitrequest;

//-----------------------------------------------------
// NOC <-- AVL SLAVE
//-----------------------------------------------------

assign nocs_data_out[DATA_POS -: AVL_DATA_WIDTH] = {avls_readdata};
assign nocs_valid_out = avls_readdatavalid;

endmodule
