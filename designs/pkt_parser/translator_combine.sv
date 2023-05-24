module translator_combine
  #(
    parameter DATA_WIDTH = 512,
    parameter WIDTH_IN = 600,
    parameter NUM_VC = 2,
    parameter NOC_RADIX = 16
    )
   (
    input 		 clk,
    input 		 reset,
        
    input [WIDTH_IN-1:0] i_data_in,
    input 		 i_valid_in,
    output 		 i_ready_out,
			 
    avalonST.src out,
    output logic [31:0]  o_pktid_out,
    output o_payload_flag

    );

   avalonST #(.WIDTH(DATA_WIDTH)) out_header ();
   avalonST #(.WIDTH(DATA_WIDTH)) out_payload ();
   
   logic [31:0] 	pkt_id;
   logic 		head_ready, payload_ready;
   logic 		payload_flag;
      
   assign i_ready_out = out.ready;
   
   translator_out #(.DATA_WIDTH(DATA_WIDTH),
		    .WIDTH_IN(WIDTH_IN),
		    .NUM_VC(NUM_VC),
		    .NOC_RADIX(NOC_RADIX)) translator_header (.i_data_in(i_data_in),
							      .i_valid_in(i_valid_in),
							      .i_ready_out(head_ready),
							      .out(out_header));
   
   translator_payload #(.DATA_WIDTH(DATA_WIDTH),
			.WIDTH_IN(WIDTH_IN),
			.NUM_VC(NUM_VC),
			.NOC_RADIX(NOC_RADIX)) translator_payload (.i_data_in(i_data_in),
								   .i_valid_in(i_valid_in),
								   .i_ready_out(payload_ready),
								   .out(out_payload),
								   .o_pktid_out(pkt_id),
								   .o_payload_flag(payload_flag));

   assign o_payload_flag = payload_flag;
      
   logic payload_r, payload_next;
   always_ff @(posedge clk) payload_r <= (reset) ? 1'b0 : payload_next;

   always_comb begin
      payload_next = payload_r;

      if (out_payload.valid && out_payload.sop) begin 
	 
	 if (payload_flag)
	   payload_next = 1'b1;
	 else
	   payload_next = 1'b0;

      end
      
   end
      
   // Mux
   always_comb begin

      if (payload_r || payload_next) begin
	 out.valid = out_payload.valid;
      	 out.sop = out_payload.sop;
	 out.eop = out_payload.eop;
	 out.error = out_payload.error;
	 out.empty = out_payload.empty;
	 out.data = out_payload.data;
      end
      else begin
	 out.valid = out_header.valid;
      	 out.sop = out_header.sop;
	 out.eop = out_header.eop;
	 out.error = out_header.error;
	 out.empty = out_header.empty;
	 out.data = out_header.data;
      end
      
   end

   assign o_pktid_out = pkt_id;
      
endmodule
