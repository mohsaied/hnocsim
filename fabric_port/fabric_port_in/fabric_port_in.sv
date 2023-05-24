/*
 * function : fabric port from rtl to noc
 * author   : Mohamed S. Abdelfattah
 * date     : 27-AUG-2014
 */

module fabric_port_in
#
(
	parameter WIDTH_NOC = 9,
	parameter N = 16,
	parameter NUM_VC = 2,
	parameter DEPTH_PER_VC = 10,
	parameter ASSIGNED_VC = 0,

	parameter WIDTH_RTL     = 4 * WIDTH_NOC, 
	parameter ADDRESS_WIDTH = $clog2(N),
	parameter VC_ADDRESS_WIDTH = $clog2(NUM_VC)
)
(
	//clocks and reset
	input wire clk_rtl,	
	input wire clk_int,	
	input wire clk_noc,
	input wire rst,
	
	//rtl interface
	input [WIDTH_RTL-1:0] rtl_packet_in,
	input                 rtl_valid_in,
	output                rtl_ready_out,

	//noc interface
	output reg [WIDTH_NOC-1:0] noc_flit_out,
	input      [NUM_VC-1:0]    noc_credits_in
);


//---------------------------------------------------------
// Implementation
//---------------------------------------------------------


wire [WIDTH_NOC-1:0] t_a_data;
wire                 t_a_valid;
wire                 t_a_ready;

tdm 
#(
	.WIDTH_IN(WIDTH_RTL),
	.WIDTH_OUT(WIDTH_NOC)
)
tdm_inst
(
	.clk_slow(clk_rtl),
	.clk_fast(clk_int),
	.rst(rst),

	.i_data_in(rtl_packet_in),
	.i_valid_in(rtl_valid_in),
	.i_ready_out(rtl_ready_out),

	.o_data_out(t_a_data),
	.o_valid_out(t_a_valid),
	.o_ready_in(t_a_ready)
);

wire [WIDTH_NOC-1:0] a_n_data;
wire                 a_n_read_en;
wire                 a_n_ready;

afifo_elastic
#(
	.WIDTH(WIDTH_NOC)
)
afifo_elastic_inst
(
	.write_clk(clk_int),
	.read_clk(clk_noc),
	.rst(rst),

	.i_data_in(t_a_data),
	.i_write_en(t_a_valid),
	.i_ready_out(t_a_ready),

	.o_data_out(a_n_data),
	.o_read_en(a_n_read_en),
	.o_ready_out(a_n_ready)
);

noc_writer
#(
	.WIDTH(WIDTH_NOC),
	.N(N),
	.NUM_VC(NUM_VC),
	.DEPTH_PER_VC(DEPTH_PER_VC),
	.ASSIGNED_VC(ASSIGNED_VC)
)
noc_writer_inst
(
	.clk(clk_noc),
	.rst(rst),
	
	.i_data_in(a_n_data),
	.i_ready_in(a_n_ready),
	.i_read_en(a_n_read_en),

	.o_flit_out(noc_flit_out),
	.o_credits_in(noc_credits_in)
);

endmodule
