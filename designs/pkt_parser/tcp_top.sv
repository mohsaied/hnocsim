module tcp_top
  #(
    parameter DATA_WIDTH = 512,
    parameter NOC_WIDTH = 600,
    parameter NUM_VC = 2,
    parameter NOC_RADIX = 16,
    parameter NUM_SRC = 4,
    parameter [3:0] DEST [0:NUM_SRC-1]  = '{4'd12,4'd13,4'd14,4'd15},
    parameter PORT_ID = 4,
    parameter REPLY_DEST = 4'd1
    )
   (
    input 		   clk,
    input 		   reset,

    // From NoC
    input [NOC_WIDTH-1:0]  i_data_in,
    input 		   i_valid_in,
    output 		   i_ready_out,
    
    // To NoC
    output [NOC_WIDTH-1:0] o_data_out,
    output 		   o_valid_out,
    input 		   o_ready_in

    );


   avalonST #(.WIDTH(DATA_WIDTH)) trans2tcp ();
   avalonST #(.WIDTH(DATA_WIDTH)) tcp2trans ();
   avalonST #(.WIDTH(DATA_WIDTH)) tcpreply2trans ();

   wire [NOC_WIDTH-1:0]    tcp_data;
   wire 		   tcp_valid;
   wire 		   tcp_ready;
   wire [NOC_WIDTH-1:0]    tcpreply_data;
   wire 		   tcpreply_valid;
   wire 		   tcpreply_ready;
   
      
   logic [$clog2(NUM_VC)-1:0] vc_id;
   logic [$clog2(NOC_RADIX)-1:0] noc_dst;
   
   
   translator_out #(.DATA_WIDTH(DATA_WIDTH),
		    .WIDTH_IN(NOC_WIDTH),
		    .NUM_VC(NUM_VC),
		    .NOC_RADIX(NOC_RADIX)) translator_out (.i_data_in(i_data_in),
							   .i_valid_in(i_valid_in),
							   .i_ready_out(i_ready_out),
							   .out(trans2tcp));
   


   tcp512 #(.NOC_RADIX(NOC_RADIX),
	    .NUM_VC(NUM_VC),
	    .NUM_SRC(NUM_SRC),
	    .DEST(DEST)) tcp (.clk(clk),
			      .reset(reset),
			      .in(trans2tcp),
			      .out(tcp2trans),
			      .out_reply(tcpreply2trans),
			      .o_vc_id(vc_id),
			      .o_noc_dst(noc_dst));

   

   translator_in #(.DATA_WIDTH(DATA_WIDTH),
		   .WIDTH_OUT(NOC_WIDTH),
		   .NUM_VC(NUM_VC),
		   .NOC_RADIX(NOC_RADIX)) translator_in (.in(tcp2trans),
							 .i_dst_in(noc_dst),
							 .i_vc_in(vc_id),
							 .i_payload_in(1'b0),
							 .i_pktid_in('b0),
							 .o_data_out(tcp_data),
							 .o_valid_out(tcp_valid),
							 .o_ready_in(tcp_ready));

   translator_in #(.DATA_WIDTH(DATA_WIDTH),
		   .WIDTH_OUT(NOC_WIDTH),
		   .NUM_VC(NUM_VC),
		   .NOC_RADIX(NOC_RADIX)) translator_in_reply (.in(tcpreply2trans),
							 .i_dst_in(REPLY_DEST), // CHANGE ME
							 .i_vc_in(vc_id),
							 .i_payload_in(1'b0),
							 .i_pktid_in('b0),
							 .o_data_out(tcpreply_data),
							 .o_valid_out(tcpreply_valid),
							 .o_ready_in(tcpreply_ready));

   arbiter2to1 #(.NOC_WIDTH(NOC_WIDTH)) arb (.clk(clk),
					     .reset(reset),
					     .i_data1_in(tcp_data),
					     .i_valid1_in(tcp_valid),
					     .i_ready1_out(tcp_ready),
					     .i_data2_in(tcpreply_data),
					     .i_valid2_in(tcpreply_valid),
					     .i_ready2_out(tcpreply_ready),
					     .o_data_out(o_data_out),
					     .o_valid_out(o_valid_out),
					     .o_ready_in(o_ready_in));
   
   
endmodule
