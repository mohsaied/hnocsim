module send_header_payload
  #(
    parameter DATA_WIDTH = 64,
    parameter MAX_HEADER_SIZE = 1 // in data beats
    )
   (
    input clk,
    input reset,

    avalonST.sink in,
    avalonST.src out,

    output logic o_payload_out,
    output logic [31:0] o_id
    
    );   

   enum {SEND_HEAD,SEND_PAYLOAD_HEAD,SEND_PAYLOAD} fsm_r, fsm_next;
   always_ff @(posedge clk) fsm_r <= (reset) ? SEND_HEAD : fsm_next;
   
   // Counter to count header data beats
   logic [$clog2(MAX_HEADER_SIZE)+1:0] cnt_r, cnt_next;
   always_ff @(posedge clk) cnt_r <= (reset) ? 'b0 : cnt_next;

   // Register to store packet internal ID
   logic [31:0] pkt_id_r, pkt_id_next;
   always_ff @(posedge clk) pkt_id_r <= (reset) ? 'b0 : pkt_id_next;

   assign o_id = pkt_id_r;
   
   always_comb begin
      // Defaults
      fsm_next 	     = fsm_r;
      cnt_next 	     = cnt_r;
      o_payload_out  = 1'b0;
      pkt_id_next    = pkt_id_r;
      in.ready 	     = out.ready;
      out.valid      = 1'b0;
      out.sop 	     = 1'b0;
      out.eop 	     = 1'b0;
      out.error      = 1'b0;
      out.empty      = 'b0;
      out.data 	     = 'b0;

      case (fsm_r)

	SEND_HEAD: 
	  if (out.ready) begin

	     if (cnt_r == 'b0) begin

		if (in.valid && in.sop) begin

		   //Start header counter
		   cnt_next 	= cnt_r + 1;
		   out.valid 	= in.valid;
		   out.sop 	= in.sop;
		   out.eop 	= in.eop;
		   out.error 	= in.error;
		   out.empty 	= in.empty;
		   out.data 	= in.data;

		   // Save packet internal ID
		   pkt_id_next 	= in.data[DATA_WIDTH-2 -: 32];
		   
		end

	     end // if (cnt_r == 'b0)
	     else begin

		cnt_next   = cnt_r + 1;
		out.valid  = in.valid;
		out.sop    = in.sop;
		out.eop    = in.eop;
		out.error  = in.error;
		out.empty  = in.empty;
		out.data   = in.data;

		if (cnt_next >= MAX_HEADER_SIZE) begin

		   // Header finished
		   out.eop = 1'b1;
		   cnt_next = 'b0;
		   
		   if (!in.eop) begin
		      fsm_next = SEND_PAYLOAD_HEAD;
		   end
		   
		end

	     end

	  end // if (out.ready)
	
	SEND_PAYLOAD_HEAD: 
	  if (out.ready) begin

	     o_payload_out  = 1'b1;
	     out.valid 	    = in.valid;
	     out.sop 	    = 1'b1;
	     out.eop 	    = in.eop;
	     out.error 	    = in.error;
	     out.empty 	    = in.empty;
	     out.data 	    = in.data;

	     if (in.eop)
	       fsm_next = SEND_HEAD;			
	     else
	       fsm_next  = SEND_PAYLOAD;
	     
	  end

	SEND_PAYLOAD: 
	  if (out.ready) begin

	     o_payload_out  = 1'b1;
	     out.valid 	    = in.valid;
	     out.sop 	    = 1'b0;
	     out.eop 	    = in.eop;
	     out.error 	    = in.error;
	     out.empty 	    = in.empty;
	     out.data 	    = in.data;

	     if (in.eop) begin
		fsm_next = SEND_HEAD;			
	     end
   
	  end
	
      endcase

   end // always_comb

   
   
endmodule
