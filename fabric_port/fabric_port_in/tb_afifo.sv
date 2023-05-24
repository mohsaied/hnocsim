/*
 * function: testbench to verify basic tdm ops
 * author  : Mohamed S. Abdelfattah
 * date    : 25-AUG-2014
 */


module tb_afifo ();

//params
parameter WIDTH = 4;
parameter DEPTH = 4;

//clocks
logic write_clk;
logic read_clk;
logic clear;
	
//input side
logic [WIDTH-1:0] i_data_in;
logic             i_write_en;
logic             i_full_out;

//output
logic [WIDTH-1:0] o_data_out;
logic             o_read_en;
logic             o_empty_out;

//using same signal names
afifo dut ( .* );

//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

//clocks
initial write_clk = 1'b1;
initial read_clk = 1'b1;
//toggle forever
always #5 write_clk = ~write_clk;
always #4 read_clk = ~read_clk;

//reset
initial clear = 1'b1;

//inputs
initial i_data_in  = 4'bZ;
initial i_write_en = 1'b0;
initial o_read_en = 1'b0;


//some test cases
initial begin

	@(posedge write_clk);
	@(posedge write_clk);
	
	clear = 1'b0;

	
	//write a word
	@(posedge write_clk);
	i_data_in = 4'ha;
	i_write_en = 1'b1;

	@(posedge write_clk);
	i_data_in = 4'hb;
	i_write_en = 1'b1;

	@(posedge write_clk);
	i_data_in = 4'hc;
	i_write_en = 1'b1;

	@(posedge write_clk);
	i_data_in = 4'hd;
	i_write_en = 1'b1;

	@(posedge read_clk);
	o_read_en = 1'b1;

	@(posedge write_clk);
	i_write_en = 1'b0;	
	
	@(posedge read_clk);
	@(posedge read_clk);
	@(posedge read_clk);

end

endmodule
