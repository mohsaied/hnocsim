module recombine
  #(
    parameter DATA_WIDTH = 512,
    parameter FIFO_DEPTH = 32,
    parameter NODE_ID = 15,
    //parameter NUM_DDR = 4,
    parameter NOC_RADIX = 16,
    //parameter [$clog2(NOC_RADIX)-1:0] DDR_PORT [0:$clog2(NUM_DDR)-1] = '{4'd4, 4'd7, 4'd8, 4'd9}
    parameter [$clog2(NOC_RADIX)-1:0] DDR_PORT = 4'd4
    )
   (
    input clk,
    input reset,

    input i_payload_flag,
    input [31:0] i_pktid,
    avalonST.sink in,
    avalonST.src out_to_txr,
    avalonST.src out_data_req
    

    );

   typedef struct packed {
      logic 			     valid;
      logic 			     sop;
      logic 			     eop;
      logic 			     error;
      logic [$clog2(DATA_WIDTH/8)-1:0] empty;
      logic [DATA_WIDTH-1:0] 	     data;
   } avalonst_t;

   avalonst_t header_fifo_out; 
   logic [$bits(avalonst_t)+32-1:0]  header_fifo_in;
   logic 			 header_fifo_empty;
   logic 			 header_fifo_full;
   logic 			 header_fifo_wrreq;
   logic 			 header_fifo_rdreq;
   logic [$clog2(FIFO_DEPTH)-1:0] header_fifo_usedw;
   avalonst_t datareq_fifo_out; 
   avalonst_t  datareq_fifo_in;
   logic 			 datareq_fifo_empty;
   logic 			 datareq_fifo_full;
   logic 			 datareq_fifo_wrreq;
   logic 			 datareq_fifo_rdreq;
   logic [$clog2(32)-1:0] datareq_fifo_usedw;

   logic [31:0] 		  header_fifo_pktid_out;
   
   
   // Fifo to store received headers
   fifo_emptyw #(.DEPTH(FIFO_DEPTH),
		 .WIDTH($bits(avalonst_t)+32)) header_fifo (.clock(clk),
							 .sclr(reset),
							 .rdreq(header_fifo_rdreq),
							 .wrreq(header_fifo_wrreq),
							 .full(header_fifo_full),
							 .empty(header_fifo_empty),
							 .data(header_fifo_in),
							 .q({header_fifo_out,header_fifo_pktid_out}),
							 .usedw(header_fifo_usedw));


   enum {WAIT,STORE,SEND} fsm_r, fsm_next;
   always_ff @(posedge clk) fsm_r <= (reset) ? WAIT : fsm_next;

   logic send_payload_r, send_payload_next;
   always_ff @(posedge clk) send_payload_r <= (reset) ? 1'b0 : send_payload_next;

   logic [31:0] header_id_r, header_id_next;
   always_ff @(posedge clk) header_id_r <= (reset) ? 'b0 : header_id_next;
            
   always_comb begin
      // Defaults
      fsm_next 		     = fsm_r;
      send_payload_next      = send_payload_r;
      header_id_next 	     = header_id_r;
      header_fifo_in 	     = 'b0;
      header_fifo_wrreq      = 1'b0;
      header_fifo_rdreq      = 1'b0;
      in.ready 		     = 1'b0/*((32-usedw) <= 1)*/;

      out_to_txr.valid 	     = 1'b0;
      out_to_txr.sop 	     = 1'b0;
      out_to_txr.eop 	     = 1'b0;
      out_to_txr.error 	     = 1'b0;
      out_to_txr.empty 	     = 'b0;
      out_to_txr.data 	     = 'b0;

      datareq_fifo_wrreq     = 1'b0;
      datareq_fifo_in.valid  = 1'b0;
      datareq_fifo_in.sop    = 1'b0;
      datareq_fifo_in.eop    = 1'b0;
      datareq_fifo_in.error  = 1'b0;
      datareq_fifo_in.empty  = 'b0;
      datareq_fifo_in.data   = 'b0;
      
      case (fsm_r)

	WAIT: 
	  begin
	     in.ready = 1'b1;
	     	     
	     if (in.valid) begin

		if (in.sop) begin

		   if (i_payload_flag) begin
		      // Received payload

		      if (out_to_txr.ready) begin
			 header_fifo_rdreq  = 1'b1;

			 if (header_fifo_out.valid) begin

			    if (header_fifo_pktid_out == i_pktid) begin
						     
			       out_to_txr.valid   = 1'b1;
			       out_to_txr.sop     = 1'b1;
			       out_to_txr.eop     = 1'b0;
			       out_to_txr.error   = header_fifo_out.error;
			       out_to_txr.empty   = header_fifo_out.empty;
			       out_to_txr.data    = header_fifo_out.data;

			       if (header_fifo_out.eop)
				 send_payload_next = 1'b1;

			    end // if (header_fifo_pktid_out == in.data[DATA_WIDTH+31 -: 32])
			    else begin
			       
			       // Data request was not serviced properly
			       // Resend request
			       datareq_fifo_wrreq = 1'b1;
			       datareq_fifo_in.valid = 1'b1;
			       datareq_fifo_in.sop = 1'b1;
			       datareq_fifo_in.eop = 1'b1;
			       datareq_fifo_in.data[DATA_WIDTH-1] = 1'b0; // write flag
			       datareq_fifo_in.data[DATA_WIDTH-2] = 1'b1; // read flag
			       datareq_fifo_in.data[DATA_WIDTH-3 -: 32] = header_fifo_pktid_out; // internal id
			       datareq_fifo_in.data[DATA_WIDTH-3-32 -: $clog2(NOC_RADIX)] = NODE_ID; // request src

			    end
			    
			 end
			    
		      end
		      
		      in.ready = 1'b0;
		      fsm_next = SEND;
		      
		   end
		   else begin
		      // Received header
		      if (!header_fifo_full) begin

			 header_id_next = in.data[DATA_WIDTH-2 -: 32]; // store id from head
			 
			 // *Don't* discard header data beat
			 header_fifo_wrreq = 1'b1;
			 header_fifo_in = {in.valid,in.sop,in.eop,in.error,in.empty,in.data,header_id_next};
			 
			 // Place data req in fifo
			 datareq_fifo_wrreq = 1'b1;
			 datareq_fifo_in.valid = 1'b1;
			 datareq_fifo_in.sop = 1'b1;
			 datareq_fifo_in.eop = 1'b1;
			 datareq_fifo_in.data[DATA_WIDTH-1] = 1'b0; // write flag
			 datareq_fifo_in.data[DATA_WIDTH-2] = 1'b1; // read flag
			 datareq_fifo_in.data[DATA_WIDTH-3 -: 32] = in.data[DATA_WIDTH-2 -: 32]; // internal id
			 datareq_fifo_in.data[DATA_WIDTH-3-32 -: $clog2(NOC_RADIX)] = NODE_ID; // request src
			 if (datareq_fifo_full)
			   $error("Data request buffer overflow!");
			 
			 fsm_next = STORE;
			 
		      end
		      else
			in.ready = 1'b0;
		      		      
		   end

		end // if (in.sop)
		//else
		//  $error("Received non-SOP in WAIT state!");
	     	
	     end // if (in.valid)
	  end

	STORE: 
	  begin
	     in.ready = ((32-header_fifo_usedw) <= 1);
	     	     	     
	     if (!header_fifo_full) begin

		header_fifo_wrreq = 1'b1;
		header_fifo_in = {in.valid,in.sop,in.eop,in.error,in.empty,in.data,header_id_r};

		if (in.eop) begin
		   fsm_next = WAIT;
		   in.ready = 1'b1;
		end
		   			     
	     end

	  end

	SEND: 
	  if (out_to_txr.ready) begin

	     if (send_payload_r) begin
		// Send payload
		in.ready 	  = 1'b1;
		out_to_txr.valid  = 1'b1;
		out_to_txr.sop 	  = 1'b0;
		out_to_txr.eop 	  = in.eop;
		out_to_txr.error  = in.error;
		out_to_txr.empty  = in.empty;
		out_to_txr.data   = in.data;

		if (in.eop)
		  fsm_next = WAIT;
				
	     end
	     else begin
		// Send head

		header_fifo_rdreq  = 1'b1;

		if (header_fifo_out.valid) begin
		   out_to_txr.valid   = 1'b1;
		   out_to_txr.sop     = 1'b1; // Header is contained in one data beat
		   out_to_txr.eop     = 1'b0;
		   out_to_txr.error   = header_fifo_out.error;
		   out_to_txr.empty   = header_fifo_out.empty;
		   out_to_txr.data    = header_fifo_out.data;

		   if (header_fifo_out.eop)
		      send_payload_next = 1'b1;
		     		   
		end
		
	     end
	     
	  end // if (out_to_txr.ready)
	
	default: begin
	   fsm_next = WAIT;
	end

      endcase
      
   end // always_comb

   
   

   // Fifo to store data requests if NoC is not ready
   fifo_emptyw #(.DEPTH(32),
		 .WIDTH($bits(avalonst_t))) datareq_fifo (.clock(clk),
							  .sclr(reset),
							  .rdreq(datareq_fifo_rdreq),
							  .wrreq(datareq_fifo_wrreq),
							  .full(datareq_fifo_full),
							  .empty(datareq_fifo_empty),
							  .data(datareq_fifo_in),
							  .q(datareq_fifo_out),
							  .usedw(datareq_fifo_usedw));


   logic datareq_fifo_empty_r;
   always_ff @(posedge clk) datareq_fifo_empty_r <= (reset) ? 1'b1 : datareq_fifo_empty;
   
   // If a data req is in the fifo, send if NoC is ready
   always_comb begin
      // Defaults
      out_data_req.valid = 1'b0;
      out_data_req.sop = 1'b0;
      out_data_req.eop = 1'b0;
      out_data_req.error = 1'b0;
      out_data_req.empty = 'b0;
      out_data_req.data = 'b0;
      datareq_fifo_rdreq = 1'b0;

      if (out_data_req.ready) begin
	 
	 if (!datareq_fifo_empty)
	   datareq_fifo_rdreq = 1'b1;

	 if (datareq_fifo_out.valid && !datareq_fifo_empty_r) begin
	    out_data_req.valid = 1'b1;
	    out_data_req.sop = 1'b1;
	    out_data_req.eop = 1'b1;
	    out_data_req.error = 1'b0;
	    out_data_req.empty = 'b0; // not important
	    out_data_req.data = datareq_fifo_out.data;
	 end

      end
	 
   end

   // When a new header is received, place new data req into fifo
