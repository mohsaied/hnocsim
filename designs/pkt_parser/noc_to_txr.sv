module noc_to_txr
  #(
    parameter DATA_WIDTH = 512,
    parameter NOC_WIDTH = 600,
    parameter NUM_VC = 2,
    parameter NOC_RADIX = 16,
    parameter NODE_ID = 15,
    parameter [$clog2(NOC_RADIX)-1:0] DDR_PORT = 4'd4
    )
   (
    input 		  clk,
    input 		  reset,

    // From NoC
    input [NOC_WIDTH-1:0] i_data_in,
    input 		  i_valid_in,
    output 		  i_ready_out,

    // Data Req To NoC
    output [NOC_WIDTH-1:0] o_data_out,
    output 		  o_valid_out,
    input 		  o_ready_in,
			  			  
    // To Txr
    avalonST.src out
    
    );

   
   avalonST #(.WIDTH(DATA_WIDTH)) trans2rec ();
   avalonST #(.WIDTH(DATA_WIDTH)) rec2trans ();

   logic [31:0] 	  pkt_id;
   wire 		  payload_flag;
         
   translator_combine #(.DATA_WIDTH(DATA_WIDTH),
		    .WIDTH_IN(NOC_WIDTH),
		    .NUM_VC(NUM_VC),
		    .NOC_RADIX(NOC_RADIX)) translator (.clk(clk),
						       .reset(reset),
						       .i_data_in(i_data_in),
						       .i_valid_in(i_valid_in),
						       .i_ready_out(i_ready_out),
						       .out(trans2rec),
						       .o_payload_flag(payload_flag),
						       .o_pktid_out(pkt_id));

   
   
   recombine #(.DATA_WIDTH(DATA_WIDTH),
	       .NODE_ID(NODE_ID),
	       .NOC_RADIX(NOC_RADIX),
	       .DDR_PORT(DDR_PORT)) recombine (.clk(clk),
					       .reset(reset),
					       .i_payload_flag(payload_flag),
					       .in(trans2rec),
					       .i_pktid(pkt_id),
					       .out_to_txr(out),
					       .out_data_req(rec2trans));

   translator_data_req #(.DATA_WIDTH(DATA_WIDTH),
		   .WIDTH_OUT(NOC_WIDTH),
		   .NUM_VC(NUM_VC),
		   .NOC_RADIX(NOC_RADIX)) translator_data_req (.in(rec2trans),
							       .i_dst_in(DDR_PORT), // CHANGE ME
							       .i_vc_in(1'b0), // CHANGE ME
							       .o_data_out(o_data_out),
							       .o_valid_out(o_valid_out),
							       .o_ready_in(o_ready_in));	
   
endmodule
