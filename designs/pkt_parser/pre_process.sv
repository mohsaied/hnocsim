module pre_process 
  #(
    parameter DATA_WIDTH = 64,
    parameter FIFO_DEPTH = 32,
    parameter NODE_ID = 7,
    parameter NOC_RADIX = 16
    )
   (
    input clk,
    input reset,
	  
    avalonST.sink in,
    avalonST.src  out
        
    );
   
   typedef struct packed {
      logic 			     valid;
      logic 			     sop;
      logic 			     eop;
      logic 			     error;
      logic [$clog2(DATA_WIDTH/8)-1:0] empty;
      logic [DATA_WIDTH-1:0] 	     data;
   } avalonst_t;

   avalonst_t fifo_out; 
   wire [$bits(avalonst_t)-1:0] 	fifo_in;
   wire 				fifo_empty;
   wire 				full;
   wire 				wrreq;
   logic 				rdreq;
   wire [$clog2(FIFO_DEPTH)-1:0] usedw;
   
   fifo_emptyw_auto #(.DEPTH(FIFO_DEPTH),
		      .WIDTH($bits(avalonst_t))) fifo (.clock(clk),
						       .sclr(reset),
						       .rdreq(rdreq),
						       .wrreq(wrreq),
						       .full(full),
						       .empty(fifo_empty),
						       .data(fifo_in),
						       .q(fifo_out),
						       .usedw(usedw));

   /* Input to FIFO */
   assign fifo_in = (in.valid&&!full) ? {in.valid,in.sop,in.eop,in.error,in.empty,in.data} : 'b0;
   assign wrreq = in.valid&&!full;
   assign in.ready = (FIFO_DEPTH-usedw > 1 && !full) && !reset;

   /* Output from FIFO */

   // skid register to hold sop while new header
   // is sent out
   avalonst_t skid_r,skid_next;
   always_ff @(posedge clk) begin
      skid_r.valid <= (reset) ? 1'b0 : skid_next.valid;
      skid_r.sop   <= (reset) ? 1'b0 : skid_next.sop;
      skid_r.eop   <= (reset) ? 1'b0 : skid_next.eop;
      skid_r.error <= (reset) ? 1'b0 : skid_next.error;
      skid_r.empty <= (reset) ? 'b0  : skid_next.empty;
      skid_r.data  <= (reset) ? 'b0  : skid_next.data;
   end
      
   // state machine
   enum {EMPTY,SOP,STALL,FORWARD} fsm_r, fsm_next;
   always_ff @(posedge clk) fsm_r <= (reset) ? EMPTY : fsm_next;

   logic [32-$clog2(NOC_RADIX)-1:0] pkt_cnt_r, pkt_cnt_next;
   always_ff @(posedge clk) pkt_cnt_r <= (reset) ? 'b0 : pkt_cnt_next;

