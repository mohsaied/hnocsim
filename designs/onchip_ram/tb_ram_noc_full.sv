/*
 * function : testbench for single-port RAM
 * author   : Mohamed S. Abdelfattah
 * date     : 16-SEPT-2015
 */

`timescale 1ns/1ps

module testbench ();

parameter WIDTH = 8;
parameter ADDR_WIDTH = 7; 
parameter N = 16;
parameter N_ADDR_WIDTH = $clog2(N);

parameter PACKED_IN = WIDTH+ADDR_WIDTH+N_ADDR_WIDTH+1+1;
parameter PACKED_OUT = WIDTH+N_ADDR_WIDTH;

//the width of this data is equal to all the signals input to a RAM
parameter WIDTH_DATA_IN = PACKED_IN;
parameter WIDTH_DATA_OUT = PACKED_OUT;

//local parameters
localparam ADDRESS_WIDTH = $clog2(N);
localparam VC_ADDRESS_WIDTH = $clog2(NUM_VC);

parameter [VC_ADDRESS_WIDTH-1:0] ASSIGNED_VC[0:N-1] = '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

logic clk;
logic rst;


parameter WIDTH_NOC    = 128;
parameter WIDTH_RTL    = 512;
parameter NUM_VC       = 2;
parameter DEPTH_PER_VC = 16;


//clocks and reset
logic         clk_noc;
logic [N-1:0] clk_rtl;
logic [N-1:0] clk_int;


//from traffic to packetizer
logic [WIDTH_DATA_IN-1:0] t_packed_out [0:N-1];
logic                     t_valid_out  [0:N-1];
logic [ADDRESS_WIDTH-1:0] t_dest_out   [0:N-1];
logic 					  t_ready_in   [0:N-1];

//from depacketizer to traffic
logic [WIDTH_DATA_OUT-1:0] t_packed_in [0:N-1];
logic 					   t_valid_in  [0:N-1];
logic                      t_ready_out [0:N-1];

//from packetizer to noc
logic [WIDTH_RTL-1:0] i_packets_in [0:N-1];
logic                 i_valids_in  [0:N-1];
logic                 i_readys_out [0:N-1];

//from noc to depacketizers
logic [WIDTH_RTL-1:0] o_packets_out [0:N-1];	
logic                 o_valids_out  [0:N-1];	
logic                 o_readys_in   [0:N-1];


//tb stuff
localparam RAM_NODE = 15;
localparam NUM_TRAFS = 15;



//vars
int i;

//dut
fabric_interface 
#(
	.DEPTH_PER_VC(DEPTH_PER_VC),
	.ASSIGNED_VC(ASSIGNED_VC)	
)
dut ( .* );


generate
genvar nd;

for (nd=0;nd<NUM_TRAFS;nd=nd+1)
begin:trafs

//instantiate traffic generators
traffic
#(
	.WIDTH(WIDTH),
	.ADDR_WIDTH(ADDR_WIDTH),
	.DEPTH(8),
	.N(N),
	.NODE(nd),
	.DEST(RAM_NODE)
)
traf_inst
(
	.clk(clk_rtl[nd]),
	.rst(rst),

	.i_packed_in(t_packed_in[nd]),
	.i_valid_in(t_valid_in[nd]),
	.i_ready_out(t_ready_out[nd]),

	.o_packed_out(t_packed_out[nd]),
	.o_dest_out(t_dest_out[nd]),
	.o_valid_out(t_valid_out[nd]),
	.o_ready_in(t_ready_in[nd])
);

//instantiate a packetizer to take output of traffic
packetizer
#(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
	.WIDTH_IN(WIDTH_DATA_IN),
	.WIDTH_OUT(WIDTH_RTL),
	.ASSIGNED_VC()
)
pkt_inst_tin
(
	.i_data_in(t_packed_out[nd]),
	.i_valid_in(t_valid_out[nd]),
	.i_dest_in(t_dest_out[nd]),
	.i_ready_out(t_ready_in[nd]),

	.o_data_out(i_packets_in[nd]),
	.o_valid_out(i_valids_in[nd]),
	.o_ready_in(i_readys_out[nd])
);

//depacketizer to feed input of traffic
depacketizer
#(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
	.WIDTH_PKT(WIDTH_RTL),
	.WIDTH_DATA(WIDTH_DATA_OUT)
)
depkt_inst_tin
(
	.i_packet_in(o_packets_out[nd]),
	.i_valid_in(o_valids_out[nd]),
	.i_ready_out(o_readys_in[nd]),

	.o_data_out(t_packed_in[nd]),
	.o_valid_out(t_valid_in[nd]),
	.o_ready_in(t_ready_out[nd])
);
end
endgenerate

//ram pktizer interface
logic [WIDTH_DATA_OUT-1:0] ram_data_out;
logic                     ram_valid_out;
logic [ADDRESS_WIDTH-1:0] ram_dest_out;
logic                     ram_ready_in;

//instantiate a de/packetizer on the ram side
packetizer
#(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
	.WIDTH_IN(WIDTH_DATA_OUT),
	.WIDTH_OUT(WIDTH_RTL),
	.ASSIGNED_VC()
)
pkt_inst_rin
(
	.i_data_in(ram_data_out),
	.i_valid_in(ram_valid_out),
	.i_dest_in(ram_dest_out),
	.i_ready_out(ram_ready_in),

	.o_data_out(i_packets_in[RAM_NODE]),
	.o_valid_out(i_valids_in[RAM_NODE]),
	.o_ready_in(i_readys_out[RAM_NODE])
);

//depacketizer is input to ram
logic [WIDTH_DATA_IN-1:0] ram_data_in;
logic                  ram_valid_in;
logic                  ram_ready_out;

depacketizer
#(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
	.WIDTH_PKT(WIDTH_RTL),
	.WIDTH_DATA(WIDTH_DATA_IN)
)
depkt_inst_rout
(
	.i_packet_in(o_packets_out[RAM_NODE]),
	.i_valid_in(o_valids_out[RAM_NODE]),
	.i_ready_out(o_readys_in[RAM_NODE]),

	.o_data_out(ram_data_in),
	.o_valid_out(ram_valid_in),
	.o_ready_in(ram_ready_out)
);

logic clk_rtls;

//a memory device
ram 
#(
	.WIDTH(WIDTH),
	.ADDR_WIDTH(ADDR_WIDTH),
	.N(N),
	.NODE(RAM_NODE)
)
ram_inst
( 
	.clk(clk_rtls),
	.rst(rst),

	.i_packed_in(ram_data_in), //this should be connected to a NoC output
	.i_valid_in(ram_valid_in),
	.i_ready_out(ram_ready_out),

	.o_packed_out(ram_data_out), //and this connected to an input port
	.o_dest_out(ram_dest_out),
	.o_valid_out(ram_valid_out),
	.o_ready_in(ram_ready_in)
);

logic clk_ints;

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
always #0.4165 clk_noc = ~clk_noc;
always #1.25   clk_ints = ~clk_ints; 
always #5      clk_rtls = ~clk_rtls; 

initial rst = 1;


//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------


initial
begin

	@ (posedge clk_rtls)
	@ (posedge clk_rtls)
	@ (posedge clk_rtls)
	@ (posedge clk_rtls)

	rst = 1'b0;
	
	#20000

	$finish(0);

end


endmodule
