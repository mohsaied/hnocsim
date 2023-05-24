module obuffer #
  (
   parameter PACKET_WIDTH = 142,
   parameter DATA_WIDTH = 64,
   parameter DEPTH = 256
   )
   (
    input 			  clk,
    input 			  reset,

    input 			  i_valid,
    input [PACKET_WIDTH-1:0] 	  i_data,
    output 			  o_ready,

    output logic 		  o_valid,
    output logic 		  o_sop,
    output logic 		  o_eop,
    output logic [DATA_WIDTH-1:0] o_data,
    output logic [2:0] 		  o_empty,
    output logic 		  o_error,
    input 			  i_ready
    );

   wire [PACKET_WIDTH-1:0]    fifo_out_data; 
   wire 		      empty;
   wire 		      full;
   logic 		      rdreq;
      
   logic [7:0] 		      tail_cnt_r, tail_cnt_next;
   logic [7:0] 		      head_cnt_r, head_cnt_next;
   logic [PACKET_WIDTH/2-1:0] half_pkt_r, half_pkt_next;
   
   enum 		      {WAIT, EMPTY, SEND} fsm_r, fsm_next;

   logic 		  sop_flag_r, sop_flag_next;

   logic [$clog2(DEPTH)-1:0] space_left;
   
   
   fifo_emptyw  #(.DEPTH(DEPTH)) fifo (.clock(clk),
		 .sclr(reset),
		 .rdreq(rdreq&&!empty),
		 .wrreq(i_valid&&!full),
		 .full(full),
		 .empty(empty),
		 .data(i_data),
		 .q(fifo_out_data),
		 .usedw(space_left));


   assign o_ready = !full;   

   always_ff @(posedge clk or posedge reset) begin
      
      if (reset) begin
	 fsm_r 	    <= WAIT;
	 tail_cnt_r <= 'b0;
	 half_pkt_r <= 'b0;
	 head_cnt_r <= 'b0;
      end
      else begin
	 fsm_r 	    <= fsm_next;
	 tail_cnt_r <= tail_cnt_next;
	 half_pkt_r <= half_pkt_next;
	 head_cnt_r <= head_cnt_next;
      end
      
   end // always_ff @

   always_ff @(posedge clk or posedge reset) sop_flag_r <= (reset) ? 1'b0 : sop_flag_next;

   // head count
   always_comb begin
      head_cnt_next  = head_cnt_r;

      if (i_valid && i_data[PACKET_WIDTH-2] && o_valid && o_sop)
	head_cnt_next = head_cnt_r;
      else if (i_valid && i_data[PACKET_WIDTH-2])
	head_cnt_next = head_cnt_r + 1;
      else if (o_valid && o_sop)
	head_cnt_next = head_cnt_r - 1;
      
   end // always_comb

   always_comb begin

      if (tail_cnt_r > head_cnt_r) begin
	 $error("ERROR: Received more tails than heads in obuffer. (t=%d)",$time);
	 $finish;
      end
      else if (head_cnt_r - tail_cnt_r > 2) begin
	 $error("ERROR: Head count exceeds tail count by three or more. (t=%d)",$time);
	 $finish;
      end     

   end
   
   always_comb begin
      // defaults
      fsm_next 	     = fsm_r;
      tail_cnt_next  = tail_cnt_r;
      rdreq 	     = 1'b0;
      o_valid 	     = 1'b0;
      o_sop 	     = 1'b0;
      o_eop 	     = 1'b0;
      o_data 	     = 'b0;
      o_empty 	     = 'b0;
      o_error 	     = 1'b0;
      half_pkt_next  = half_pkt_r;

      sop_flag_next = sop_flag_r;
            
      case (fsm_r)

	WAIT: begin
	   if ((i_data[PACKET_WIDTH-3] || i_data[PACKET_WIDTH/2-3]) && i_valid) begin

	      if (!empty) begin
		 rdreq = 1'b1;
		 fsm_next = SEND;
	      end
	      else
		fsm_next = EMPTY;
	      
	   end
	   //else if (tail_cnt_r > 0) begin

	     // rdreq = 1'b1;
	     // fsm_next = SEND;

	   // end	   
	end

	EMPTY:
	  if (!empty) begin

	     rdreq = 1'b1;
	     fsm_next = SEND;
	   
	  end

	SEND: begin

	   if ((i_data[PACKET_WIDTH-3] || i_data[PACKET_WIDTH/2-3]) && i_valid)
	     tail_cnt_next = tail_cnt_r + 1;
	   
	   if (i_ready) begin
	      rdreq = 1'b1;
	      o_valid = 1'b1;
	      
	      if (half_pkt_r[PACKET_WIDTH/2-1]) begin

		 o_sop 		= half_pkt_r[PACKET_WIDTH/2-2];
		 o_eop 		= half_pkt_r[PACKET_WIDTH/2-3];
		 o_empty 	= half_pkt_r[PACKET_WIDTH/2-4:PACKET_WIDTH/2-6];
		 o_error 	= half_pkt_r[PACKET_WIDTH/2-7];
		 o_data 	= half_pkt_r[PACKET_WIDTH/2-8 -: DATA_WIDTH];

		 half_pkt_next 	= 'b0;

		 if (o_eop) begin

		    if (tail_cnt_r == 0 && tail_cnt_next == 0) begin
		       fsm_next = WAIT;
		       rdreq = 1'b0;
		    end
		    else if ((i_data[PACKET_WIDTH-3] || i_data[PACKET_WIDTH/2-3]) && i_valid) begin
		       tail_cnt_next = tail_cnt_r;
		       if (empty)
			 fsm_next = EMPTY;
		    end
		    else
		      tail_cnt_next = tail_cnt_r - 1;
		    		    
		 end
		    
	      end
	      else begin

		 o_sop 		= fifo_out_data[PACKET_WIDTH-2];
		 o_eop 		= fifo_out_data[PACKET_WIDTH-3];
		 o_empty 	= fifo_out_data[PACKET_WIDTH-4:PACKET_WIDTH-6];
		 o_error 	= fifo_out_data[PACKET_WIDTH-7];
		 o_data 	= fifo_out_data[PACKET_WIDTH-8 -: DATA_WIDTH];

		 if (o_eop) begin

		    if (tail_cnt_r == 0 && tail_cnt_next == 0) begin
		       fsm_next = WAIT;
		       rdreq = 1'b0;
		    end
		    else if ((i_data[PACKET_WIDTH-3] || i_data[PACKET_WIDTH/2-3]) && i_valid) begin
		       tail_cnt_next = tail_cnt_r;
		       if (empty)
			 fsm_next = EMPTY;
		    end
		    else
		      tail_cnt_next = tail_cnt_r - 1;
		    
		 end
		 else begin
		    half_pkt_next 	= fifo_out_data[PACKET_WIDTH/2-1:0];
		    rdreq 		= 1'b0;
		 end
		 
	      end // else: !if(half_pkt_r[PACKET_WIDTH/2-1])

	      // Debug
	       if (o_sop && o_eop)
		 sop_flag_next = 1'b0;
	       else if (o_sop) begin
		 if (sop_flag_r) begin
		    $error("ERROR: Obuffer received SOP, expecting EOP. (t=%d)",$time);
		    $finish;
		 end
		 else
		   sop_flag_next = 1'b1;
	       end
	       else if (o_eop) begin
		  if (sop_flag_r)
		    sop_flag_next = 1'b0;
		  else begin
		     $error("ERROR: Obuffer received EOP, expecting SOP. (t=%d)",$time);
		     $finish;
		  end
	       end
	       else begin
		  if (!sop_flag_r) begin
		     $error("ERROR: Obuffer received data, expecting SOP. (t=%d)",$time);
		     $finish;
		  end
	       end
	      
	   end // if (i_ready)

	end // case: SEND
	
      endcase
      
   end // always_comb
   
   

endmodule
    
