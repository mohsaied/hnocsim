module arbiter2to1
  #(
    parameter NOC_WIDTH = 600
    )
   (
    input 		   clk,
    input 		   reset,

    input [NOC_WIDTH-1:0]  i_data1_in,
    input 		   i_valid1_in,
    output 		   i_ready1_out,

    input [NOC_WIDTH-1:0]  i_data2_in,
    input 		   i_valid2_in,
    output 		   i_ready2_out,

    output logic [NOC_WIDTH-1:0] o_data_out,
    output logic		   o_valid_out,
    input 		   o_ready_in

    );

   localparam FIFO_DEPTH = 32;

   logic [NOC_WIDTH-1:0]   fifo1_out; 
   logic [NOC_WIDTH-1:0]   fifo1_in;
   logic 		   fifo1_empty;
   logic 		   fifo1_full;
   logic 		   fifo1_wrreq;
   logic 		   fifo1_rdreq;
   logic [$clog2(FIFO_DEPTH)-1:0] fifo1_usedw;
   
   logic [NOC_WIDTH-1:0] 	  fifo2_out; 
   logic [NOC_WIDTH-1:0] 	  fifo2_in;
   logic 			  fifo2_empty;
   logic 			  fifo2_full;
   logic 			  fifo2_wrreq;
   logic 			  fifo2_rdreq;
   logic [$clog2(FIFO_DEPTH)-1:0] fifo2_usedw;

   assign fifo1_wrreq = i_valid1_in;
   assign fifo1_in = i_data1_in;
   assign fifo2_wrreq = i_valid2_in;
   assign fifo2_in = i_data2_in;

   assign i_ready1_out = FIFO_DEPTH - fifo1_usedw > 2;
   assign i_ready2_out = FIFO_DEPTH - fifo2_usedw > 2;
   
   fifo_emptyw #(.DEPTH(FIFO_DEPTH),
		 .WIDTH(NOC_WIDTH)) fifo_1 (.clock(clk),
					    .sclr(reset),
					    .rdreq(fifo1_rdreq),
					    .wrreq(fifo1_wrreq),
					    .full(fifo1_full),
					    .empty(fifo1_empty),
					    .data(fifo1_in),
					    .q(fifo1_out),
					    .usedw(fifo1_usedw));

   fifo_emptyw #(.DEPTH(FIFO_DEPTH),
		 .WIDTH(NOC_WIDTH)) fifo_2 (.clock(clk),
					    .sclr(reset),
					    .rdreq(fifo2_rdreq),
					    .wrreq(fifo2_wrreq),
					    .full(fifo2_full),
					    .empty(fifo2_empty),
					    .data(fifo2_in),
					    .q(fifo2_out),
					    .usedw(fifo2_usedw));

   logic 			  ready_in_r,ready_in_next;
   always_ff @(posedge clk) ready_in_r <= ready_in_next;
   always_comb ready_in_next = o_ready_in;

   logic 			  fifo1_empty_r, fifo1_empty_next;
   logic 			  fifo2_empty_r, fifo2_empty_next;
   always_ff @(posedge clk) fifo1_empty_r <= (reset) ? 1'b1 : fifo1_empty_next;
   always_ff @(posedge clk) fifo2_empty_r <= (reset) ? 1'b1 : fifo2_empty_next;
   always_comb begin
      // Defaults
      fifo1_empty_next = fifo1_empty_r;
      fifo2_empty_next = fifo2_empty_r;
      
      if (ready_in_r) begin

	 fifo1_empty_next = fifo1_empty;
	 fifo2_empty_next = fifo2_empty;
	 
      end
      
   end
   
   wire [3:0] 			  valid1_in;
   wire [3:0] 			  sop1_in;
   wire [3:0] 			  eop1_in;
   wire [3:0] 			  valid2_in;
   wire [3:0] 			  sop2_in;
   wire [3:0] 			  eop2_in;
   wire 			  eop1;
   wire 			  eop2;
   
   genvar 			  i;

   generate
      for (i=3; i>=0; i--) begin : ABC

	 assign valid1_in[i] = !fifo1_empty_r && fifo1_out[((i+1)*NOC_WIDTH/4)-1];
	 assign sop1_in[i] = fifo1_out[((i+1)*NOC_WIDTH/4)-2];
	 assign eop1_in[i] = fifo1_out[((i+1)*NOC_WIDTH/4)-3];
	 	 
	 assign valid2_in[i] = !fifo2_empty_r && fifo2_out[((i+1)*NOC_WIDTH/4)-1];
	 assign sop2_in[i] = fifo2_out[((i+1)*NOC_WIDTH/4)-2];
	 assign eop2_in[i] = fifo2_out[((i+1)*NOC_WIDTH/4)-3];
	 
      end
   endgenerate

   assign eop1 = (valid1_in[0] && eop1_in[0]) || 
		 (valid1_in[1] && eop1_in[1]) ||
		 (valid1_in[2] && eop1_in[2]) ||
		 (valid1_in[3] && eop1_in[3]);
   		 
   assign eop2 = (valid2_in[0] && eop2_in[0]) ||
		 (valid2_in[1] && eop2_in[1]) ||
		 (valid2_in[2] && eop2_in[2]) ||
		 (valid2_in[3] && eop2_in[3]);
   
   enum   {POLLING, SEND_ONE, SEND_TWO} fsm_r, fsm_next;
   always_ff @(posedge clk) fsm_r <= (reset) ? POLLING : fsm_next;

   logic  rr_flag_r, rr_flag_next;
   always_ff @(posedge clk) rr_flag_r <= (reset) ? 1'b0 : rr_flag_next;
   
   // Round robin arbitration
   always_comb begin
      // Defaults
      rr_flag_next = rr_flag_r;
      fsm_next = fsm_r;
      o_data_out = 'b0;
      o_valid_out = 1'b0;
      fifo1_rdreq = ready_in_r && !fifo1_empty;
      fifo2_rdreq = ready_in_r && !fifo2_empty;
                  
      case (fsm_r)

	POLLING: 
	  if (ready_in_r) begin

	     if (rr_flag_r) begin
		// Give priority to 2

		if (!fifo2_empty_r) begin
		   // Send 2
		   
		   fifo1_rdreq = 1'b0;
		   
		   o_data_out = fifo2_out;
		   o_valid_out = !fifo2_empty_r;
		 
		   rr_flag_next = 1'b0;

		   if (!eop2)
		     fsm_next = SEND_TWO;
