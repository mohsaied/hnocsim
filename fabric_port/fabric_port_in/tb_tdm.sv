/*
 * function: testbench to verify basic tdm ops
 * author  : Mohamed S. Abdelfattah
 * date    : 25-AUG-2014
 */

module tb_tdm ();


//params
parameter WIDTH_IN = 16;
parameter WIDTH_OUT = 4;

//clocks
logic clk_slow;
logic clk_fast;
logic rst;
	
//input side
logic [WIDTH_IN-1:0] i_data_in;
logic                i_valid_in;
logic                i_ready_out;

//output
logic [WIDTH_OUT-1:0] o_data_out;
logic                 o_valid_out;
logic                 o_ready_in;

//using same signal names
tdm dut ( .* );

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
initial i_data_in  = 16'bZ;
initial i_valid_in = 1'b0;
initial o_ready_in = 1'b1;


//some test cases
initial begin

	@(posedge clk_fast);
	@(posedge clk_fast);
	@(posedge clk_slow);	
	@(posedge clk_fast);
	@(posedge clk_fast);

	rst = 1'b0;

	//wait a cycle until we're "ready"
	@(posedge clk_slow);	

	//first stimulus
	@(posedge clk_slow);	
	i_data_in = 16'hABCD;
	i_valid_in = 1'b1;
	o_ready_in = 1'b1;

	//nothing in the next cycle
	@(posedge clk_slow);	
	i_valid_in = 1'b0;


	//then two stimuli one after the other
	@(posedge clk_slow);	
	i_data_in = 16'h1234;
	i_valid_in = 1'b1;
	o_ready_in = 1'b1;
	@(posedge clk_slow);	
	i_data_in = 16'h5678;
	i_valid_in = 1'b1;
	o_ready_in = 1'b1;

	//nothing in the next cycle
 	@(posedge clk_slow);	
	i_valid_in = 1'b0;

	//now we want to test the downstream ready signal
	@(posedge clk_slow);
	i_data_in = 16'habcd;
	i_valid_in = 1'b1;
	o_ready_in = 1'b0;

	@(posedge clk_slow);
	i_data_in = 16'h1234;
	i_valid_in = 1'b1;
	o_ready_in = 1'b0;

	@(posedge clk_slow);
	i_data_in = 16'h5678;
	i_valid_in = 1'b0;
	o_ready_in = 1'b1;

	

	


	@(posedge clk_slow);	
	@(posedge clk_slow);	

end

endmodule
