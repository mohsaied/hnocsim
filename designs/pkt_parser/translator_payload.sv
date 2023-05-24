module translator_payload
  #(
    parameter DATA_WIDTH = 512,
    parameter WIDTH_IN = 600,
    parameter NUM_VC = 2,
    parameter NOC_RADIX = 16
    )
   (
    
    input [WIDTH_IN-1:0] i_data_in,
    input 		 i_valid_in,
    output 		 i_ready_out,
			 
    avalonST.src out,
    output logic [31:0] o_pktid_out,
    output logic o_payload_flag

    );

   localparam ADDRESS_WIDTH = $clog2(NOC_RADIX);
   localparam VC_ADDRESS_WIDTH = $clog2(NUM_VC);
   
   localparam FLIT3_WIDTH = WIDTH_IN/4 - 3 - ADDRESS_WIDTH - VC_ADDRESS_WIDTH - 1 - 32; // remove flag and id
   localparam FLIT2_WIDTH = WIDTH_IN/4 - 3 - VC_ADDRESS_WIDTH;
   localparam FLIT1_WIDTH = WIDTH_IN/4 - 3 - VC_ADDRESS_WIDTH;
   localparam FLIT0_WIDTH = DATA_WIDTH-FLIT3_WIDTH-FLIT2_WIDTH-FLIT1_WIDTH;
     
   wire [FLIT3_WIDTH-1:0] flit3_data;
   wire [FLIT2_WIDTH-1:0] flit2_data;
   wire [FLIT1_WIDTH-1:0] flit1_data;
   wire [FLIT0_WIDTH-1:0] flit0_data;
   
   assign i_ready_out = out.ready;

   assign out.valid = (i_valid_in && i_data_in[WIDTH_IN-1]);
   assign out.sop = i_data_in[WIDTH_IN-2];
   assign out.eop = i_data_in[WIDTH_IN/4-3];
   assign out.error = 1'b0;
   //assign out.empty = i_data_in[WIDTH_IN-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-33-1 -: $clog2(DATA_WIDTH/8)];
   assign out.empty = 'b0; // FIX ME

   assign o_payload_flag = i_data_in[WIDTH_IN-3-VC_ADDRESS_WIDTH-ADDRESS_WIDTH-1];
   assign o_pktid_out = i_data_in[WIDTH_IN-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-1-1 -: 32];
   
   assign flit3_data =  i_data_in[WIDTH_IN-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-1-1-32 -: FLIT3_WIDTH];
   assign flit2_data =  i_data_in[3*WIDTH_IN/4-3-$clog2(NUM_VC)-1 -: FLIT2_WIDTH];
   assign flit1_data =  i_data_in[WIDTH_IN/2-3-$clog2(NUM_VC)-1 -: FLIT1_WIDTH];
   assign flit0_data =  i_data_in[WIDTH_IN/4-3-$clog2(NUM_VC)-1 -: FLIT0_WIDTH];
   
   assign out.data = {flit3_data,flit2_data,flit1_data,flit0_data};
   
      

endmodule
