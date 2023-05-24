module merge_to_noc
  #(
    parameter DATA_WIDTH = 64
    )
   (
    input clk,
    input reset,

    avalonST.sink in_header,
    avalonST.sink in_payload,
    avalonST.src out,

    output logic o_payload_out
    
    );

   
   typedef struct packed {
      logic 	  valid;
      logic 	  sop;
      logic 	  eop;
      logic 	  error;
      logic [$clog2(DATA_WIDTH/8)-1:0] empty;
      logic [DATA_WIDTH-1:0] 	       data;
   } avalonst_t;
   
   // Round robin flag to indicate give priority to sending payload
   // This flag should toggle in order to do RR arbitration
   logic  rr_payload_flag_r, rr_payload_flag_next;
   always_ff @(posedge clk) rr_payload_flag_r <= (reset) ? 1'b0 : rr_payload_flag_next;
      
   enum   {POLLING,SEND_HEAD,SEND_PAYLOAD,SEND_REGISTERED_HEAD,SEND_REGISTERED_PAYLOAD} fsm_r, fsm_next;
   always_ff @(posedge clk) fsm_r <= (reset) ? POLLING : fsm_next;


   // For absorbing data when ready signal is dropped
   avalonst_t skidhead0_r, skidhead0_next;
   avalonst_t skidhead1_r, skidhead1_next;
   avalonst_t skidpayload0_r, skidpayload0_next;
   avalonst_t skidpayload1_r, skidpayload1_next;
   
   always_ff @(posedge clk) begin

      skidhead0_r.valid    <= (reset) ? 1'b0 : skidhead0_next.valid;
      skidhead0_r.sop 	   <= (reset) ? 1'b0 : skidhead0_next.sop;
      skidhead0_r.eop 	   <= (reset) ? 1'b0 : skidhead0_next.eop;
      skidhead0_r.error    <= (reset) ? 1'b0 : skidhead0_next.error;
      skidhead0_r.empty    <= (reset) ? 'b0 : skidhead0_next.empty;
      skidhead0_r.data 	   <= (reset) ? 'b0 : skidhead0_next.data;

      skidhead1_r.valid    <= (reset) ? 1'b0 : skidhead1_next.valid;
      skidhead1_r.sop 	   <= (reset) ? 1'b0 : skidhead1_next.sop;
      skidhead1_r.eop 	   <= (reset) ? 1'b0 : skidhead1_next.eop;
      skidhead1_r.error    <= (reset) ? 1'b0 : skidhead1_next.error;
      skidhead1_r.empty    <= (reset) ? 'b0 : skidhead1_next.empty;
      skidhead1_r.data 	   <= (reset) ? 'b0 : skidhead1_next.data;

      skidpayload0_r.valid <= (reset) ? 1'b0 : skidpayload0_next.valid;
      skidpayload0_r.sop   <= (reset) ? 1'b0 : skidpayload0_next.sop;
      skidpayload0_r.eop   <= (reset) ? 1'b0 : skidpayload0_next.eop;
      skidpayload0_r.error <= (reset) ? 1'b0 : skidpayload0_next.error;
      skidpayload0_r.empty <= (reset) ? 'b0 : skidpayload0_next.empty;
      skidpayload0_r.data  <= (reset) ? 'b0 : skidpayload0_next.data;

      skidpayload1_r.valid <= (reset) ? 1'b0 : skidpayload1_next.valid;
      skidpayload1_r.sop   <= (reset) ? 1'b0 : skidpayload1_next.sop;
      skidpayload1_r.eop   <= (reset) ? 1'b0 : skidpayload1_next.eop;
      skidpayload1_r.error <= (reset) ? 1'b0 : skidpayload1_next.error;
      skidpayload1_r.empty <= (reset) ? 'b0 : skidpayload1_next.empty;
      skidpayload1_r.data  <= (reset) ? 'b0 : skidpayload1_next.data;
      
   end // always_ff @

   
   always_comb begin
      // Defaults
      fsm_next 		    = fsm_r;
      rr_payload_flag_next  = rr_payload_flag_r;
      out.valid 	    = 1'b0;
      out.sop 		    = 1'b0;
      out.eop 		    = 1'b0;
      out.error 	    = 1'b0;
      out.empty 	    = 'b0;
      out.data 		    = 'b0;
      in_header.ready 	    = 1'b0;
      in_payload.ready 	    = 1'b0;
      o_payload_out 	    = 1'b0;
      skidhead0_next 	    = skidhead0_r;
      skidhead1_next 	    = skidhead1_r;
      skidpayload0_next     = skidpayload0_r;
      skidpayload1_next     = skidpayload1_r;
       
      case (fsm_r)

	POLLING:
	  if (out.ready) begin
	     //in_header.ready = 1'b1;
	     //in_payload.ready = 1'b1;

	     if (rr_payload_flag_r) begin
		// Give priority to payload
		in_payload.ready = 1'b1;
		
		if (in_payload.valid && in_payload.sop) begin

		   in_header.ready  = 1'b0;
		   out.valid 	 = in_payload.valid;
		   out.sop 	 = in_payload.sop;
		   out.eop 	 = in_payload.eop;
		   out.error 	 = in_payload.error;
		   out.empty 	 = in_payload.empty;
		   out.data 	 = in_payload.data;

		   rr_payload_flag_next = 1'b0;
		   fsm_next 	 = SEND_PAYLOAD;
		   o_payload_out = 1'b1;
		   		   
		end // if (in_payload.valid && in_payload.sop)
		
