/*
 * function : connect fabric ports to noc
 * author   : Mohamed S. Abdelfattah
 * date     : 3-SEPT-2014
 */

module fabric_interface
#(
	parameter WIDTH_NOC    = 128,
	parameter WIDTH_RTL    = 512,
	parameter N            = 16,
	parameter NUM_VC       = 2,
	parameter DEPTH_PER_VC = 8,
	parameter VERBOSE      = 1,
	parameter VC_ADDRESS_WIDTH = $clog2(NUM_VC),
	parameter [VC_ADDRESS_WIDTH-1:0] ASSIGNED_VC [0:N-1] = '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
)
(
	//clocks and reset
	input         clk_noc,
	input         rst,
	input [N-1:0] clk_rtl,
	input [N-1:0] clk_int,
	
	//from rtl modules to noc
	input [WIDTH_RTL-1:0] i_packets_in [0:N-1],
	input                 i_valids_in  [0:N-1],
	output                i_readys_out [0:N-1],

	//from noc to rtl modules
	output [WIDTH_RTL-1:0] o_packets_out [0:N-1],	
	output                 o_valids_out  [0:N-1],	
	input                  o_readys_in   [0:N-1]
);

int i;
int cycle_count;

wire [WIDTH_NOC-1:0] flits_in    [0:N-1];
wire [WIDTH_NOC-1:0] flits_out   [0:N-1];
wire [NUM_VC-1:0]    credits_in  [0:N-1];
wire [NUM_VC-1:0]    credits_out [0:N-1];


//rtl interface that talks to booksim
rtl_interface 
#(
	.WIDTH(WIDTH_NOC),
	.N(N),
	.NUM_VC(NUM_VC),
        .VERBOSE(VERBOSE)
) 
rtl_interface 
(
	.clk(clk_noc),
	.reset(1'b0),
	.i_flit_in(flits_in),
	.o_flit_out(flits_out),
	.credits_to_noc(credits_in),
	.credits_to_rtl(credits_out)
);  


//generate as many fabric ports as we have routers
generate
genvar inode;
for (inode=0; inode<N; inode++)
begin:fps

//fabric port inputs
fabric_port_in
#(
	.WIDTH_NOC(WIDTH_NOC),
	.N(N),
	.NUM_VC(NUM_VC),
	.DEPTH_PER_VC(DEPTH_PER_VC),
	.ASSIGNED_VC(ASSIGNED_VC[inode])
)
fpin_inst
(
	.clk_rtl(clk_rtl[inode]),	
	.clk_int(clk_int[inode]),	
	.clk_noc(clk_noc),
	.rst(rst),

	.rtl_packet_in(i_packets_in[inode]),
	.rtl_valid_in(i_valids_in[inode]),
	.rtl_ready_out(i_readys_out[inode]),

	.noc_flit_out(flits_in[inode]),
	.noc_credits_in(credits_out[inode])
);


//fabric port inputs
fabric_port_out
#(
	.WIDTH_NOC(WIDTH_NOC),
	.N(N),
	.NUM_VC(NUM_VC),
	.DEPTH_PER_VC(DEPTH_PER_VC)
)
fpout_inst
(
	.clk_rtl(clk_rtl[inode]),	
	.clk_int(clk_int[inode]),	
	.clk_noc(clk_noc),
	.rst(rst),
	
	.noc_flit_in(flits_out[inode]),
	.noc_credits_out(credits_in[inode]),

	.rtl_packet_out(o_packets_out[inode]),
	.rtl_valid_out(o_valids_out[inode]),
	.rtl_ready_in(o_readys_in[inode])
);

end

endgenerate

//synopsys translate off
//`define DEBUG_LATENCY
`ifdef DEBUG_LATENCY
int curr_time;
always @ *
begin
	curr_time = $time;
	for(i=0;i<N;i++)
	begin
		if(i_valids_in[i])
			$display("%d | fpin (%d)",curr_time,i);
		if(o_valids_out[i])
			$display("%d | fpout (%d)",curr_time,i);
	end
end

always @ *
begin
	curr_time = $time;
	for(i=0;i<N;i++)
	begin
		if(flits_in[i][WIDTH_NOC-1])
			$display("%d | nocin (%d)",curr_time,i);
		if(flits_out[i][WIDTH_NOC-1])
			$display("%d | nocout (%d)",curr_time,i);
	end
end
`endif
//synopsys translate on




endmodule
