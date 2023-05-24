//synopsys translate_off
`include "timescale.v"
//synopsys translate_on

module jpeg_qnr_wrap_noc(clk, ena, rst, packed_in, packed_out);

	//
	// parameters
	//
	parameter d_width = 12;
	parameter z_width = 2 * d_width;

	//
	// inputs & outputs
	//
	input clk;                    // system clock
	input ena;                    // clock enable
	input rst;                    // asynchronous active low reset

	input [d_width:0] packed_in;
	
	output reg [12:0] packed_out;


	reg                dstrb;   // present dstrb 1clk cycle before din
	reg  [d_width-1:0] din;     // data input

	reg [10:0] dout;    // data output
	reg        douten;

	reg qnr_doe;

	reg [5:0]        qnt_cnt; // sample number (get quantization value qnt_cnt)
	reg [7:0]        qnt_val; // quantization value
	
	//pack
	assign dstrb = packed_in[d_width];
	assign din = packed_in[d_width-1:0];
	assign packed_out = {douten,dout[10],dout};

	
	// Hookup QNR (Quantization and Rounding) unit
	jpeg_qnr
	qnr(
		.clk(clk),
		.ena(ena),
		.rst(rst),
		.dstrb(dstrb),
		.din(din),
		.qnt_val(qnt_val),
		.qnt_cnt(qnt_cnt),
		.dout(dout),
		.douten(qnr_doe)
	);

	// delay douten 1 clk_cycle => account for delayed fdct_res & qnt_val
	always @(posedge clk)
	  if(ena)
	    douten <= #1 qnr_doe;

	always @ (posedge clk)
	begin
		case (qnt_cnt)
			00 : qnt_val = 8'd16;
			01 : qnt_val = 8'd11;
			02 : qnt_val = 8'd12;
			03 : qnt_val = 8'd14;
			04 : qnt_val = 8'd12;
			05 : qnt_val = 8'd10;
			06 : qnt_val = 8'd16;
			07 : qnt_val = 8'd14;
			08 : qnt_val = 8'd13;
			09 : qnt_val = 8'd14;
			10 : qnt_val = 8'd18;
			11 : qnt_val = 8'd17;
			12 : qnt_val = 8'd16;
			13 : qnt_val = 8'd19;
			14 : qnt_val = 8'd24;
			15 : qnt_val = 8'd40;
			16 : qnt_val = 8'd26;
			17 : qnt_val = 8'd24;
			18 : qnt_val = 8'd22;
			19 : qnt_val = 8'd22;
			20 : qnt_val = 8'd24;
			21 : qnt_val = 8'd49;
			22 : qnt_val = 8'd35;
			23 : qnt_val = 8'd37;
			24 : qnt_val = 8'd29;
			25 : qnt_val = 8'd40;
			26 : qnt_val = 8'd58;
			27 : qnt_val = 8'd51;
			28 : qnt_val = 8'd61;
			29 : qnt_val = 8'd60;
			30 : qnt_val = 8'd57;
			31 : qnt_val = 8'd51;
			32 : qnt_val = 8'd56;
			33 : qnt_val = 8'd55;
			34 : qnt_val = 8'd64;
			35 : qnt_val = 8'd72;
			36 : qnt_val = 8'd92;
			37 : qnt_val = 8'd78;
			38 : qnt_val = 8'd64;
			39 : qnt_val = 8'd68;
			40 : qnt_val = 8'd87;
			41 : qnt_val = 8'd69;
			42 : qnt_val = 8'd55;
			43 : qnt_val = 8'd56;
			44 : qnt_val = 8'd80;
			45 : qnt_val = 8'd109;
			46 : qnt_val = 8'd81;
			47 : qnt_val = 8'd87;
			48 : qnt_val = 8'd95;
			49 : qnt_val = 8'd98;
			50 : qnt_val = 8'd103;
			51 : qnt_val = 8'd104;
			52 : qnt_val = 8'd103;
			53 : qnt_val = 8'd62;
			54 : qnt_val = 8'd77;
			55 : qnt_val = 8'd113;
			56 : qnt_val = 8'd121;
			57 : qnt_val = 8'd112;
			58 : qnt_val = 8'd100;
			59 : qnt_val = 8'd120;
			60 : qnt_val = 8'd92;
			61 : qnt_val = 8'd101;
			62 : qnt_val = 8'd103;
			63 : qnt_val = 8'd99;
		endcase
	end

endmodule