/* -----\/----- EXCLUDED -----\/-----
		else if (in_header.valid && in_header.sop) begin

		   in_payload.ready  = 1'b0;
		   out.valid 	  = in_header.valid;
		   out.sop 	  = in_header.sop;
		   out.eop 	  = in_header.eop;
		   out.error 	  = in_header.error;
		   out.empty 	  = in_header.empty;
		   out.data 	  = in_header.data;
		   fsm_next 	  = SEND_HEAD;
		   
		end
 -----/\----- EXCLUDED -----/\----- */
		 

	     end // if (rr_payload_flag_r)
	     else begin	
		// Give priority to header
		in_header.ready = 1'b1;
		
		if (in_header.valid && in_header.sop) begin

		   in_payload.ready  = 1'b0;
		   out.valid 	  = in_header.valid;
		   out.sop 	  = in_header.sop;
		   out.eop 	  = in_header.eop;
		   out.error 	  = in_header.error;
		   out.empty 	  = in_header.empty;
		   out.data 	  = in_header.data;

		   rr_payload_flag_next = 1'b1;
		   fsm_next 	  = SEND_HEAD;
		   
		end // if (in_header.valid && in_header.sop)
		
/* -----\/----- EXCLUDED -----\/-----
		else if (in_payload.valid && in_payload.sop) begin

		   in_header.ready  = 1'b0;
		   out.valid 	 = in_payload.valid;
		   out.sop 	 = in_payload.sop;
		   out.eop 	 = in_payload.eop;
		   out.error 	 = in_payload.error;
		   out.empty 	 = in_payload.empty;
		   out.data 	 = in_payload.data;
		   fsm_next 	 = SEND_PAYLOAD;
		   o_payload_out = 1'b1;
		   
		end // if (in_payload.valid && in_payload.sop)
 -----/\----- EXCLUDED -----/\----- */
		 
		 
	     end 
	     
	  end

	SEND_HEAD: 
	  if (out.ready) begin
	     
	     in_header.ready   = 1'b1;
	     in_payload.ready  = 1'b0;
	     out.valid 	       = in_header.valid;
	     out.sop 	       = in_header.sop;
	     out.eop 	       = in_header.eop;
	     out.error 	       = in_header.error;
	     out.empty 	       = in_header.empty;
	     out.data 	       = in_header.data;
	     
	     if (in_header.eop) begin
		
		if (rr_payload_flag_r && (skidpayload0_r.valid || skidpayload1_r.valid)) begin
		   fsm_next = SEND_REGISTERED_PAYLOAD;
		   rr_payload_flag_next = 1'b0;
		end else		
		  fsm_next = POLLING;
		
	     end
	     	     
	  end

	SEND_PAYLOAD: 
	  if (out.ready) begin

	     in_header.ready = 1'b0;
	     in_payload.ready = 1'b1;
	     out.valid  = in_payload.valid;
	     out.sop    = in_payload.sop;
	     out.eop    = in_payload.eop;
	     out.error  = in_payload.error;
	     out.empty  = in_payload.empty;
	     out.data   = in_payload.data;
	     o_payload_out = 1'b1;

	     if (in_payload.eop) begin

		if (!rr_payload_flag_r && (skidhead0_r.valid || skidhead1_r.valid)) begin
		   fsm_next = SEND_REGISTERED_HEAD;
		   rr_payload_flag_next = 1'b1;
		end else
		  fsm_next = POLLING;

	     end
	     
	  end // if (out.ready)

	SEND_REGISTERED_HEAD: 
	  if (out.ready) begin

	     if (skidhead0_r.valid) begin

		// head skids one cycle only (payload skids two cycles)
		out.valid 	      = skidhead0_r.valid;
		out.sop 	      = skidhead0_r.sop;
		out.eop 	      = skidhead0_r.eop;
		out.error 	      = skidhead0_r.error;
		out.empty 	      = skidhead0_r.empty;
		out.data 	      = skidhead0_r.data;

		//skidhead1_next 	      = skidhead0_r;
		skidhead0_next.valid  = 1'b0;

		if (out.eop)
		  fsm_next = POLLING;
				
	     end // if (skidhead1_r.valid)
	     else begin

		in_header.ready  = 1'b1;
		out.valid 	 = in_header.valid;
		out.sop 	 = in_header.sop;
		out.eop 	 = in_header.eop;
		out.error 	 = in_header.error;
		out.empty 	 = in_header.empty;
		out.data 	 = in_header.data;

		if (out.eop)
		  fsm_next = POLLING;
		else
		  fsm_next  = SEND_HEAD;		
		
	     end
	     
	  end
	
	SEND_REGISTERED_PAYLOAD: 
	  if (out.ready) begin

	     o_payload_out = 1'b1;
	     	     
	     if (skidpayload1_r.valid) begin
		
		out.valid 		 = skidpayload1_r.valid;
		out.sop 		 = skidpayload1_r.sop;
		out.eop 		 = skidpayload1_r.eop;
		out.error 		 = skidpayload1_r.error;
		out.empty 		 = skidpayload1_r.empty;
		out.data 		 = skidpayload1_r.data;

		skidpayload1_next 	 = skidpayload0_r;
		skidpayload0_next.valid  = 1'b0;
		
	     end // if (skidpayload1_r.valid)
	     else begin

		in_payload.ready = 1'b1;
		out.valid 	 = in_payload.valid;
		out.sop 	 = in_payload.sop;
		out.eop 	 = in_payload.eop;
		out.error 	 = in_payload.error;
		out.empty 	 = in_payload.empty;
		out.data 	 = in_payload.data;
		fsm_next 	 = SEND_PAYLOAD;		
		
	     end
	     	   
	  end

	default: begin

	end

      endcase

      if (!in_header.ready && in_header.valid) begin
	 
	 skidhead0_next.valid  = in_header.valid;
	 skidhead0_next.sop    = in_header.sop;
	 skidhead0_next.eop    = in_header.eop;
	 skidhead0_next.error  = in_header.error;
	 skidhead0_next.empty  = in_header.empty;
	 skidhead0_next.data   = in_header.data;

	 skidhead1_next = skidhead0_r;
	 
      end

      if (!in_payload.ready && in_payload.valid) begin
	  
	 skidpayload0_next.valid  = in_payload.valid;
	 skidpayload0_next.sop    = in_payload.sop;
	 skidpayload0_next.eop    = in_payload.eop;
	 skidpayload0_next.error  = in_payload.error;
	 skidpayload0_next.empty  = in_payload.empty;
	 skidpayload0_next.data   = in_payload.data;

	 skidpayload1_next = skidpayload0_r;

      end
                
   end // always_comb
   
endmodule
    
