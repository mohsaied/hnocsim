/*
 * function : fabric port from noc to rtl
 * author   : Mohamed S. Abdelfattah
 * date     : 2-SEPT-2014
 */

module fabric_port_out
#
(
	parameter WIDTH_NOC = 8,
	parameter N = 16,
	parameter NUM_VC = 2,
	parameter DEPTH_PER_VC = 8,
	
	parameter WIDTH_RTL = 4 * WIDTH_NOC, 
	parameter ADDRESS_WIDTH = $clog2(N),
	parameter VC_ADDRESS_WIDTH = $clog2(NUM_VC)
)
(
	//clocks and reset
	input wire clk_noc,
	input wire clk_rtl,	
	input wire clk_int,	
	input wire rst,
	
	//noc interface
	input reg [WIDTH_NOC-1:0] noc_flit_in,
	output    [NUM_VC-1:0]    noc_credits_out,

	//rtl interface
	output reg [4*WIDTH_NOC-1:0] rtl_packet_out,
	output reg                   rtl_valid_out,
	input                        rtl_ready_in

);


//---------------------------------------------------------
// Implementation
//---------------------------------------------------------

wire [WIDTH_NOC-1:0] n_a_data; 
wire                 n_a_write; 
wire                 n_a_ready; 

noc_reader
#(
	.DEPTH_PER_VC(DEPTH_PER_VC),
	.WIDTH(WIDTH_NOC),
	.NUM_VC(NUM_VC),
	.N(N)
)
noc_reader_inst
(
	.clk(clk_noc),
	.rst(rst),

	.i_flit_in(noc_flit_in),
	.i_credits_out(noc_credits_out),

	.o_data_out(n_a_data),
	.o_write_en(n_a_write),
	.o_ready_in(n_a_ready)
);

wire [WIDTH_NOC-1:0] a_d_data;
wire                 a_d_read;
wire                 a_d_ready;

afifo_elastic
#(
	.WIDTH(WIDTH_NOC),
	.DEPTH(DEPTH_PER_VC)
)
afifo_inst
(
	.write_clk(clk_noc),
	.read_clk(clk_int),
	.rst(rst),

	.i_data_in(n_a_data),
	.i_write_en(n_a_write),
	.i_ready_out(n_a_ready),

	.o_data_out(a_d_data),
	.o_read_en(a_d_read),
	.o_ready_out(a_d_ready)
);

demux
#(
	.WIDTH_IN(WIDTH_NOC),
	.WIDTH_OUT(WIDTH_NOC*4)
)
demux_inst
(
	.clk_slow(clk_rtl),
	.clk_fast(clk_int),
	.rst(rst),

	.i_data_in(a_d_data),
	.i_empty_in(~a_d_ready),
	.i_read_en(a_d_read),

	.o_data_out(rtl_packet_out),
	.o_valid_out(rtl_valid_out),
	.o_ready_in(rtl_ready_in)
);
endmodule
