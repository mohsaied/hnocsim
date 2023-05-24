/*
 * function: testbench to verify basic ops
 * author  : Mohamed S. Abdelfattah
 * date    : 2-SEPT-2014
 */

`timescale 1ns/1ps

module tb_fabric_port_out ();


parameter WIDTH_DATA = 10;
parameter WIDTH_NOC = 8;
parameter N = 16;
parameter NUM_VC = 2;
parameter DEPTH_PER_VC = 8;
	
parameter WIDTH_RTL = 4 * WIDTH_NOC; 
parameter ADDRESS_WIDTH = $clog2(N);
parameter VC_ADDRESS_WIDTH = $clog2(NUM_VC);

//clocks and reset
logic clk_noc;
logic clk_rtl;	
logic clk_int;	
logic rst;

//noc interface
logic [WIDTH_NOC-1:0] noc_flit_in;
logic [NUM_VC-1:0]    noc_credits_out;

//rtl interface
logic [4*WIDTH_NOC-1:0] rtl_packet_out;
logic                   rtl_valid_out;
logic                   rtl_ready_in;

//dut
fabric_port_out dut ( .* );

localparam VALID_POS = WIDTH_NOC-1;
localparam VC_POS = WIDTH_NOC-4;
localparam HEAD_POS = WIDTH_NOC-2;
localparam TAIL_POS = WIDTH_NOC-3;

int i;

//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

//clocks
initial clk_noc = 1'b0;
initial clk_rtl = 1'b0;
initial clk_int = 1'b0;
//toggle forever
always #1.25 clk_noc = ~clk_noc;
always #1.25 clk_int = ~clk_int;
always #5 clk_rtl = ~clk_rtl;

//reset
initial rst = 1'b1;

//logics
initial noc_flit_in  = 4'bZ;
initial rtl_ready_in = 1'b0;

reg [3:0] credit_counts [0:1];
reg head;
reg tail;

//some test cases
initial begin

	@(posedge clk_rtl);
	@(posedge clk_rtl);
	
	rst = 1'b0;
	rtl_ready_in = 1;

//keep writing through the fifo
for (i = 0; i < 100000; )
begin
	if (~rst)
	begin
		
		@ (posedge clk_noc)
	
		//control packet length here
		if (i%4 == 0) head = 1; else head = 0;
		if (i%4 == 3) tail = 1; else tail = 0;

		if (credit_counts[0] > 0 & i < 16)
		begin
			noc_flit_in = i;
			noc_flit_in[VALID_POS] = 1;
			noc_flit_in[VC_POS -: VC_ADDRESS_WIDTH] = 0;
			noc_flit_in[HEAD_POS] = head;
			noc_flit_in[TAIL_POS] = tail;
			i=i+1;
		end
		else if (credit_counts[1] > 0)
		begin
			noc_flit_in = i;
			noc_flit_in[VALID_POS] = 1;
			noc_flit_in[VC_POS -: VC_ADDRESS_WIDTH] = 1;
			noc_flit_in[HEAD_POS] = head;
			noc_flit_in[TAIL_POS] = tail;
			i=i+1;
		end

		else
		begin
			noc_flit_in[VALID_POS] = 0;
		end

	end
end

end // of initial

always @ (posedge clk_noc)
begin
	if (rst)
	begin
		credit_counts[0] = 8;
		credit_counts[1] = 8;
	end
	else
	begin
		if (noc_flit_in[VALID_POS] & (noc_flit_in[VC_POS -: VC_ADDRESS_WIDTH] == 0))
			credit_counts[0] = credit_counts[0] - 1;
		if (noc_flit_in[VALID_POS] & (noc_flit_in[VC_POS -: VC_ADDRESS_WIDTH] == 1))	
			credit_counts[1] = credit_counts[1] - 1;
		if (noc_credits_out[0])
			credit_counts[0] = credit_counts[0] + 1;	
		if (noc_credits_out[1])
			credit_counts[1] = credit_counts[1] + 1;
	end
end



endmodule