/* -----\/----- EXCLUDED -----\/-----
   always_comb begin
      pkt_cnt_next = pkt_cnt_r;

      if (in.ready && in.valid && in.sop)
	pkt_cnt_next = pkt_cnt_r + 1;
      
   end
 -----/\----- EXCLUDED -----/\----- */
      
   int i;
      
   always_comb begin
      // Defaults
      fsm_next 	 = fsm_r;
      skid_next  = skid_r;
      rdreq 	 = 1'b0;
      out.valid  = 1'b0;
      out.sop 	 = 1'b0;
      out.eop 	 = 1'b0;
      out.error  = 1'b0;
      out.empty  = 'b0;
      out.data 	 = 'b0;
      i = 0;

      pkt_cnt_next = pkt_cnt_r;
                  
      case (fsm_r)

	EMPTY:
	  if (out.ready) begin

	     if (skid_r.valid) begin
		// finish sending last data beat of last packet
		out.valid  = skid_r.valid;
		out.sop    = 1'b0;
		out.eop    = skid_r.eop;
		out.error  = skid_r.error;
		out.empty  = skid_r.empty;
		out.data   = skid_r.data;

		skid_next  = '{0,0,0,0,0,0};
	     end
	     
	     if (!fifo_empty) begin
		
		rdreq = 1'b1;  

		if (fifo_out.valid && fifo_out.sop) begin
		   skid_next = fifo_out;

		   // Insert new header data beat
		   out.valid  = 1'b1;
		   out.sop    = 1'b1;
		   out.eop    = 1'b0;
		   out.error  = 1'b0;
		   out.empty  = 'b0;
		   out.data   = 'b0;
		   out.data[DATA_WIDTH-2 -: 4] = NODE_ID;
		   for (i=0;i<32-$clog2(NOC_RADIX);i++)
		     out.data[DATA_WIDTH-2-4-i] = pkt_cnt_r[i];
		   		   
		   pkt_cnt_next = pkt_cnt_r + 1;
		   
		   fsm_next = FORWARD;
		end
		else
		  fsm_next = STALL;

	     end
	     		
	  end
	
	STALL: 
	  if (out.ready) begin

	     if (fifo_empty) begin
		fsm_next = EMPTY;
		rdreq = 1'b0;
	     end
	     else if (skid_r.valid) begin

		if (skid_r.sop) begin

		   // Insert new header data beat
		   out.valid  = 1'b1;
		   out.sop    = 1'b1;
		   out.eop    = 1'b0;
		   out.error  = 1'b0;
		   out.empty  = 'b0;
		   out.data   = 'b0;
		   out.data[DATA_WIDTH-2 -: 4] = NODE_ID;
		   for (i=0;i<32-$clog2(NOC_RADIX);i++)
		     out.data[DATA_WIDTH-2-4-i] = pkt_cnt_r[i];

		   pkt_cnt_next = pkt_cnt_r + 1;

		   fsm_next = FORWARD;

		end
		else begin
		   
		   // finish sending last data beat of last packet
		   out.valid  = skid_r.valid;
		   out.sop    = 1'b0;
		   out.eop    = skid_r.eop;
		   out.error  = skid_r.error;
		   out.empty  = skid_r.empty;
		   out.data   = skid_r.data;

		   skid_next = fifo_out;
		   fsm_next = SOP;

		end
	     end
	     else if (fifo_out.valid && fifo_out.sop) begin
		rdreq = 1'b1;
		skid_next = fifo_out;

		// Insert new header data beat
		out.valid  = 1'b1;
		out.sop    = 1'b1;
		out.eop    = 1'b0;
		out.error  = 1'b0;
		out.empty  = 'b0;
		out.data   = 'b0;
		out.data[DATA_WIDTH-2 -: 4] = NODE_ID;
		for (i=0;i<32-$clog2(NOC_RADIX);i++)
		  out.data[DATA_WIDTH-2-4-i] = pkt_cnt_r[i];

		pkt_cnt_next = pkt_cnt_r + 1;
		
		fsm_next = FORWARD;
	     end // if (fifo_out.valid && fifo_out.sop)
	     
	end

	SOP: 
	  if (out.ready) begin
	     rdreq = 1'b1;
	     //skid_next = fifo_out;
	     
	     // Insert new header data beat
	     out.valid  = 1'b1;
	     out.sop    = 1'b1;
	     out.eop    = 1'b0;
	     out.error  = 1'b0;
	     out.empty  = 'b0;
	     out.data   = 'b0;
	     out.data[DATA_WIDTH-2 -: 4] = NODE_ID;
	     for (i=0;i<32-$clog2(NOC_RADIX);i++)
	       out.data[DATA_WIDTH-2-4-i] = pkt_cnt_r[i];

	     pkt_cnt_next = pkt_cnt_r + 1;

	     if (fifo_out.eop)
	       fsm_next = STALL;
	     else
	       fsm_next = FORWARD;
	     
	  end

	FORWARD:
	  if (out.ready) begin
	     rdreq = 1'b1;
	     skid_next = fifo_out;
	     
	     out.valid  = skid_r.valid;
	     out.sop    = 1'b0;
	     out.eop    = skid_r.eop;
	     out.error  = skid_r.error;
	     out.empty  = skid_r.empty;
	     out.data   = skid_r.data;

	     if (fifo_empty) begin
		fsm_next = EMPTY;
		rdreq = 1'b0;
	     end
	     else if (fifo_out.eop || skid_r.eop)
	       fsm_next = STALL;
	     	     	     
	  end

      endcase // case (fsm_r)

   end
   
endmodule

		     
