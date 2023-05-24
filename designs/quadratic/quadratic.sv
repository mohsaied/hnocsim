/* 
 * function : connect the functional units to the NOC computes Ax^2 + c 
 * author   : Mohamed S. Abdelfattah
 * date     : 4-SEPT-2014
 */

`timescale 1ns/1ps

module quadratic
#(
	parameter WIDTH_DATA = 160
)
(
	input clk,
	input clk_ints,
	input clk_nocs,
	input rst,

	input [WIDTH_DATA-1:0] i_x,
	input i_valid_in,
	output i_ready_out,

	output reg [WIDTH_DATA-1:0] o_y,
	output reg o_valid_out,
	input      o_ready_in
);

//local parameters
localparam ADDRESS_WIDTH = $clog2(N);
localparam VC_ADDRESS_WIDTH = $clog2(NUM_VC);

//NoC parameters	
parameter WIDTH_NOC    = 128;
parameter WIDTH_RTL    = 512;
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

//connected to node 0
mult_x 
#(
	.WIDTH(WIDTH_DATA)
)
multx_inst
(
	.clk(clk),
	.rst(rst),
	
	.i_x(i_x),
	.i_valid_in(i_valid_in),
	.i_ready_out(i_ready_out),

	.o_y(pkt_data_in[0]),         //an noc port
	.o_valid_out(pkt_valid_in[0]), //an noc port
	.o_ready_in(pkt_ready_out[0])   //noc is ready?
);

//mult x is on node 0 and sends to node 1
assign pkt_dest_in[0] = 1;

//connected to node 1
mult_a 
#(
	.WIDTH(WIDTH_DATA)
)
multa_inst
(
	.clk(clk),
	.rst(rst),
	
	.i_x(pkt_data_out[1]),
	.i_valid_in(pkt_valid_out[1]),
	.i_ready_out(pkt_ready_in[1]),

	.o_y(pkt_data_in[1]),         //an noc port
	.o_valid_out(pkt_valid_in[1]), //an noc port
	.o_ready_in(pkt_ready_out[1])   //noc is ready?
);

//mult a is on node 0 and sends to node 1
assign pkt_dest_in[1] = 2;

//connected to node 2
add_c 
#(
	.WIDTH(WIDTH_DATA)
)
addc_inst
(
	.clk(clk),
	.rst(rst),
	
	.i_x(pkt_data_out[2]),
	.i_valid_in(pkt_valid_out[2]),
	.i_ready_out(pkt_ready_in[2]),

	.o_y(o_y),      
	.o_valid_out(o_valid_out),
	.o_ready_in(o_ready_in)  
);


endmodule

