/* 
 * function : testbench to test the simple quadratic circuit
 * author   : Mohamed S. Abdelfattah
 * date     : 3-SEPT-2014
 */

`timescale 1ns/1ps

module testbench();

//parameter WIDTH = 16; // 1 flit
//parameter WIDTH = 160; // 2 flits
//parameter WIDTH = 260; // 3 flits
//parameter WIDTH = 400; //4 flits


parameter WIDTH = 400;


parameter [WIDTH-1:0] A = 16'd101;
parameter [WIDTH-1:0] B = 16'd59;
parameter [WIDTH-1:0] C = 16'd76;


localparam N_INPUTS = 1000;
localparam SEED = 32'hBAADF00D;

logic clk;
logic clk_ints;
logic clk_nocs;
logic rst;

logic [WIDTH-1:0] i_x;
logic i_valid_in;
logic i_ready_out;

logic [WIDTH-1:0] o_y;
logic o_valid_out;
logic o_ready_in;


//dut
quadratic #(.WIDTH_DATA(WIDTH)) dut ( .* );

//vars
int i;
real cycle_count;

// generate clocks
initial clk_nocs = 1'b1;
initial clk_ints = 1'b1;
initial clk = 1'b1;
always #1.25 clk_nocs = ~clk_nocs;
always #1.25 clk_ints = ~clk_ints; 
always #5    clk = ~clk; 

// A combinational function to calculate the known good result.
// It looks identical to the Verilog inside the actual circuit for
// part (a), but as parts (b) and (c) get written this code won't change
// and it will be used to make sure that (b) and (c) are identical
// in result to (a)
function [WIDTH-1:0] golden_result(input reg [WIDTH-1:0] x);
	reg [WIDTH-1:0] xx;
	reg [WIDTH-1:0] Axx;
	reg [WIDTH-1:0] Bx;
	reg [WIDTH-1:0] AxxBx;
begin
	xx = x*x;
	Axx = A*xx;
	Bx = B*x;
	AxxBx = Axx + Bx;
	
	golden_result = Axx + C;
end
endfunction

initial cycle_count = 0;
always @ (posedge clk)
	cycle_count = cycle_count + 1;

int first_cycle;
initial first_cycle = -1;

int first_rec_cycle;
initial first_rec_cycle = -1;


//experiment with stall patterns
always @ (negedge clk)
	o_ready_in <= $urandom_range(0,9) <= 9 ? 1 : 0;


// Producer Process: Sequential testbench code to initialize the circuit and
// send input values to it
reg [WIDTH-1:0] prod_rand = SEED;
integer prod_i;
initial begin
	// Set valid low until we're ready to give the circuit inputs
	i_valid_in = 1'b0;
	
	// Toggle the rst for a cycle
	rst = 1'b1;
	#10;
	rst = 1'b0;
	
	// Generate N_INPUTS random inputs and deliver to circuit
	for (prod_i = 0; prod_i < N_INPUTS; prod_i = prod_i + 1) begin
		// Wait for circuit to be ready
		@(posedge clk);
		while (!i_ready_out) begin
			i_valid_in = 1'b0;		
			@(posedge clk);
		end
					
		if(first_cycle == -1)
			first_cycle = cycle_count;

		// Generate a random number and give it to the circuit
		//i_x = prod_rand[4:0];
		i_x = prod_rand[WIDTH-1:0];
		prod_rand = $random(prod_rand);
		i_valid_in = 1'b1;
	end
end

// Consumer process: Sequential testbench code to receive output
// from the circuit and verify it. Also stops the simulation when
// all outputs are delivered.
reg [WIDTH-1:0] cns_rand = SEED;
reg [WIDTH-1:0] cns_x;
reg [WIDTH-1:0] good_y;
reg fail = 1'b0;
integer cns_i;
int num_fail;
real tot;
initial begin
	num_fail = 0;
	tot = 0;
	// We generate the same numbers as the producer process
	// by using the same random seed sequence
	for (cns_i = 0; cns_i < N_INPUTS; cns_i = cns_i + 1) begin
		// Wait for a valid output
		@(posedge clk);
		while (!o_valid_out) begin
			@(posedge clk);
		end
		
		// Use our copy of X to calculate the correct Y
		cns_x = cns_rand[WIDTH-1:0];
		//cns_x = cns_rand[4:0];
		cns_rand = $random(cns_rand);
		good_y = golden_result(cns_x);
					
		if(first_rec_cycle == -1)
			first_rec_cycle = cycle_count;

	
		tot = tot + 1;

		// Display and compare the answer to the known good value
		if (good_y != o_y) begin
			$display("FAIL X: %d Expected Y: %d Got Y: %d", cns_x, good_y, o_y);
			fail = 1'b1;
			num_fail = num_fail +1;
		end
		else begin
			$display("SUCCESS X: %d Expected Y: %d Got Y: %d", cns_x, good_y, o_y);
		end
	end
	
	$display("%s", fail? "SOME TESTS FAILED" : "ALL TESTS PASSED");
	$display("%d failed out of %d total tests",num_fail,tot);
	$display("Total number of cycles = %d (%d) for %d total inputs -- xput = %f ops/cycle",cycle_count-first_cycle,cycle_count-first_rec_cycle,tot,tot/(cycle_count-first_cycle+1));
	//$stop(0);
	$finish(0);
end

endmodule
