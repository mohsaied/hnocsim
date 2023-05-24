module split_header_payload
  #(
    parameter DATA_WIDTH = 64,
    parameter MAX_HEADER_SIZE = 10, // in data beats
    parameter FIFO_DEPTH = 50
    )
   (
    input clk,
    input reset,

    avalonST.sink in,
    avalonST.src out_header,
    avalonST.src out_payload,

    output logic [31:0] o_id

    );

   typedef struct packed {
      logic 	  valid;
      logic 	  sop;
      logic 	  eop;
      logic 	  error;
      logic [$clog2(DATA_WIDTH/8)-1:0] empty;
      logic [DATA_WIDTH-1:0] 	       data;
   } avalonst_t;

   typedef struct packed {
      logic 	  valid;
      logic 	  sop;
      logic 	  eop;
      logic 	  error;
      logic [$clog2(DATA_WIDTH/8)-1:0] empty;
      logic [DATA_WIDTH+32-1:0]        data;
   } avalonst2_t;
   
   avalonst_t                           header_fifo_out; 
   avalonst_t                    	header_fifo_in;
   logic 				header_fifo_empty;
   logic 				header_fifo_full;
   logic 				header_fifo_wrreq;
   logic 				header_fifo_rdreq;
   logic [$clog2(FIFO_DEPTH)-1:0] 	header_fifo_usedw;
   
   avalonst2_t                           payload_fifo_out; 
   avalonst2_t                           payload_fifo_in; 
   logic 				payload_fifo_empty;
   logic 				payload_fifo_full;
   logic 				payload_fifo_wrreq;
   logic 				payload_fifo_rdreq;
   logic [$clog2(FIFO_DEPTH)-1:0] 	payload_fifo_usedw;
   
   enum {SEND_HEAD,SEND_PAYLOAD_HEAD,SEND_PAYLOAD}   fsm_r, fsm_next;
   always_ff @(posedge clk) fsm_r <= (reset) ? SEND_HEAD : fsm_next;

   // Counter to count header data beats
   logic [$clog2(MAX_HEADER_SIZE)+1:0] cnt_r, cnt_next;
   always_ff @(posedge clk) cnt_r <= (reset) ? 'b0 : cnt_next;

   // Register to store packet internal ID
   logic [31:0] 		     pkt_id_r, pkt_id_next;
   always_ff @(posedge clk) pkt_id_r <= (reset) ? 'b0 : pkt_id_next;


   //assign o_id = pkt_id_r;
      
   always_comb begin
      // Defaults
      fsm_next 		     = fsm_r;
      cnt_next 		     = cnt_r;
      pkt_id_next 	     = pkt_id_r;
      in.ready 		     = 1'b0;
      
      header_fifo_in.valid   = 1'b0;
      header_fifo_in.sop     = 1'b0;
      header_fifo_in.eop     = 1'b0;
      header_fifo_in.error   = 1'b0;
      header_fifo_in.empty   = 'b0;
      header_fifo_in.data    = 'b0;
      header_fifo_wrreq      = 1'b0;
      
      payload_fifo_in.valid  = 1'b0;
      payload_fifo_in.sop    = 1'b0;
      payload_fifo_in.eop    = 1'b0;
      payload_fifo_in.error  = 1'b0;
      payload_fifo_in.empty  = 'b0;
      payload_fifo_in.data   = 'b0;
      payload_fifo_wrreq      = 1'b0;
                                    
      
      case (fsm_r)

	SEND_HEAD: 
	  if (!header_fifo_full) begin
	     in.ready = 1'b1;
	     	       
	     if (cnt_r == 'b0) begin

		if (in.valid && in.sop) begin
		   
		   // Start header counter
		   header_fifo_wrreq     = 1'b1;
		   header_fifo_in.valid  = in.valid;
		   header_fifo_in.sop    = in.sop;
		   header_fifo_in.eop    = in.eop;
		   header_fifo_in.error  = in.error;
		   header_fifo_in.empty  = in.empty;
		   header_fifo_in.data   = in.data;
		   cnt_next 	     = cnt_r + 1;

		   // Save packet internal ID
		   pkt_id_next 	     = in.data[DATA_WIDTH-2 -: 32];

		   //if (cnt_next == MAX_HEADER_SIZE)
		   //  in.ready = 1'b0;
		   
		end

	     end // if (cnt_r == 'b0)
	     else begin

		header_fifo_wrreq     = 1'b1;
		header_fifo_in.valid  = in.valid;
		header_fifo_in.sop    = in.sop;
		header_fifo_in.eop    = in.eop;
		header_fifo_in.error  = in.error;
		header_fifo_in.empty  = in.empty;
		header_fifo_in.data   = in.data;
		cnt_next 	      = cnt_r + 1;

		// drop ready one cycle early to give time to propogate
		//if (cnt_next == MAX_HEADER_SIZE - 1)
		//  in.ready = 1'b0; 
		
		if (cnt_next >= MAX_HEADER_SIZE) begin

		   // Header finished
		   header_fifo_in.eop = 1'b1;
		   cnt_next = 'b0;
		   		   
		   if (!in.eop) begin
		      in.ready = !payload_fifo_full;
		      fsm_next = SEND_PAYLOAD_HEAD;
		      //fsm_next = SEND_PAYLOAD;
		   end
		   		   
		end
		
	     end
	   
	  end

	SEND_PAYLOAD_HEAD:
	  if (!payload_fifo_full) begin
	     in.ready 		    = 1'b1;

	     payload_fifo_wrreq     = 1'b1;
	     /*
	     payload_fifo_in.valid 		       = 1'b1;
	     payload_fifo_in.sop 		       = 1'b1;
	     payload_fifo_in.eop 		       = 1'b0;
	     payload_fifo_in.error 		       = 1'b0;
	     payload_fifo_in.empty 		       = 'b0;
	     payload_fifo_in.data[DATA_WIDTH-1]        = 1'b1; // payload flag
	     payload_fifo_in.data[DATA_WIDTH-2 -: 32]  = pkt_id_r; // internal id
	     payload_fifo_in.data[DATA_WIDTH-2-32:0]   = 'b0;
	      */

	     payload_fifo_wrreq     = 1'b1;
	     payload_fifo_in.valid  = in.valid;
	     payload_fifo_in.sop    = 1'b1;
	     payload_fifo_in.eop    = in.eop;
	     payload_fifo_in.error  = in.error;
	     payload_fifo_in.empty  = in.empty;
	     payload_fifo_in.data   = {in.data,pkt_id_r};

	     
	     if (in.eop)
	       fsm_next = SEND_HEAD;			
	     else
	       fsm_next  = SEND_PAYLOAD;
	     	     
	  end
	
	SEND_PAYLOAD: 
	  if (!payload_fifo_full) begin
	     in.ready 		    = 1'b1;

	     payload_fifo_wrreq     = 1'b1;
	     payload_fifo_in.valid  = in.valid;
	     payload_fifo_in.sop    = 1'b0;
	     payload_fifo_in.eop    = in.eop;
	     payload_fifo_in.error  = in.error;
	     payload_fifo_in.empty  = in.empty;
	     payload_fifo_in.data   = {in.data,pkt_id_r};

	     if (in.eop) begin
	       fsm_next = SEND_HEAD;			
	     end
	         	   
	end

	default: begin

	end

      endcase

   end // always_comb

   
   fifo_emptyw #(.DEPTH(FIFO_DEPTH),
		 .WIDTH($bits(avalonst_t))) header_fifo (.clock(clk),
							 .sclr(reset),
							 .rdreq(header_fifo_rdreq),
							 .wrreq(header_fifo_wrreq),
							 .full(header_fifo_full),
							 .empty(header_fifo_empty),
							 .data(header_fifo_in),
							 .q(header_fifo_out),
							 .usedw(header_fifo_usedw));

   fifo_emptyw #(.DEPTH(FIFO_DEPTH),
		 .WIDTH($bits(avalonst_t)+32)) payload_fifo (.clock(clk),
							 .sclr(reset),
							 .rdreq(payload_fifo_rdreq),
							 .wrreq(payload_fifo_wrreq),
							 .full(payload_fifo_full),
							 .empty(payload_fifo_empty),
							 .data(payload_fifo_in),
							 .q(payload_fifo_out),
							 .usedw(payload_fifo_usedw));

   

   // Delay empty signal by on clock cycle
   logic header_fifo_rdreq_r, payload_fifo_rdreq_r;
   always_ff @(posedge clk) begin
      header_fifo_rdreq_r <= (reset) ? 1'b0 : header_fifo_rdreq;
      payload_fifo_rdreq_r <= (reset) ? 1'b0 : payload_fifo_rdreq;
   end

   always_comb begin
      // Defaults
      out_header.valid 	 = 1'b0;
      out_header.sop 	 = 1'b0;
      out_header.eop 	 = 1'b0;
      out_header.error 	 = 1'b0;
      out_header.empty 	 = 'b0;
      out_header.data 	 = 'b0;
      
      //header_fifo_rdreq  = out_header.ready && (!header_fifo_empty || header_fifo_out.valid);
      header_fifo_rdreq  = out_header.ready && !header_fifo_empty;
      //header_fifo_rdreq  = out_header.ready;
            
      if (header_fifo_rdreq_r) begin
	 
	 //header_fifo_rdreq = 1'b1;
	 out_header.valid  = header_fifo_out.valid;
	 out_header.sop    = header_fifo_out.sop;
	 out_header.eop    = header_fifo_out.eop;
	 out_header.error  = header_fifo_out.error;
	 out_header.empty  = header_fifo_out.empty;
	 out_header.data   = header_fifo_out.data;
	 
      end

   end // always_comb

   logic [31:0] out_pktid_r, out_pktid_next;
   always_ff @(posedge clk) out_pktid_r <= (reset) ? 32'b0 : out_pktid_next;
      
   always_comb begin
      // Defaults
      out_pktid_next     = out_pktid_r;
      out_payload.valid  = 1'b0;
      out_payload.sop 	 = 1'b0;
      out_payload.eop 	 = 1'b0;
      out_payload.error  = 1'b0;
      out_payload.empty  = 'b0;
      out_payload.data 	 = 'b0;

      //payload_fifo_rdreq  = out_payload.ready && (!payload_fifo_empty || payload_fifo_out.valid);
      payload_fifo_rdreq  = out_payload.ready && !payload_fifo_empty;
      //payload_fifo_rdreq  = out_payload.ready;
            
      if (payload_fifo_rdreq_r) begin

	 //payload_fifo_rdreq = 1'b1;
	 out_payload.valid  = payload_fifo_out.valid;
	 out_payload.sop    = payload_fifo_out.sop;
	 out_payload.eop    = payload_fifo_out.eop;
	 out_payload.error  = payload_fifo_out.error;
	 out_payload.empty  = payload_fifo_out.empty;
	 out_payload.data   = payload_fifo_out.data[DATA_WIDTH+32-1 -: DATA_WIDTH];

	 if (payload_fifo_out.valid && payload_fifo_out.sop)
	   out_pktid_next = payload_fifo_out.data[31:0];
	 	 
      end
      
   end // always_comb

   assign o_id = out_pktid_r;
   

endmodule
    
    
