/*
 * function: testbench to verify basic tdm ops
 * author  : Mohamed S. Abdelfattah
 * date    : 25-AUG-2014
 */

`timescale 1ns/1ps

module tb_demux ();

//params
parameter WIDTH_IN = 4;
parameter WIDTH_OUT = 16;

//clocks
logic clk_slow;
logic clk_fast;
logic rst;

//input side
logic [WIDTH_IN-1:0] i_data_in;
logic                i_empty_in;
logic                i_read_en;

//output
logic [WIDTH_OUT-1:0] o_data_out;
logic                 o_valid_out;
logic                 o_ready_in;

//using same signal names
demux dut ( .* );

//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

//clocks
initial clk_fast = 1'b1;
initial clk_slow = 1'b1;
//toggle forever
always #1 clk_fast = ~clk_fast;
always #4 clk_slow = ~clk_slow;

//reset
initial rst = 1'b1;

//inputs
initial i_data_in  = 4'bZ;
initial i_empty_in = 1'b1;
initial o_ready_in = 1'b0;

//some test cases
initial begin

	@(posedge clk_fast);
	@(posedge clk_fast);
	
	rst = 1'b0;
	
	o_ready_in = 0;
	
	@(posedge clk_fast);
	i_empty_in = 1'b0;

	//write a word
	@(posedge clk_fast);
	i_data_in = 4'ha;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'hb;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'hc;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'hd;
	i_data_in[1] = 1;
	i_empty_in = 1'b1;

	@(posedge clk_fast);
	i_empty_in = 1'b0;
	
	o_ready_in = 0;
	
	//write 2 words
	@(posedge clk_fast);
	i_data_in = 4'he;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'hf;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'h1;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'h2;
	i_data_in[1] = 1;
	i_empty_in = 1'b0;

	o_ready_in = 0;
	
	@(posedge clk_fast);
	i_data_in = 4'h5;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'h6;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'h7;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'h8;
	i_data_in[1] = 1;
	i_empty_in = 1'b0;


	o_ready_in = 1;
	
	@(posedge clk_fast);
	i_empty_in = 1'b1;
	

	@(posedge clk_fast);
	@(posedge clk_fast);
	@(posedge clk_fast);
	@(posedge clk_fast);

	//write 3 words
	@(posedge clk_fast);
	i_data_in = 4'h9;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_empty_in = 1'b1;

	@(posedge clk_fast);
	i_data_in = 4'ha;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'hb;
	i_data_in[1] = 1;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'hc;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'h1;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'h2;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'h3;
	i_data_in[1] = 1;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'h4;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'h5;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'h6;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'h7;
	i_data_in[1] = 1;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'h8;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'h9;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'ha;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'hb;
	i_data_in[1] = 1;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'hc;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'hd;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'he;
	i_data_in[1] = 1;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'hf;
	i_data_in[1] = 0;
	i_empty_in = 1'b0;

	@(posedge clk_fast);
	i_data_in = 4'h0;
	i_data_in[1] = 1;
	i_empty_in = 1'b0;


	@(posedge clk_fast);
	i_empty_in = 1'b1;




	@(posedge clk_fast);
	@(posedge clk_fast);
	@(posedge clk_fast);

end

endmodule
