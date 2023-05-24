/*
 * function : take in packets and spit out data only (strip control)
 * author   : Mohamed S. Abdelfattah
 * date     : 3-SEPT-2014
 */

module depacketizer_sop
#(
	parameter WIDTH_PKT = 600,
	parameter WIDTH_DATA = 512+32+1+1,
	parameter VC_ADDRESS_WIDTH = 1,
	parameter ADDRESS_WIDTH = 4
)
(
	input [WIDTH_PKT-1:0] i_packet_in,
	input                 i_valid_in,
	output                i_ready_out,
	
	output [WIDTH_DATA-1:0] o_data_out,
	output            [3:0] o_valid_out,
	input                   o_ready_in,

    output            [3:0] o_sop_out,
    output            [3:0] o_eop_out
);

localparam WIDTH_FLIT = WIDTH_PKT/4;
localparam DATA_POS_HEAD = WIDTH_PKT - 3 - VC_ADDRESS_WIDTH - ADDRESS_WIDTH - 1;
localparam DATA_POS_B1   = WIDTH_PKT - WIDTH_FLIT - 3 - VC_ADDRESS_WIDTH - ADDRESS_WIDTH - 1;
localparam DATA_POS_B2   = WIDTH_PKT - 2*WIDTH_FLIT - 3 - VC_ADDRESS_WIDTH - ADDRESS_WIDTH - 1;
localparam DATA_POS_TAIL = WIDTH_PKT - 3*WIDTH_FLIT - 3 - VC_ADDRESS_WIDTH - ADDRESS_WIDTH - 1;

localparam WIDTH_DATA_IDL = WIDTH_PKT - 3*4 -4*VC_ADDRESS_WIDTH - ADDRESS_WIDTH;
localparam EXTRA_BITS = WIDTH_DATA_IDL - WIDTH_DATA;

wire [WIDTH_DATA-1:0] full_data;

localparam FLIT_DATA_WIDTH = WIDTH_PKT/4 - 3 - VC_ADDRESS_WIDTH - ADDRESS_WIDTH;

localparam VALID1_POS = WIDTH_PKT - 1;
localparam VALID2_POS = WIDTH_PKT -   WIDTH_FLIT - 1;
localparam VALID3_POS = WIDTH_PKT - 2*WIDTH_FLIT - 1;
localparam VALID4_POS = WIDTH_PKT - 3*WIDTH_FLIT - 1;

localparam SOP1_POS = WIDTH_PKT - 2;
localparam SOP2_POS = WIDTH_PKT -   WIDTH_FLIT - 2;
localparam SOP3_POS = WIDTH_PKT - 2*WIDTH_FLIT - 2;
localparam SOP4_POS = WIDTH_PKT - 3*WIDTH_FLIT - 2;

localparam EOP1_POS = WIDTH_PKT - 3;
localparam EOP2_POS = WIDTH_PKT -   WIDTH_FLIT - 3;
localparam EOP3_POS = WIDTH_PKT - 2*WIDTH_FLIT - 3;
localparam EOP4_POS = WIDTH_PKT - 3*WIDTH_FLIT - 3;

//------------------------------------------------------------------------
// Implementation
//------------------------------------------------------------------------

assign i_ready_out = o_ready_in;

assign o_valid_out[3] = i_valid_in & i_packet_in[VALID1_POS];
assign o_valid_out[2] = i_valid_in & i_packet_in[VALID2_POS];
assign o_valid_out[1] = i_valid_in & i_packet_in[VALID3_POS];
assign o_valid_out[0] = i_valid_in & i_packet_in[VALID4_POS];

assign o_sop_out[3] = i_packet_in[SOP1_POS];
assign o_sop_out[2] = i_packet_in[SOP2_POS];
assign o_sop_out[1] = i_packet_in[SOP3_POS];
assign o_sop_out[0] = i_packet_in[SOP4_POS];

assign o_eop_out[3] = i_packet_in[EOP1_POS];
assign o_eop_out[2] = i_packet_in[EOP2_POS];
assign o_eop_out[1] = i_packet_in[EOP3_POS];
assign o_eop_out[0] = i_packet_in[EOP4_POS];

//here we need to strip all the control bits and concat data back together


/* -----\/----- EXCLUDED -----\/-----
assign full_data = {
		i_packet_in[DATA_POS_HEAD : 3*WIDTH_FLIT],
		i_packet_in[DATA_POS_B1   : 2*WIDTH_FLIT],
		i_packet_in[DATA_POS_B2   : 1*WIDTH_FLIT],
		i_packet_in[DATA_POS_TAIL : 0]
};
 -----/\----- EXCLUDED -----/\----- */

assign full_data = {
		    i_packet_in[DATA_POS_HEAD -: FLIT_DATA_WIDTH],
		    i_packet_in[DATA_POS_B1   -: FLIT_DATA_WIDTH],
		    i_packet_in[DATA_POS_B2   -: FLIT_DATA_WIDTH],
		    i_packet_in[DATA_POS_TAIL -: WIDTH_DATA-(3*FLIT_DATA_WIDTH)]
		    };

assign o_data_out = full_data;



endmodule
