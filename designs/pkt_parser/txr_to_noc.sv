module txr_to_noc
  #(
    parameter DATA_WIDTH = 512,
    parameter NOC_WIDTH = 600,
    parameter FIFO_DEPTH = 32,
    parameter MAX_HEADER_SIZE = 1,
    parameter MAC_ADDRESS = 48'hA1B2C3D4E5F6,
    parameter MEM_DEPTH = 512,
    parameter NUM_VC = 2,
    parameter NOC_RADIX = 16,
    parameter PORT_ID = 2,
    parameter DDR_PORT = 4,
    parameter NODE_ID = PORT_ID,
    parameter DEST = 4'd0,
    parameter MEM_WIDTH = $clog2(NOC_RADIX) + 1 // port # + valid bit
    )
   (
    input 		   clk,
    input 		   reset,
			   
    avalonST.sink in,

    // To NoC
    output [NOC_WIDTH-1:0] o_data_out,
    output 		   o_valid_out,
    input 		   o_ready_in

    );

   avalonST #(.WIDTH(DATA_WIDTH)) pre2eth ();
   avalonST #(.WIDTH(DATA_WIDTH)) eth2send ();
   avalonST #(.WIDTH(DATA_WIDTH)) send2trans ();
   
   logic [$clog2(NUM_VC)-1:0] 	  header_vc_id;
   logic [$clog2(NOC_RADIX)-1:0]  header_noc_dst;
   logic [$clog2(NUM_VC)-1:0] 	  vc_id;
   logic [$clog2(NOC_RADIX)-1:0]  noc_dst;

   typedef struct packed {
      logic 				  valid;
      logic 				  sop;
      logic 				  eop;
      logic 				  error;
      logic [$clog2(DATA_WIDTH/8)-1:0] 	  empty;
      logic [DATA_WIDTH-1:0] 		  data;
   } avalonst_t;
   
      
   pre_process #(.DATA_WIDTH(DATA_WIDTH),
		 .FIFO_DEPTH(FIFO_DEPTH),
		 .NOC_RADIX(NOC_RADIX),
		 .NODE_ID(NODE_ID)) pre (.clk(clk),
					       .reset(reset),
					       .in(in),
					       .out(pre2eth));

            
   ethernet512 #(.MAC_ADDRESS(MAC_ADDRESS),
		 .MEM_DEPTH(MEM_DEPTH),
		 .NUM_VC(NUM_VC),
		 .NOC_RADIX(NOC_RADIX),
		 .PORT_ID(PORT_ID),
		 .MEM_WIDTH(MEM_WIDTH)) ethernet (.clk(clk),
						  .reset(reset),
						  .in(pre2eth),
						  .out(eth2send),
						  .o_vc_id(header_vc_id),
						  .o_noc_dst(header_noc_dst));
   


   logic payload_flag;
   logic [31:0] pkt_id;
      
   send_header_payload #(.DATA_WIDTH(DATA_WIDTH),
		       .MAX_HEADER_SIZE(MAX_HEADER_SIZE)) send_hp (.clk(clk),
								   .reset(reset),
								   .in(eth2send),
								   .out(send2trans),
								   .o_payload_out(payload_flag),
								   .o_id(pkt_id));
   
   translator_in #(.DATA_WIDTH(DATA_WIDTH),
		   .WIDTH_OUT(NOC_WIDTH),
		   .NUM_VC(NUM_VC),
		   .NOC_RADIX(NOC_RADIX)) translator (.in(send2trans),
						      .i_dst_in(noc_dst),
						      .i_vc_in(1'b0), // CHANGE ME
						      .i_pktid_in(pkt_id),
						      .i_payload_in(payload_flag),
						      .o_data_out(o_data_out),
						      .o_valid_out(o_valid_out),
						      .o_ready_in(o_ready_in));	


   //logic payload_flag_r, payload_flag_next;
   //always_ff @(posedge clk) payload_flag_r <= (reset) ? 1'b0 : payload_flag_next;
      
   always_comb begin
      // Defaults
/* -----\/----- EXCLUDED -----\/-----
      payload_flag_next = payload_flag_r;
            
      if (merge2trans.valid && merge2trans.sop) begin

	 if (merge2trans.data[DATA_WIDTH-1]) begin
	    // Payload
	    payload_flag_next = 1'b1;
	    
	 end
	 else begin
	    // Header
	    payload_flag_next = 1'b0;
	    
	 end

      end // if (merge2trans.valid && merge2trans.sop)
 -----/\----- EXCLUDED -----/\----- */
      
      if (payload_flag) begin
	 vc_id = 'b0;
	 noc_dst = DDR_PORT;
      end
      else begin
	 vc_id = header_vc_id;
	 //noc_dst = header_noc_dst;
	 noc_dst = DEST;
      end
      
   end
   
endmodule