/* -----\/----- EXCLUDED -----\/-----
   always_comb begin
      // Defaults
      datareq_fifo_wrreq     = 1'b0;
      datareq_fifo_in.valid  = 1'b0;
      datareq_fifo_in.sop    = 1'b0;
      datareq_fifo_in.eop    = 1'b0;
      datareq_fifo_in.error  = 1'b0;
      datareq_fifo_in.empty  = 'b0;
      datareq_fifo_in.data   = 'b0;

      if (in.valid && in.sop) begin

	 datareq_fifo_wrreq = 1'b1;
	 datareq_fifo_in.valid = 1'b1;
	 datareq_fifo_in.sop = 1'b1;
	 datareq_fifo_in.eop = 1'b1;
	 datareq_fifo_in.data[DATA_WIDTH-1] = 1'b0; // write flag
	 datareq_fifo_in.data[DATA_WIDTH-2] = 1'b1; // read flag
	 datareq_fifo_in.data[DATA_WIDTH-3 -: 32] = in.data[DATA_WIDTH-2 -: 32]; // internal id
	 datareq_fifo_in.data[DATA_WIDTH-3-32 -: $clog2(NOC_RADIX)] = NODE_ID; // request src
	 
      end // if (in.valid && in.sop)

      if (datareq_fifo_full)
	$error("Data request buffer overflow!");
      
   end
 -----/\----- EXCLUDED -----/\----- */
      
   

endmodule
