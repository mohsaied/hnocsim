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
	parameter PARALLEL = 36;
	// amount of 8x8 data packets to use for tests (current max. = 4)
	parameter input_lists_start = 1;
	parameter input_lists_end = 4;
	localparam SEED = 520'd112;


	//
	// internal wires
	//
	reg clk;
	reg rst;

	reg dstrb [0:PARALLEL-1];
	reg [7:0] din [0:PARALLEL-1];
	wire den [0:PARALLEL-1];
	wire [ 3:0] size [0:PARALLEL-1]; 
	wire [ 3:0] rlen [0:PARALLEL-1];
	wire [11:0] amp  [0:PARALLEL-1];

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
	jpeg_encoder_bnoc_big #(.COEF_WIDTH(coef_width),.PARALLEL(PARALLEL))
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

	jpeg_encoder_noc_big #(.COEF_WIDTH(coef_width),.PARALLEL(PARALLEL))
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


	int k;
	integer f;
	//initial f = $fopen("output_bnoc.txt");
	initial f = $fopen("output_noc.txt");

	always @ (posedge clk)
	begin
		for(k=0;k<PARALLEL;k++)
			if(den[k])
				$fdisplay(f,"%d|size = %h, rlen = %h, amp = %h",k,size[k],rlen[k],amp[k]);
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
	
		#1;
		for(k=0;k<PARALLEL;k++)
			dstrb[k] = 1'b0;

		rst = #17 1'b0;


		// wait a while
		repeat(20) @(posedge clk);

		for(n=0; n <= 1; n = n +1)
		begin
			// present dstrb
			#1;
			for(k=0;k<PARALLEL;k++)
				dstrb[k] = 1'b1;

			for(y=0; y<=7; y=y+1)
			for(x=0; x<=7; x=x+1)
			begin
				@(posedge clk)
				#1;
				for(k=0;k<PARALLEL;k++)
					dstrb[k] = 1'b0;
				random_input = $urandom_range(0,255);
				for(k=0;k<PARALLEL;k++)
					din[k] = random_input[7:0];
				//$display("din = %f",din);
			end
		end
	
		#2000
		$fclose(f);
		$finish(0);

	end

endmodule

