/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Discrete Cosine Transform Testbench (ITU-T.81 & ITU-T.83)  ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2002 Richard Herveille                        ////
////                    richard@asics.ws                         ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

`include "timescale.v"

module tb_jpeg();

	parameter coef_width = 13; //9;

	// amount of 8x8 data packets to use for tests (current max. = 4)
	parameter input_lists_start = 1;
	parameter input_lists_end = 4;
	localparam SEED = 8'hBA;


	//
	// internal wires
	//
	reg clk;
	reg rst;

	reg dstrb;
	reg [7:0] din;
	wire den;
	wire [10:0] dout;
	wire [ 3:0] size, rlen;
	wire [11:0] amp;

	reg [ 7:0] input_list  [(input_lists_end*64) -1:0];

	reg [7:0] random_input;

	integer x,y;
	integer n, list_cnt;
	
	logic clk_ints;
	logic clk_nocs;
	
	
	// generate clocks
	initial clk_nocs = 1'b1;
	initial clk_ints = 1'b1;
	initial clk = 1'b1;
	always #1 clk_nocs = ~clk_nocs;
	always #1.25 clk_ints = ~clk_ints; 
	always #5    clk = ~clk; 

	//
	// JPEG Encoder unit
	//

/*
	jpeg_encoder_bnoc #(coef_width)
	jpeg_enc (
		.clk(clk),
		.rst(rst),
		.dstrb(dstrb),
		.din(din),
		.size(size),
		.rlen(rlen),
		.amp(amp),
		.douten(den)
	);	
*/

	jpeg_encoder_noc #(coef_width)
	jpeg_enc (
		.clk(clk),
		.rst(rst),
		.clk_ints(clk_ints),
		.clk_nocs(clk_nocs),
		.dstrb(dstrb),
		.din(din),
		.size(size),
		.rlen(rlen),
		.amp(amp),
		.douten(den)
	);


	integer f;
	initial f = $fopen("output_noc.txt");

	always @ (posedge clk)
	begin
		if(den)
			$fdisplay(f,"size = %h, rlen = %h, amp = %h",size,rlen,amp);
			//$display("size = %h, rlen = %h, amp = %h",size,rlen,amp);
	end


	//
	// testbench body
	//


	// initial statements
	initial
	begin
	
		random_input = SEED;
		clk = 0; // start with low-level clock
		rst = 1; // reset system
		dstrb = 1'b0;

		rst = #17 1'b0;


		// wait a while
		repeat(20) @(posedge clk);

		for(n=0; n <= 10; n = n +1)
		begin
			// present dstrb
			dstrb = #1 1'b1;

			for(y=0; y<=7; y=y+1)
			for(x=0; x<=7; x=x+1)
			begin
				@(posedge clk)
				dstrb = #1 1'b0;
				random_input = $urandom_range(0,255);
				din = #1 random_input[7:0];
				//$display("din = %f",din);
			end
		end
	
		#2000
		$fclose(f);
		$finish(0);

	end

endmodule

