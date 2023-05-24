module noc_to_tcp_to_txr
  #(
    parameter DATA_WIDTH = 512,
    parameter NOC_WIDTH = 600,
    parameter NUM_VC = 2,
    parameter NOC_RADIX = 16,
    parameter REPLY_DEST = 4'd1
    )
   (
    input clk,
    input reset,

    // From NoC
    input [NOC_WIDTH-1:0] i_data_in,
    input 	   	  i_valid_in,
    output 		  i_ready_out,
	
    // To Txr
    avalonST.src out,

    // Replies To NoC
    output [NOC_WIDTH-1:0] o_data_out,
    output 		   o_valid_out,
    input 		   o_ready_in


    );

   logic [$clog2(NUM_VC)-1:0] vc_id;
   logic [$clog2(NOC_RADIX)-1:0] noc_dst;

   avalonST #(.WIDTH(DATA_WIDTH)) trans2tcp ();
   avalonST #(.WIDTH(DATA_WIDTH)) tcp2trans ();

   translator_out #(.DATA_WIDTH(DATA_WIDTH),
		    .WIDTH_IN(NOC_WIDTH),
		    .NUM_VC(NUM_VC),
		    .NOC_RADIX(NOC_RADIX)) translator (.i_data_in(i_data_in),
						       .i_valid_in(i_valid_in),
						       .i_ready_out(i_ready_out),
						       .out(trans2tcp));

   tcp512 #(.NOC_RADIX(NOC_RADIX),
	    .NUM_VC(NUM_VC)) tcp (.clk(clk),
				  .reset(reset),
				  .in(trans2tcp),
				  .out(out),
				  .out_reply(tcp2trans),
				  .o_vc_id(vc_id), // not used here
				  .o_noc_dst(noc_dst)); // not used here

   
   translator_in #(.DATA_WIDTH(DATA_WIDTH),
		   .WIDTH_OUT(NOC_WIDTH),
		   .NUM_VC(NUM_VC),
		   .NOC_RADIX(NOC_RADIX)) translator_in (.in(tcp2trans),
							 .i_dst_in(REPLY_DEST[3:0]), // CHANGE ME
							 .i_vc_in(vc_id),
							 .i_payload_in(1'b0),
							 .i_pktid_in('b0),
							 .o_data_out(o_data_out),
							 .o_valid_out(o_valid_out),
							 .o_ready_in(o_ready_in));	
   
   
endmodule
