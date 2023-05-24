/*
 * function : take packets with ethernet frames from NoC and output write
 *            requests to DDR3 on an avalon bus
 * author   : Mohamed S. Abdelfattah
 * date     : 13-MAR-2015
 */


`timescale 1ns/1ps

module testbench();


// Parameters for NOC /////////////////

parameter WIDTH_NOC    = 150;
parameter WIDTH_RTL    = 600;
parameter NUM_VC       = 2;
parameter DEPTH_PER_VC = 16;
parameter N = 16;

//local parameters
localparam ADDRESS_WIDTH = $clog2(N);
localparam VC_ADDRESS_WIDTH = $clog2(NUM_VC);

parameter [VC_ADDRESS_WIDTH-1:0] ASSIGNED_VC[0:N-1] = '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};


// Parameters for frame buf ///////////

// AVL SIDE ////////////
parameter AVL_ADDR_WIDTH = 29;
parameter AVL_DATA_WIDTH = 512+6;
parameter AVL_BYTE_EN_WIDTH = AVL_DATA_WIDTH/8;
parameter FRAME_ID_WIDTH = 4+28;   //4 bits for each port, and 14 bits for each frame 2^14 = 16384
parameter BIN_ADDR_WIDTH = 8;      // how many frame buffers will we have
parameter FRAME_OFFSET_WIDTH = 5;  // what is the maximum frame length in (4-flit) cycles?
                                   // the frame offset is log2 that value
// NOC SIDE ////////////
parameter NOC_ADDR_WIDTH = ADDRESS_WIDTH;
parameter WIDTH_PKT = AVL_DATA_WIDTH+1+1+FRAME_ID_WIDTH; //this is the data width after the translator strips away the flit headers

//which nodes are each connected to?
parameter [ADDRESS_WIDTH-1:0] PGEN_NODE = 4;
parameter [ADDRESS_WIDTH-1:0] DDR_NODE = 11;

// Clocking ///////////////////////////

logic clk;
logic rst;

//clocks and reset
logic         clk_noc;
logic         clk_rtls;
logic [N-1:0] clk_rtl;
logic         clk_ints;
logic [N-1:0] clk_int;

generate
genvar iclk;
for(iclk=0;iclk<N;iclk++)
begin:clocks
assign clk_rtl[iclk] = clk_rtls;
assign clk_int[iclk] = clk_ints;
end
endgenerate


// generate clocks
initial clk_noc = 1'b1;
initial clk_ints = 1'b1;
initial clk_rtls = 1'b1;
always #0.4165 clk_noc  = ~clk_noc;
always #0.625  clk_ints = ~clk_ints; 
always #2.5    clk_rtls = ~clk_rtls; 

initial begin
rst = 1;
#10;
rst = 0;
end

// Fabric Interface ////////////////////

//from packetizer to noc
logic [WIDTH_RTL-1:0] i_packets_in [0:N-1];
logic                 i_valids_in  [0:N-1];
logic                 i_readys_out [0:N-1];

//from noc to depacketizers
logic [WIDTH_RTL-1:0] o_packets_out [0:N-1];	
logic                 o_valids_out  [0:N-1];	
logic                 o_readys_in   [0:N-1];


fabric_interface 
#(
	.DEPTH_PER_VC(DEPTH_PER_VC),
	.ASSIGNED_VC(ASSIGNED_VC),
    .WIDTH_RTL(WIDTH_RTL),
    .WIDTH_NOC(WIDTH_NOC)
)
fi_inst ( .* );



// Frame Buffer TB /////////////////////////

//signals for packet gen
wire      [WIDTH_PKT-1:0] pgen_noc_data_out;
wire                [3:0] pgen_noc_valid_out;
wire                      pgen_noc_ready_in;
wire                [3:0] pgen_noc_sop_out;
wire                [3:0] pgen_noc_eop_out;

// ddr ports
wire [WIDTH_PKT-1:0] ddr_noc_data_in;
wire           [3:0] ddr_noc_valid_in;
wire                 ddr_noc_ready_out;
wire           [3:0] ddr_noc_sop_in;
wire           [3:0] ddr_noc_eop_in;

wire      [WIDTH_PKT-1:0] ddr_noc_data_out;
wire [NOC_ADDR_WIDTH-1:0] ddr_noc_dest_out;
wire                [3:0] ddr_noc_valid_out;
wire                      ddr_noc_ready_in;
wire                [3:0] ddr_noc_sop_out;
wire                [3:0] ddr_noc_eop_out;


pkt_generator #(
    .AVL_DATA_WIDTH(AVL_DATA_WIDTH)
) pkt_gen( 
    
    .clk(clk_rtls),
    .rst(rst),

    .noc_data_in(pgen_noc_data_out),
    .noc_valid_in(pgen_noc_valid_out),
    .noc_ready_out(pgen_noc_ready_in),
    .noc_sop_in(pgen_noc_sop_out),
    .noc_eop_in(pgen_noc_eop_out)
);

ethernet_frame_buffer #(
    .AVL_DATA_WIDTH(AVL_DATA_WIDTH)
) fb_inst( 
    .clk(clk_rtls),
    .rst(rst),

    .top_noc_data_in  (ddr_noc_data_in), 
    .top_noc_valid_in (ddr_noc_valid_in),
    .top_noc_ready_out(ddr_noc_ready_out),
    .top_noc_sop_in   (ddr_noc_sop_in),
    .top_noc_eop_in   (ddr_noc_eop_in),
    
    .top_noc_data_out (ddr_noc_data_out), 
    .top_noc_dest_out (ddr_noc_dest_out), 
    .top_noc_valid_out(ddr_noc_valid_out),
    .top_noc_ready_in (ddr_noc_ready_in),
    .top_noc_sop_out  (ddr_noc_sop_out),
    .top_noc_eop_out  (ddr_noc_eop_out)
);


// De/Packetizers //////////////////////////

//one packetizer for pkt generator

packetizer_sop
#(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
	.WIDTH_IN(WIDTH_PKT),
	.WIDTH_OUT(WIDTH_RTL),
	.ASSIGNED_VC()
)
pgen_pktizer
(
	.i_data_in  (pgen_noc_data_out),
	.i_valid_in (pgen_noc_valid_out),
	.i_sop_in   (pgen_noc_sop_out),
	.i_eop_in   (pgen_noc_eop_out),
	.i_dest_in  (DDR_NODE),
	.i_ready_out(pgen_noc_ready_in),
    
    //which node are we connected to?
	.o_packet_out (i_packets_in[PGEN_NODE]),
	.o_valid_out(i_valids_in[PGEN_NODE]),
	.o_ready_in (i_readys_out[PGEN_NODE])
);

//one packetizer/depacketizer for frame buffer

packetizer_sop
#(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
	.WIDTH_IN(WIDTH_PKT),
	.WIDTH_OUT(WIDTH_RTL),
	.ASSIGNED_VC()
)
ddr_pktizer
(
	.i_data_in  (ddr_noc_data_out),
	.i_valid_in (ddr_noc_valid_out),
	.i_sop_in   (ddr_noc_sop_out),
	.i_eop_in   (ddr_noc_eop_out),
	.i_dest_in  (ddr_noc_dest_out),
	.i_ready_out(ddr_noc_ready_in),
    
    //which node are we connected to?
	.o_packet_out (i_packets_in[DDR_NODE]),
	.o_valid_out(i_valids_in[DDR_NODE]),
	.o_ready_in (i_readys_out[DDR_NODE])
);


depacketizer_sop
#(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
	.WIDTH_PKT(WIDTH_RTL),
	.WIDTH_DATA(WIDTH_PKT)
)
ddr_depktizer
(
	.i_packet_in(o_packets_out[DDR_NODE]),
	.i_valid_in (o_valids_out[DDR_NODE]),
	.i_ready_out(o_readys_in[DDR_NODE]),

	.o_data_out (ddr_noc_data_in),
	.o_valid_out(ddr_noc_valid_in),
	.o_ready_in (ddr_noc_ready_out),
	.o_sop_out  (ddr_noc_sop_in),
	.o_eop_out  (ddr_noc_eop_in)
);


endmodule
