module translator_in
  #(
    parameter DATA_WIDTH = 512,
    parameter WIDTH_OUT = 600,
    parameter NUM_VC = 2,
    parameter NOC_RADIX = 16
    )
   (
    avalonST.sink in,
    input [$clog2(NOC_RADIX)-1:0] i_dst_in,
    input [$clog2(NUM_VC)-1:0] i_vc_in,

    input i_payload_in,
    input [31:0] i_pktid_in,
    
    output [WIDTH_OUT-1:0] o_data_out,
    output o_valid_out,
    input o_ready_in

    );

   assign in.ready = o_ready_in;

   localparam VC_ADDRESS_WIDTH = $clog2(NUM_VC);
   localparam ADDRESS_WIDTH = $clog2(NOC_RADIX);
   localparam PAYLOAD_PKT_WIDTH = DATA_WIDTH + 1 + 1 + 32; // 1b write flag, 1b read flag, 32b id, 512b data
      
   wire [PAYLOAD_PKT_WIDTH-1:0] payload_pkt;
   assign payload_pkt = {1'b1,1'b0,i_pktid_in,in.data};
      
   wire [DATA_WIDTH/4-1:0] headflit3_data;
   wire [DATA_WIDTH/4-1:0] headflit2_data;
   wire [DATA_WIDTH/4-1:0] headflit1_data;
   wire [DATA_WIDTH/4-1:0] headflit0_data;

   localparam FLIT_DATA_WIDTH = WIDTH_OUT/4 - 3 - VC_ADDRESS_WIDTH - ADDRESS_WIDTH;
      
   wire [FLIT_DATA_WIDTH-1:0] payloadflit3_data;
   wire [FLIT_DATA_WIDTH-1:0] payloadflit2_data;
   wire [FLIT_DATA_WIDTH-1:0] payloadflit1_data;
   wire [FLIT_DATA_WIDTH-1:0] payloadflit0_data;

   assign headflit3_data = in.data[DATA_WIDTH-1 -: DATA_WIDTH/4];
   assign headflit2_data = in.data[3*DATA_WIDTH/4-1 -: DATA_WIDTH/4];
   assign headflit1_data = in.data[DATA_WIDTH/2-1 -: DATA_WIDTH/4];
   assign headflit0_data = in.data[DATA_WIDTH/4-1:0];

   assign payloadflit3_data = payload_pkt[PAYLOAD_PKT_WIDTH-1 -: FLIT_DATA_WIDTH];
   assign payloadflit2_data = payload_pkt[PAYLOAD_PKT_WIDTH-FLIT_DATA_WIDTH-1 -: FLIT_DATA_WIDTH];
   assign payloadflit1_data = payload_pkt[PAYLOAD_PKT_WIDTH-2*FLIT_DATA_WIDTH-1 -: FLIT_DATA_WIDTH];
   assign payloadflit0_data = {payload_pkt[PAYLOAD_PKT_WIDTH-3*FLIT_DATA_WIDTH-1:0],22'b0};
   
   assign o_valid_out = in.valid;
      
   assign o_data_out[WIDTH_OUT-1 -: WIDTH_OUT/4] = (i_payload_in) ?
						   {
						    in.valid,
						    in.sop,
						    1'b0,
						    i_vc_in,
						    i_dst_in,
						    payloadflit3_data
						    } :
						   {
						    in.valid,
						    in.sop,
						    1'b0,
						    i_vc_in,
						    i_dst_in,
						    {headflit3_data,in.error,in.empty},
						    7'b0
						    };

   assign o_data_out[3*WIDTH_OUT/4-1 -: WIDTH_OUT/4] = (i_payload_in) ?
						       {
							in.valid,
							1'b0,
							1'b0,
							i_vc_in,
							i_dst_in,
							payloadflit2_data
							} :
						       {
							in.valid,
							1'b0,
							1'b0,
							i_vc_in,
							i_dst_in,
							{headflit2_data,in.error,in.empty},
							7'b0
							};

   assign o_data_out[WIDTH_OUT/2-1 -: WIDTH_OUT/4] = (i_payload_in) ?
						     {
						      in.valid,
						      1'b0,
						      1'b0,
						      i_vc_in,
						      i_dst_in,
						      payloadflit1_data
						      } :
						     {
						      in.valid,
						      1'b0,
						      1'b0,
						      i_vc_in,
						      i_dst_in,
						      {headflit1_data,in.error,in.empty},
						      7'b0
						      };

   assign o_data_out[WIDTH_OUT/4-1 : 0] = (i_payload_in) ?
					  {
					   in.valid,
					   1'b0,
					   in.eop,
					   i_vc_in,
					   i_dst_in,
					   payloadflit0_data
					   } :
					  {
					   in.valid,
					   1'b0,
					   in.eop,
					   i_vc_in,
					   i_dst_in,
					   {headflit0_data,in.error,in.empty},
					   7'b0
					   };
   
   
endmodule
    
