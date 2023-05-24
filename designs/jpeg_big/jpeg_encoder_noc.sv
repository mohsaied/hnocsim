/* 
 * function : connect jpeg application to noc 
 * author   : mohamed s. abdelfattah
 * date     : 13-sept-2014
 */

//synopsys translate_off
`include "timescale.v"
//synopsys translate_on

module jpeg_encoder_noc_big
#(
	parameter COEF_WIDTH = 11,
	parameter DI_WIDTH = 8,
	parameter PARALLEL = 1
)
(
	input clk, //sys clk
	input rst, //active-low async reset
	
	input clk_ints,
	input clk_nocs,

	input       dstrb [0:PARALLEL-1], //data strobe . preset dstrb 1 cycle before data blk
	input [7:0] din [0:PARALLEL-1],   // input pixels
	
	output  [3:0] size [0:PARALLEL-1],  //size
	output  [3:0] rlen [0:PARALLEL-1],  //run-length
	output [11:0] amp  [0:PARALLEL-1],   //amplitude
	output        douten [0:PARALLEL-1] //data out enable
);


//local parameters
localparam ADDRESS_WIDTH = $clog2(N);
localparam VC_ADDRESS_WIDTH = $clog2(NUM_VC);

//NoC parameters	
parameter WIDTH_NOC    = 128;
parameter WIDTH_RTL    = 512;
parameter WIDTH_DATA   = 13 * PARALLEL;
parameter N            = 16;
parameter NUM_VC       = 2;
parameter DEPTH_PER_VC = 16;
parameter [VC_ADDRESS_WIDTH-1:0] ASSIGNED_VC [0:N-1] = '{0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0}; 

//clocks and reset
logic         clk_noc;
logic [N-1:0] clk_rtl;
logic [N-1:0] clk_int;
	
generate
genvar iclk;
for(iclk=0;iclk<N;iclk++)
begin:clocks
assign clk_rtl[iclk] = clk;
assign clk_int[iclk] = clk_ints;
end
endgenerate

assign clk_noc = clk_nocs;

//connections from rtl modules to noc
logic [WIDTH_RTL-1:0] i_packets_in [0:N-1];
logic                 i_valids_in  [0:N-1];
logic                 i_readys_out [0:N-1];

//connections from noc to rtl modules
logic [WIDTH_RTL-1:0] o_packets_out [0:N-1];	
logic                 o_valids_out  [0:N-1];	
logic                 o_readys_in   [0:N-1];

//fabric interface
fabric_interface  
#(
	.ASSIGNED_VC(ASSIGNED_VC),
	.DEPTH_PER_VC(DEPTH_PER_VC)
)
fabric_interface_inst
( .* );

//pkt input interfaces
logic [WIDTH_DATA-1:0]    pkt_data_in [0:3];
logic                     pkt_valid_in [0:3];
logic [ADDRESS_WIDTH-1:0] pkt_dest_in [0:3];
logic                     pkt_ready_out [0:3];

//pkt output interfaces
logic [WIDTH_DATA-1:0] pkt_data_out [0:3];
logic                  pkt_valid_out [0:3];
logic                  pkt_ready_in [0:3];

//instantiate packetizers and a depacketizers to make things easy
generate
genvar ix;
for(ix=0;ix<4;ix++)
begin:x
packetizer
#(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
	.WIDTH_IN(WIDTH_DATA),
	.WIDTH_OUT(WIDTH_RTL),
	.ASSIGNED_VC(ASSIGNED_VC[ix])
)
pkt_inst
(
	.i_data_in(pkt_data_in[ix]),
	.i_valid_in(pkt_valid_in[ix]),
	.i_dest_in(pkt_dest_in[ix]),
	.i_ready_out(pkt_ready_out[ix]),

	.o_data_out(i_packets_in[ix]),
	.o_valid_out(i_valids_in[ix]),
	.o_ready_in(i_readys_out[ix])
);

depacketizer
#(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
	.WIDTH_PKT(WIDTH_RTL),
	.WIDTH_DATA(WIDTH_DATA)
)
depkt_inst
(
	.i_packet_in(o_packets_out[ix]),
	.i_valid_in(o_valids_out[ix]),
	.i_ready_out(o_readys_in[ix]),

	.o_data_out(pkt_data_out[ix]),
	.o_valid_out(pkt_valid_out[ix]),
	.o_ready_in(pkt_ready_in[ix])
);
end
endgenerate



// variables
localparam WIDTH_UNIT = 13;
reg [12:0] dct_packed_out [0:PARALLEL-1];
reg [12:0] qnr_packed_in [0:PARALLEL-1];
reg [12:0] qnr_packed_out [0:PARALLEL-1];
reg [12:0] rle_packed_in [0:PARALLEL-1];

generate
genvar j;
for(j=0;j<PARALLEL;j=j+1)
	assign pkt_data_in[0][WIDTH_DATA-1-j*WIDTH_UNIT -: WIDTH_UNIT] = dct_packed_out[j]; 
for(j=0;j<PARALLEL;j=j+1)
	assign qnr_packed_in[j] = pkt_data_out[1][WIDTH_DATA-1-j*WIDTH_UNIT -: WIDTH_UNIT];
for(j=0;j<PARALLEL;j=j+1)
	assign pkt_data_in[1][WIDTH_DATA-1-j*WIDTH_UNIT -: WIDTH_UNIT] = qnr_packed_out[j]; 
for(j=0;j<PARALLEL;j=j+1)
	assign rle_packed_in[j] = pkt_data_out[2][WIDTH_DATA-1-j*WIDTH_UNIT -: WIDTH_UNIT];
endgenerate

// Hookup DCT to node 0
fdct_wrap_noc_big #(COEF_WIDTH, DI_WIDTH, 12, PARALLEL)
fdct_inst
(
	.clk(clk),
	.rst(~rst),
	
	.ena(pkt_ready_out[0]),
	.dstrb(dstrb),
	.din(din),

	.packed_out(dct_packed_out) //13 bits
	//.packed_out(pkt_data_in[0]) //13 bits
);

assign pkt_dest_in[0] = 1;
assign pkt_valid_in[0] = pkt_ready_out[0];
assign pkt_ready_in[0] = pkt_ready_out[0];

// Hookup QNR to node 1
jpeg_qnr_wrap_noc_big
#(PARALLEL)
qnr(
	.clk(clk),
	.rst(~rst),
	.ena(pkt_ready_out[1]),
	
	.packed_in(qnr_packed_in), //13 bits 
	.packed_out(qnr_packed_out)
	//.packed_in(pkt_data_out[1]), //13 bits 
	//.packed_out(pkt_data_in[1])
);

assign pkt_dest_in[1] = 2;
assign pkt_valid_in[1] = pkt_ready_out[1];
assign pkt_ready_in[1] = pkt_ready_out[1];

// Hookup RLE to node 2
jpeg_rle_noc_big
#(PARALLEL)
rle(
	.clk(clk),
	.rst(~rst),
	.ena(1'b1),
	
	.packed_in(rle_packed_in),
	//.packed_in(pkt_data_out[2]),
	
	.size(size),
	.rlen(rlen),
	.amp(amp),
	.douten(douten),
	.bstart()
);

assign pkt_ready_in[2] = pkt_ready_out[2];

endmodule
