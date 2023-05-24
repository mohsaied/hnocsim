/* 
 * function : connect jpeg application to noc 
 * author   : mohamed s. abdelfattah
 * date     : 13-sept-2014
 */

//synopsys translate_off
`include "timescale.v"
//synopsys translate_on

module jpeg_encoder
#(
	parameter COEF_WIDTH = 11,
	parameter DI_WIDTH = 8
)
(
	input clk, //sys clk
	input rst, //active-low async reset
	
	input clk_ints,
	input clk_nocs,

	input       dstrb, //data strobe . preset dstrb 1 cycle before data blk
	input [7:0] din,   // input pixels
	
	output  [3:0] size,  //size
	output  [3:0] rlen,  //run-length
	output [11:0] amp,   //amplitude
	output        douten //data out enable
);

// variables
reg  [11:0] fdct_out;
wire 		fdct_doe;
wire [10:0] qnr_dout;
reg         qnr_doe;

// Hookup DCT to node 0
fdct_wrap #(COEF_WIDTH, DI_WIDTH, 12)
fdct_inst
(
	.clk(clk),
	.rst(rst),
	
	.ena(1'b1),
	.dstrb(dstrb),
	.din(din),

	.dout(fdct_out),
	.douten(fdct_doe)
);

// Hookup QNR to node 1
jpeg_qnr_wrap
qnr(
	.clk(clk),
	.rst(rst),
	
	.ena(1'b1),
	.dstrb(fdct_doe),
	.din(fdct_out),

	.dout(qnr_dout),
	.douten(qnr_doe)
);

// Hookup RLE to node 2
jpeg_rle
rle(
	.clk(clk),
	.rst(rst),
	
	.ena(1'b1),
	.dstrb(qnr_doe),
	.din(qnr_dout),
	
	.size(size),
	.rlen(rlen),
	.amp(amp),
	.douten(douten)
);

endmodule
