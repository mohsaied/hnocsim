module translator_data_req
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
    
    output [WIDTH_OUT-1:0] o_data_out,
    output o_valid_out,
    input o_ready_in

    );

   
   assign in.ready = o_ready_in;
   assign o_valid_out = in.valid;


   assign o_data_out[WIDTH_OUT-1 -: WIDTH_OUT/4] = {
						    in.valid,
						    1'b1,
						    1'b1,
						    i_vc_in,
						    i_dst_in,
						    in.data[DATA_WIDTH-1 -: 38],
						    104'b0
						    };

   assign o_data_out[3*WIDTH_OUT/4-1 : 0] = 'b0;
   

endmodule
