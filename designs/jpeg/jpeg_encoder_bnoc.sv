/* 
 * function : connect jpeg application to noc 
 * author   : mohamed s. abdelfattah
 * date     : 13-sept-2014
 */

//synopsys translate_off
`include "timescale.v"
//synopsys translate_on

module jpeg_encoder_bnoc
#(
	parameter COEF_WIDTH = 11,
	parameter DI_WIDTH = 8
)
(
	input clk, //sys clk
	input rst, //active-low async reset
	
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
wire [11:0] qnr_dout;
reg         qnr_doe;

// Hookup DCT to node 0
fdct_wrap_noc #(COEF_WIDTH, DI_WIDTH, 12)
fdct_inst
(
	.clk(clk),
	.rst(~rst),
	
	.ena(1'b1),
	.dstrb(dstrb),
	.din(din),

	.packed_out({fdct_doe,fdct_out}) //13 bits
);


// Hookup QNR to node 1
jpeg_qnr_wrap_noc
qnr(
	.clk(clk),
	.rst(~rst),
	.ena(1'b1),
	
	.packed_in({fdct_doe,fdct_out}), //13 bits
	.packed_out({qnr_doe,qnr_dout})
);


// Hookup RLE to node 2
jpeg_rle_noc
rle(
	.clk(clk),
	.rst(~rst),
	.ena(1'b1),
	
	.packed_in({qnr_doe,qnr_dout}),
	
	.size(size),
	.rlen(rlen),
	.amp(amp),
	.douten(douten),
	.bstart()
);

endmodule
