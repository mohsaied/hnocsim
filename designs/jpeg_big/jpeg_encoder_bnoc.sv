/* 
 * function : connect jpeg application to noc 
 * author   : mohamed s. abdelfattah
 * date     : 13-sept-2014
 */

//synopsys translate_off
`include "timescale.v"
//synopsys translate_on

module jpeg_encoder_bnoc_big
#(
	parameter COEF_WIDTH = 11,
	parameter DI_WIDTH = 8,
	parameter PARALLEL = 39
)
(
	input clk, //sys clk
	input rst, //active-low async reset
	
	input       dstrb [0:PARALLEL-1], //data strobe . preset dstrb 1 cycle before data blk
	input [7:0] din   [0:PARALLEL-1],   // input pixels
	
	output  [3:0] size   [0:PARALLEL-1],  //size
	output  [3:0] rlen   [0:PARALLEL-1],  //run-length
	output [11:0] amp    [0:PARALLEL-1],   //amplitude
	output        douten [0:PARALLEL-1] //data out enable
);

// variables
reg [12:0] fdct_packed_out [0:PARALLEL-1];
reg [12:0] qnr_packed_out [0:PARALLEL-1];

// Hookup DCT to node 0
fdct_wrap_noc_big #(COEF_WIDTH, DI_WIDTH, 12,PARALLEL)
fdct_inst
(
	.clk(clk),
	.rst(~rst),
	
	.ena(1'b1),
	.dstrb(dstrb),
	.din(din),

	.packed_out(fdct_packed_out) //13 bits
);


// Hookup QNR to node 1
jpeg_qnr_wrap_noc_big
#(PARALLEL)
qnr(
	.clk(clk),
	.rst(~rst),
	.ena(1'b1),
	
	.packed_in(fdct_packed_out), //13 bits
	.packed_out(qnr_packed_out)
);


// Hookup RLE to node 2
jpeg_rle_noc_big
#(PARALLEL)
rle(
	.clk(clk),
	.rst(~rst),
	.ena(1'b1),
	
	.packed_in(qnr_packed_out),
	
	.size(size),
	.rlen(rlen),
	.amp(amp),
	.douten(douten),
	.bstart()
);

endmodule
