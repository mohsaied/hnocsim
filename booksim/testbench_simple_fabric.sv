/* 
 * function : testbench to 
 * author   : Mohamed S. Abdelfattah
 * date     : 3-SEPT-2014
 */

`timescale 1ns/1ps

module testbench();
parameter WIDTH_NOC    = 128;
parameter WIDTH_RTL    = 512;
parameter N            = 16;
parameter NUM_VC       = 2;
parameter DEPTH_PER_VC = 8;

//clocks and reset
logic         clk_noc;
logic         rst;
logic [N-1:0] clk_rtl;
logic [N-1:0] clk_int;
	
//from rtl modules to noc
logic [WIDTH_RTL-1:0] i_packets_in [0:N-1];
logic                 i_valids_in  [0:N-1];
logic                 i_readys_out [0:N-1];

//from noc to rtl modules
logic [WIDTH_RTL-1:0] o_packets_out [0:N-1];	
logic                 o_valids_out  [0:N-1];	
logic                 o_readys_in   [0:N-1];


//local parameters
localparam ADDRESS_WIDTH = $clog2(N);
localparam VC_ADDRESS_WIDTH = $clog2(NUM_VC);

localparam WIDTH_DATA = 492; 

//vars
int i;
int cycle_count;

//dut
fabric_interface dut ( .* );

//1 pkt input interface
logic [WIDTH_DATA-1:0]    pkt_data_in;
logic                     pkt_valid_in;
logic [ADDRESS_WIDTH-1:0] pkt_dest_in;
logic                     pkt_ready_out;


//instantiate a packetizer and a depacketizer to make things easy
packetizer
#(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
	.WIDTH_IN(WIDTH_DATA),
	.WIDTH_OUT(WIDTH_RTL)
)
pkt_inst
(
	.i_data_in(pkt_data_in),
	.i_valid_in(pkt_valid_in),
	.i_dest_in(pkt_dest_in),
	.i_ready_out(pkt_ready_out),

	.o_data_out(i_packets_in[0]),
	.o_valid_out(i_valids_in[0]),
	.o_ready_in(i_readys_out[0])
);


//1 pkt output interface
logic [WIDTH_DATA-1:0] pkt_data_out;
logic                  pkt_valid_out;
logic                  pkt_ready_in;

depacketizer
#(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
	.WIDTH_PKT(WIDTH_RTL),
	.WIDTH_DATA(WIDTH_DATA)
)
depkt_inst
(
	.i_packet_in(o_packets_out[15]),
	.i_valid_in(o_valids_out[15]),
	.i_ready_out(o_readys_in[15]),

	.o_data_out(pkt_data_out),
	.o_valid_out(pkt_valid_out),
	.o_ready_in(pkt_ready_in)
);

//one module clk is connected to all the nodes
logic clk_rtls;
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
always #1    clk_noc = ~clk_noc; 
always #1.25 clk_ints = ~clk_ints; 
always #5    clk_rtls = ~clk_rtls; 

initial rst = 1;

initial pkt_data_in = 0;
initial pkt_valid_in = 0;
initial pkt_dest_in = 0;
initial pkt_ready_in = 0;

int packet_count = 0;

//-------------------------------------------------------------------------
// Testbench
//-------------------------------------------------------------------------

//simple testbench sends one packet
initial begin

	cycle_count = 0;

	/*
	for (i=1; i<N; i=i+1) begin
		i_packets_in[i] = 0;
		i_valids_in[i] = 0;
		o_readys_in[i] = 1;
	end
	*/
	
	//three clock cycles later we deassert the rst
	@(posedge clk_rtls)
	@(posedge clk_rtls)
	@(posedge clk_rtls)

	rst = 0;
	
	@(posedge clk_rtls)
	@(posedge clk_rtls)

for (i = 0; i < 3; i++)
begin
	@(posedge clk_rtls)

	pkt_data_in = i;
 	pkt_valid_in = 1;
	pkt_dest_in = 15;
	pkt_ready_in = 1;
	
	$display("Sending data = %d from node 0 (cycle=%d)",pkt_data_in,cycle_count);
	packet_count = packet_count + 1;
end

	@(posedge clk_rtls)

 	pkt_valid_in = 0;
end

//listen for received packets
always @(posedge clk_rtls) begin
	cycle_count = cycle_count + 1;
	if(pkt_valid_out)
	begin
		$display("Received data = %d at node 15 (cycle=%d)",pkt_data_out,cycle_count);
		packet_count = packet_count - 1;
		if(packet_count == 0)
			$finish;
	end
end


endmodule