/* -----\/----- EXCLUDED -----\/-----
		   else begin
		      if (fifo1_empty_r)
			fifo1_rdreq = ready_in_r && !fifo1_empty;
		      else
			fsm_next = SEND_ONE;
		   end
 -----/\----- EXCLUDED -----/\----- */
		   		   
		end
		else if (!fifo1_empty_r) begin
		   // Send 1

		   fifo2_rdreq = 1'b0;
		   
		   o_data_out = fifo1_out;
		   o_valid_out = !fifo1_empty_r;
	
		   if (!eop1)
		     fsm_next = SEND_ONE;
/* -----\/----- EXCLUDED -----\/-----
		   else begin
		      if (fifo2_empty_r)
			fifo2_rdreq = ready_in_r && !fifo2_empty;
		      else
			fsm_next = SEND_TWO;
		   end
 -----/\----- EXCLUDED -----/\----- */
		   
		end
		
		
	     end
	     else begin
		// Give priority to 1

		if (!fifo1_empty_r) begin
		   // Send 1
		   
		   fifo2_rdreq = 1'b0;
		   o_data_out = fifo1_out;
		   o_valid_out = !fifo1_empty_r;
		   rr_flag_next = 1'b1;

		   if (!eop1)
		     fsm_next = SEND_ONE;
		   		   
		end
		else if (!fifo2_empty_r) begin
		   // Send 2

		   fifo1_rdreq = 1'b0;
		   o_data_out = fifo2_out;
		   o_valid_out = !fifo2_empty_r;

		   if (!eop2)
		     fsm_next = SEND_TWO;
		   
		end
		
	     end // else: !if(rr_flag_r)
	     	     
	  end

	SEND_ONE: 
	  if (ready_in_r) begin

	     fifo2_rdreq = 1'b0;
	     o_data_out = fifo1_out;
	     o_valid_out = !fifo1_empty_r;
	     
	     if (eop1) begin

		fifo2_rdreq = ready_in_r && !fifo2_empty;

		// Give priority to 2

		if (!fifo2_empty) begin
		   // Send 2
		   
		   //fifo2_rdreq = ready_in_r && !fifo2_empty;
		   fifo1_rdreq = 1'b0;
		   rr_flag_next = 1'b0;
		   fsm_next = SEND_TWO;
		   
		end
		else if (!fifo1_empty) begin
		   // Send 1

		   //fifo1_rdreq = ready_in_r && !fifo1_empty;
		   fsm_next = SEND_ONE;
		   
		end
		else
		  fsm_next = POLLING;

	     end // if (eop1)
	          
	  end

	SEND_TWO: 
	  if (ready_in_r) begin

	     fifo1_rdreq = 1'b0;
	     o_data_out = fifo2_out;
	     o_valid_out = !fifo2_empty_r;
	     
	     if (eop2) begin

		fifo1_rdreq = ready_in_r && !fifo1_empty;

		// Give priority to 1

		if (!fifo1_empty) begin
		   // Send 1
		   
		   //fifo1_rdreq = ready_in_r && !fifo1_empty;
		   fifo2_rdreq = 1'b0;
		   rr_flag_next = 1'b1;
		   fsm_next = SEND_ONE;
		   
		end
		else if (!fifo2_empty) begin
		   // Send 2

		   //fifo2_rdreq = ready_in_r && !fifo2_empty;
		   fsm_next = SEND_TWO;
		   
		end
		else
		  fsm_next = POLLING;
	
	     end // if (eop2)
	     	     
	  end

      endcase

   end

endmodule
