module noc_to_txr_basic
  #(
    parameter DATA_WIDTH = 512,
    parameter NOC_WIDTH = 600,
    parameter NUM_VC = 2,
    parameter NOC_RADIX = 16
    )
   (
    input clk,
    input reset,

    // From NoC
    input [NOC_WIDTH-1:0] i_data_in,
    input 	   	  i_valid_in,
    output 		  i_ready_out,
	
    // To Txr
    avalonST.src out

    );


   translator_out #(.DATA_WIDTH(DATA_WIDTH),
		    .WIDTH_IN(NOC_WIDTH),
		    .NUM_VC(NUM_VC),
		    .NOC_RADIX(NOC_RADIX)) translator (.i_data_in(i_data_in),
						       .i_valid_in(i_valid_in),
						       .i_ready_out(i_ready_out),
						       .out(out));
   
   
endmodule
