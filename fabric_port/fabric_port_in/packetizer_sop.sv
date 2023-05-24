/*
 * function : take a data word/dest and insert proper packet and flit headers -- manual setting of sop and eop
 * author   : Mohamed S. Abdelfattah
 * date     : 11-MAR-2015
 */

module packetizer_sop
#(
	parameter ADDRESS_WIDTH = 4,
	parameter VC_ADDRESS_WIDTH = 1,
	parameter WIDTH_IN  = 12,
	//parameter WIDTH_OUT = ((WIDTH_IN + 3*4 + ADDRESS_WIDTH + 4*VC_ADDRESS_WIDTH + 3)/4) * 4 
	parameter WIDTH_OUT = 36,
	parameter [VC_ADDRESS_WIDTH-1:0] ASSIGNED_VC = 0
)
(
	//input port
	input [WIDTH_IN-1:0]      i_data_in,
	input               [3:0] i_valid_in,
	input [ADDRESS_WIDTH-1:0] i_dest_in,
	output                    i_ready_out,
    
    input               [3:0] i_sop_in,
    input               [3:0] i_eop_in,

	//output port
	output [WIDTH_OUT-1:0] o_packet_out,
	output                 o_valid_out,
	input                  o_ready_in
);

//ideal flit widths
localparam FLIT_1_WIDTH_IDL = WIDTH_OUT/4 - 3 - ADDRESS_WIDTH - VC_ADDRESS_WIDTH;
localparam FLIT_2_WIDTH_IDL = WIDTH_OUT/4 - 3 - VC_ADDRESS_WIDTH;
localparam FLIT_3_WIDTH_IDL = WIDTH_OUT/4 - 3 - VC_ADDRESS_WIDTH;
localparam FLIT_4_WIDTH_IDL = WIDTH_OUT/4 - 3 - VC_ADDRESS_WIDTH;

//actual flit widths
localparam FLIT_1_VALID     = 1;
localparam FLIT_1_WIDTH_ACT = FLIT_1_WIDTH_IDL > WIDTH_IN ? WIDTH_IN : FLIT_1_WIDTH_IDL;
localparam FLIT_1_PADDING   = FLIT_1_WIDTH_IDL - FLIT_1_WIDTH_ACT;
localparam REM_FROM_1       = WIDTH_IN - FLIT_1_WIDTH_ACT; 

localparam FLIT_2_VALID     = WIDTH_IN > (FLIT_1_WIDTH_ACT);
localparam FLIT_2_WIDTH_ACT = FLIT_2_VALID ? (FLIT_2_WIDTH_IDL > REM_FROM_1 ? REM_FROM_1 : FLIT_2_WIDTH_IDL) : 1;
localparam FLIT_2_PADDING   = FLIT_2_WIDTH_IDL - FLIT_2_WIDTH_ACT;
localparam REM_FROM_2       = REM_FROM_1 - FLIT_2_WIDTH_ACT;
  
localparam FLIT_3_VALID     = WIDTH_IN > (FLIT_1_WIDTH_ACT + FLIT_2_WIDTH_ACT);
localparam FLIT_3_WIDTH_ACT = FLIT_3_VALID ? (FLIT_3_WIDTH_IDL > REM_FROM_2 ? REM_FROM_2 : FLIT_3_WIDTH_IDL) : 1;
localparam FLIT_3_PADDING   = FLIT_3_WIDTH_IDL - FLIT_3_WIDTH_ACT;
localparam REM_FROM_3       = REM_FROM_2 - FLIT_3_WIDTH_ACT;

localparam FLIT_4_VALID     = WIDTH_IN > (FLIT_1_WIDTH_ACT + FLIT_2_WIDTH_ACT + FLIT_3_WIDTH_ACT);
localparam FLIT_4_WIDTH_ACT = FLIT_4_VALID ? (FLIT_4_WIDTH_IDL > REM_FROM_3 ? REM_FROM_3 : FLIT_4_WIDTH_IDL) : 1;
localparam FLIT_4_PADDING   = FLIT_4_WIDTH_IDL - FLIT_4_WIDTH_ACT;

wire [FLIT_1_WIDTH_ACT-1:0] flit_1_data;
wire [FLIT_2_WIDTH_ACT-1:0] flit_2_data;
wire [FLIT_3_WIDTH_ACT-1:0] flit_3_data;
wire [FLIT_4_WIDTH_ACT-1:0] flit_4_data;


//-------------------------------------------------------------------------
// Implementation
//-------------------------------------------------------------------------

assign o_valid_out = i_valid_in;
assign i_ready_out = o_ready_in;

localparam FLIT_2_START = FLIT_2_VALID ? WIDTH_IN-1-FLIT_1_WIDTH_ACT : FLIT_2_WIDTH_ACT;
localparam FLIT_3_START = FLIT_3_VALID ? WIDTH_IN-1-FLIT_1_WIDTH_ACT-FLIT_2_WIDTH_ACT : FLIT_3_WIDTH_ACT;
localparam FLIT_4_START = FLIT_4_VALID ? WIDTH_IN-1-FLIT_1_WIDTH_ACT-FLIT_2_WIDTH_ACT-FLIT_3_WIDTH_ACT : FLIT_4_WIDTH_ACT;

assign flit_1_data = FLIT_1_VALID ? i_data_in[WIDTH_IN-1 -: FLIT_1_WIDTH_ACT] : 0;
assign flit_2_data = FLIT_2_VALID ? i_data_in[FLIT_2_START -: FLIT_2_WIDTH_ACT] : 0;
assign flit_3_data = FLIT_3_VALID ? i_data_in[FLIT_3_START -: FLIT_3_WIDTH_ACT] : 0;
assign flit_4_data = FLIT_4_VALID ? i_data_in[FLIT_4_START -: FLIT_4_WIDTH_ACT] : 0;

assign o_packet_out = {
	i_valid_in[0],
	i_sop_in[0],
	i_eop_in[0],
	ASSIGNED_VC,
	i_dest_in,
	flit_1_data,
	{FLIT_1_PADDING{1'b0}},
	
	i_valid_in[1],
	i_sop_in[1],
	i_eop_in[1],
	ASSIGNED_VC,
	flit_2_data,
	{FLIT_2_PADDING{1'b0}},
	
	i_valid_in[2],
	i_sop_in[2],
        i_eop_in[2],
	ASSIGNED_VC,
	flit_3_data,
	{FLIT_3_PADDING{1'b0}},
	
	i_valid_in[3],
	i_sop_in[3],
        i_eop_in[3],
	ASSIGNED_VC,
	flit_4_data,
	{FLIT_4_PADDING{1'b0}}
};

endmodule
