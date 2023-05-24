module ipv6_top
  #(
    parameter DATA_WIDTH = 512,
    parameter NOC_WIDTH = 600,
    parameter NUM_VC = 2,
    parameter NOC_RADIX = 16,
    parameter PORT_ID = 4,
    parameter NUM_SRC = 4,
    parameter [3:0] DEST [0:NUM_SRC-1] = '{4'd8,4'd9,4'd10,4'd11}
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


   avalonST #(.WIDTH(DATA_WIDTH)) trans2ip ();
   avalonST #(.WIDTH(DATA_WIDTH)) ip2trans ();
   logic [$clog2(NUM_VC)-1:0] vc_id;
   logic [$clog2(NOC_RADIX)-1:0] noc_dst;
   
   
   translator_out #(.DATA_WIDTH(DATA_WIDTH),
		    .WIDTH_IN(NOC_WIDTH),
		    .NUM_VC(NUM_VC),
		    .NOC_RADIX(NOC_RADIX)) translator_out (.i_data_in(i_data_in),
							   .i_valid_in(i_valid_in),
							   .i_ready_out(i_ready_out),
							   .out(trans2ip));
   


   ipv6_512 #(.NOC_RADIX(NOC_RADIX),
	      .NUM_VC(NUM_VC),
	      .NODE_ID(PORT_ID),
	      .NUM_SRC(NUM_SRC),
	      .DEST(DEST)) ipv6 (.clk(clk),
				       .reset(reset),
				       .in(trans2ip),
				       .out(ip2trans),
				       .o_vc_id(vc_id),
				       .o_noc_dst(noc_dst));
   

   translator_in #(.DATA_WIDTH(DATA_WIDTH),
		   .WIDTH_OUT(NOC_WIDTH),
		   .NUM_VC(NUM_VC),
		   .NOC_RADIX(NOC_RADIX)) translator_in (.in(ip2trans),
							 .i_dst_in(noc_dst),
							 .i_vc_in(vc_id),
							 .i_payload_in(1'b0),
							 .i_pktid_in('b0),
							 .o_data_out(o_data_out),
							 .o_valid_out(o_valid_out),
							 .o_ready_in(o_ready_in));	

   
endmodule
