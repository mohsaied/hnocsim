module translator_out
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
			 
    avalonST.src out

    );


   assign i_ready_out = out.ready;
   
   assign out.valid = (i_valid_in && i_data_in[WIDTH_IN-1]);
   assign out.sop = i_data_in[WIDTH_IN-2];
   assign out.eop = i_data_in[WIDTH_IN/4-3];
   //assign out.error = i_data_in[WIDTH_IN-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-1];
   //assign out.empty = i_data_in[WIDTH_IN-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-2 -: $clog2(DATA_WIDTH/8)];
   
/* -----\/----- EXCLUDED -----\/-----
   assign out.data = {
		      i_data_in[WIDTH_IN-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-2-$clog2(DATA_WIDTH/8) -: DATA_WIDTH/4],
		      i_data_in[3*WIDTH_IN/4-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-2-$clog2(DATA_WIDTH/8) -: DATA_WIDTH/4],
		      i_data_in[WIDTH_IN/2-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-2-$clog2(DATA_WIDTH/8) -: DATA_WIDTH/4],
		      i_data_in[WIDTH_IN/4-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-2-$clog2(DATA_WIDTH/8) -: DATA_WIDTH/4]
		      };
 -----/\----- EXCLUDED -----/\----- */

   assign out.error = i_data_in[WIDTH_IN-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-DATA_WIDTH/4-1];
   assign out.empty = i_data_in[WIDTH_IN-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-DATA_WIDTH/4-2 -: $clog2(DATA_WIDTH/8)];
   
   assign out.data = {
		      i_data_in[WIDTH_IN-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-1 -: DATA_WIDTH/4],
		      i_data_in[3*WIDTH_IN/4-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-1 -: DATA_WIDTH/4],
		      i_data_in[WIDTH_IN/2-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-1 -: DATA_WIDTH/4],
		      i_data_in[WIDTH_IN/4-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-1 -: DATA_WIDTH/4]
		      };
   

endmodule
