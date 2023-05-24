/*
 * function : testbench to verify basic ops
 * author   : Mohamed S. Abdelfattah
 * date     : 27-AUG-2014
 */

`timescale 1ns/1ps

module tb_fp_in();

//params
parameter WIDTH_DATA = 10;
parameter WIDTH_NOC = 9;
parameter N = 16;
parameter NUM_VC = 2;
parameter DEPTH_PER_VC = 10;

parameter WIDTH_RTL        = 4 * WIDTH_NOC; 
parameter ADDRESS_WIDTH    = $clog2(N);
parameter VC_ADDRESS_WIDTH = $clog2(NUM_VC);

//clocks and reset
logic clk_rtl;
logic clk_int;	
logic clk_noc;
logic rst;
	
//pkt interface
logic [WIDTH_DATA-1:0]    pkt_data_in;
logic                     pkt_valid_in;
logic [ADDRESS_WIDTH-1:0] pkt_dest_in;
logic                     pkt_ready_out;

logic [WIDTH_RTL-1:0] rtl_packet_in;
logic                 rtl_valid_in;
logic                 rtl_ready_out;

//noc interface
logic [WIDTH_NOC-1:0] noc_flit_out;
logic [NUM_VC-1:0]    noc_credits_in;

//using same signal names
fabric_port_in dut ( .* );

packetizer 
#(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
	.WIDTH_IN(WIDTH_DATA),
	.WIDTH_OUT(4*WIDTH_NOC)
)
pkt_inst
(
	.i_data_in(pkt_data_in),
	.i_valid_in(pkt_valid_in),
	.i_dest_in(pkt_dest_in),
	.i_ready_out(pkt_ready_out),

	.o_data_out(rtl_packet_in),
	.o_valid_out(rtl_valid_in),
	.o_ready_in(rtl_ready_out)
);

//-------------------------------------------------------------------------------
// Testbench
//-------------------------------------------------------------------------------

//clocks
initial clk_rtl = 1'b1;
initial clk_int = 1'b1;
initial clk_noc = 1'b1;
//toggle forever
always #5    clk_rtl = ~clk_rtl;
always #1.25 clk_int = ~clk_int;
always #1    clk_noc = ~clk_noc;

//reset
initial rst = 1'b1;

//inputs
initial pkt_data_in = {WIDTH_DATA{1'bZ}};
initial pkt_valid_in = 1'b0;
initial pkt_dest_in = {ADDRESS_WIDTH{1'b0}};
initial noc_credits_in = {NUM_VC{00}};

int i;

initial 
begin
	
	rst = 1'b1;

	@ (posedge clk_rtl)
	
	rst = 1'b0;

	for (i=0;i < 1000; i++)
	begin
		
		@ (posedge clk_rtl)

		if (rtl_ready_out)
		begin
			pkt_valid_in = 1;
			pkt_data_in = i;
		end
		else
			pkt_valid_in = 1'b0;

	end	

	$stop(0);

end

always @ (posedge clk_noc)
begin
	if (noc_flit_out[WIDTH_NOC-1])
		noc_credits_in = 2'b01;
end

//some test cases
/*
initial begin
	
	@ (posedge clk_rtl);

	rst = 1'b0;

	@ (posedge clk_rtl);
	@ (posedge clk_rtl);

	//1 write
	@ (posedge clk_rtl);
	pkt_data_in = {WIDTH_DATA{1'b1}};
	pkt_valid_in = 1'b1;
	pkt_dest_in = {ADDRESS_WIDTH{1'b0}};

	@ (posedge clk_rtl);
	pkt_valid_in = 1'b0;
	
	//2 writes
	@ (posedge clk_rtl);
	pkt_data_in = {WIDTH_DATA{1'b1}};
	pkt_valid_in = 1'b1;
	pkt_dest_in = {ADDRESS_WIDTH{1'b0}};

	@ (posedge clk_rtl);
	pkt_data_in = {WIDTH_DATA{1'b0}};
	pkt_valid_in = 1'b1;
	pkt_dest_in = {ADDRESS_WIDTH{1'b1}};

	@ (posedge clk_rtl);
	pkt_valid_in = 1'b0;

	//3 writes
	@ (posedge clk_rtl);
	pkt_data_in = {WIDTH_DATA{1'b1}};
	pkt_valid_in = 1'b1;
	pkt_dest_in = {ADDRESS_WIDTH{1'b0}};

	@ (posedge clk_rtl);
	pkt_data_in = {WIDTH_DATA{1'b0}};
	pkt_valid_in = 1'b1;
	pkt_dest_in = {ADDRESS_WIDTH{1'b1}};

	@ (posedge clk_rtl);
	pkt_data_in = {WIDTH_DATA{1'b1}};
	pkt_valid_in = 1'b1;
	pkt_dest_in = {ADDRESS_WIDTH{1'b1}};

	@ (posedge clk_rtl);
	pkt_valid_in = 1'b0;

	
	//more writes -- should stall after these
	@ (posedge clk_rtl);
	pkt_data_in = {WIDTH_DATA{1'b0}};
	pkt_valid_in = 1'b1;
	pkt_dest_in = {ADDRESS_WIDTH{1'b1}};

	@ (posedge clk_rtl);
	@ (posedge clk_rtl);
	@ (posedge clk_rtl);
	
	@ (posedge clk_rtl);
	pkt_valid_in = 1'b0;

	@ (posedge clk_rtl);
	@ (posedge clk_rtl);

end
*/


endmodule
