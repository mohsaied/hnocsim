//synopsys translate_off
`include "timescale.v"
//synopsys translate_on

module fdct_wrap_noc(clk, ena, rst, dstrb, din, packed_out);

	parameter coef_width = 11;
	parameter di_width = 8;
	parameter do_width = 12;

	//
	// inputs & outputs
	//
	input clk;                    // system clock
	input ena;                    // clock enable
	input rst;                    // active low asynchronous reset

	input dstrb;                  // data-strobe. Present dstrb 1clk-cycle before data block
	input  [di_width-1:0] din;
	
	output reg [do_width:0] packed_out;

	reg [do_width-1:0] dout;
	reg                douten; // data-out enable


	reg [do_width-1:0] fdct_dout;
	
	assign packed_out = {douten,dout};

	// Hookup FDCT & ZigZag module
	fdct #(coef_width, di_width, 12)
	fdct_zigzag(
		.clk(clk),
		.ena(ena),
		.rst(rst),
		.dstrb(dstrb),
		.din(din),
		.dout(fdct_dout),
		.douten(douten)
	);

	// delay 'fdct_dout' => wait for synchronous quantization RAM/ROM
	always @(posedge clk)
	  if(ena)
	    dout <= #1 fdct_dout;



endmodule
