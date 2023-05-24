//synopsys translate_off
`include "timescale.v"
//synopsys translate_on

module fdct_wrap_noc_big(clk, ena, rst, dstrb, din, packed_out);

parameter coef_width = 11;
parameter di_width = 8;
parameter do_width = 12;
parameter PARALLEL = 39;

//
// inputs & outputs
//
input clk;                    // system clock
input ena;                    // clock enable
input rst;                    // active low asynchronous reset

input                 dstrb [0:PARALLEL-1]; // data-strobe. Present dstrb 1clk-cycle before data block
input  [di_width-1:0] din   [0:PARALLEL-1];

output reg [do_width:0] packed_out [0:PARALLEL-1];


//---------------------------------------------------
// Implementation
//---------------------------------------------------


generate

genvar i;

for (i=0; i<PARALLEL; i++)
begin:dcts
	// Hookup FDCTs
	fdct_wrap_noc 
	#(coef_width, di_width, 12)
	fdct_inst
	(
		.clk(clk),
		.ena(ena),
		.rst(rst),
		
		.dstrb(dstrb[i]),
		.din(din[i]),
		
		.packed_out(packed_out[i])
	);
end

endgenerate

endmodule
