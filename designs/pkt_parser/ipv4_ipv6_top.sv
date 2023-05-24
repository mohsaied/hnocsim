module ipv4_ipv6_top
  #(
    parameter DATA_WIDTH = 512,
    parameter NOC_WIDTH = 600,
    parameter NUM_VC = 2,
    parameter NOC_RADIX = 16,
    parameter PORT_ID = 4,
    parameter NUM_SRC = 4,
    parameter [3:0] DEST [0:NUM_SRC-1] = '{4'd12,4'd13,4'd14,4'd15}
    )
   (
    input clk,
    input reset,

    input [NOC_WIDTH-1:0] i_data_in,
    input i_valid_in,
    output logic i_ready_out,

    output logic [NOC_WIDTH-1:0] o_data_out,
    output logic o_valid_out,
    input o_ready_in
    
    );

   import global_package::*;
      
   localparam FIFO_DEPTH = 8;

   wire [3:0] valid_in;
   wire [3:0] sop_in;
   wire [3:0] eop_in;
   wire       eop;
   wire [2:0] dest_mod;

   genvar     i;

   generate
      for (i=3; i>=0; i--) begin : WWW

	 assign valid_in[i] = i_valid_in && i_data_in[((i+1)*NOC_WIDTH/4)-1];
	 assign sop_in[i] = i_data_in[((i+1)*NOC_WIDTH/4)-2];
	 assign eop_in[i] = i_data_in[((i+1)*NOC_WIDTH/4)-3];
	 
      end
   endgenerate

   assign eop = eop_in[3] || eop_in[2] || eop_in[1] || eop_in[0];
   
   assign dest_mod = i_data_in[NOC_WIDTH-1-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-1-32-7 -: 3];
   
   
   logic [NOC_WIDTH-1:0] 	  ipv4_fifo_out; 
   logic [NOC_WIDTH-1:0] 	  ipv4_fifo_in;
   logic 			  ipv4_fifo_empty;
   logic 			  ipv4_fifo_full;
   logic 			  ipv4_fifo_wrreq;
   logic 			  ipv4_fifo_rdreq;
   logic [$clog2(FIFO_DEPTH)-1:0] ipv4_fifo_usedw;

   logic [NOC_WIDTH-1:0] 	  ipv6_fifo_out; 
   logic [NOC_WIDTH-1:0] 	  ipv6_fifo_in;
   logic 			  ipv6_fifo_empty;
   logic 			  ipv6_fifo_full;
   logic 			  ipv6_fifo_wrreq;
   logic 			  ipv6_fifo_rdreq;
   logic [$clog2(FIFO_DEPTH)-1:0] ipv6_fifo_usedw;

   logic [NOC_WIDTH-1:0] 	  ipv4_data_in_next,ipv4_data_in_r;
   logic 			  ipv4_valid_in_next,ipv4_valid_in_r;
   logic 			  ipv4_ready_out;
   logic [NOC_WIDTH-1:0] 	  ipv4_data_out;
   logic 			  ipv4_valid_out;
   logic 			  ipv4_ready_in;
   
   logic [NOC_WIDTH-1:0] 	  ipv6_data_in_next,ipv6_data_in_r;
   logic 			  ipv6_valid_in_next,ipv6_valid_in_r;
   logic 			  ipv6_ready_out;
   logic [NOC_WIDTH-1:0] 	  ipv6_data_out;
   logic 			  ipv6_valid_out;
   logic 			  ipv6_ready_in; 
   
   
   // Fifo to store ipv4 packets
   fifo_emptyw #(.DEPTH(FIFO_DEPTH),
		 .WIDTH(NOC_WIDTH)) ipv4_fifo (.clock(clk),
					       .sclr(reset),
					       .rdreq(ipv4_fifo_rdreq && !ipv4_fifo_empty),
					       .wrreq(ipv4_fifo_wrreq),
					       .full(ipv4_fifo_full),
					       .empty(ipv4_fifo_empty),
					       .data(ipv4_fifo_in),
					       .q(ipv4_fifo_out),
					       .usedw(ipv4_fifo_usedw));

   // Fifo to store ipv6 packets
   fifo_emptyw #(.DEPTH(FIFO_DEPTH),
		 .WIDTH(NOC_WIDTH)) ipv6_fifo (.clock(clk),
					      .sclr(reset),
					      .rdreq(ipv6_fifo_rdreq && !ipv6_fifo_empty),
					      .wrreq(ipv6_fifo_wrreq),
					      .full(ipv6_fifo_full),
					      .empty(ipv6_fifo_empty),
					      .data(ipv6_fifo_in),
					      .q(ipv6_fifo_out),
					      .usedw(ipv6_fifo_usedw)); 


   logic 			  ipv4_empty_r;
   always_ff @(posedge clk) ipv4_empty_r <= (reset) ? 1'b1 : ipv4_fifo_empty;

   logic 			  ipv6_empty_r;
   always_ff @(posedge clk) ipv6_empty_r <= (reset) ? 1'b1 : ipv6_fifo_empty;

/* -----\/----- EXCLUDED -----\/-----
   always_comb begin
      ipv4_data_in_next   = ipv4_fifo_out;
      ipv4_valid_in_next  = ~ipv4_empty_r;
      ipv6_data_in_next    = ipv6_fifo_out;
      ipv6_valid_in_next   = ~ipv6_empty_r;
   end
 -----/\----- EXCLUDED -----/\----- */

/* -----\/----- EXCLUDED -----\/-----
   always_ff @(posedge clk) begin

      ipv4_data_in_r  <= (reset) ? 'b0 : ipv4_data_in_next;
      ipv6_data_in_r  <= (reset) ? 'b0 : ipv6_data_in_next;
      ipv4_valid_in_r <= (reset) ? 'b0 : ipv4_valid_in_next;
      ipv6_valid_in_r <= (reset) ? 'b0 : ipv6_valid_in_next;
      
   end
 -----/\----- EXCLUDED -----/\----- */
   
   ipv4_top #(.DATA_WIDTH(DATA_WIDTH),
	      .NOC_WIDTH(NOC_WIDTH),
	      .NUM_VC(NUM_VC),
	      .NOC_RADIX(NOC_RADIX),
	      .NUM_SRC(NUM_SRC),
	      .DEST(DEST),
	      .PORT_ID(PORT_ID)) ipv4 (.clk(clk),
				       .reset(reset),
				       .i_data_in(ipv4_fifo_out/*ipv4_data_in_r*/),
				       .i_valid_in(~ipv4_empty_r/*ipv4_valid_in_r*/),
				       .i_ready_out(ipv4_fifo_rdreq),
				       .o_data_out(ipv4_data_out),
				       .o_valid_out(ipv4_valid_out),
				       .o_ready_in(ipv4_ready_in));
				   
   ipv6_top #(.DATA_WIDTH(DATA_WIDTH),
	      .NOC_WIDTH(NOC_WIDTH),
	      .NUM_VC(NUM_VC),
	      .NOC_RADIX(NOC_RADIX),
	      .NUM_SRC(NUM_SRC),
	      .DEST(DEST),
	      .PORT_ID(PORT_ID)) ipv6 (.clk(clk),
				       .reset(reset),
				       .i_data_in(ipv6_fifo_out/*ipv6_data_in_r*/),
				       .i_valid_in(~ipv6_empty_r/*ipv6_valid_in_r*/),
				       .i_ready_out(ipv6_fifo_rdreq),
				       .o_data_out(ipv6_data_out),
				       .o_valid_out(ipv6_valid_out),
				       .o_ready_in(ipv6_ready_in));


   // Arbitrate between outputs of ipv4 and ipv6 module
   arbiter2to1 #(.NOC_WIDTH(NOC_WIDTH)) arbiter (.clk(clk),
						 .reset(reset),
						 .i_data1_in(ipv4_data_out),
						 .i_valid1_in(ipv4_valid_out),
						 .i_ready1_out(ipv4_ready_in),
						 .i_data2_in(ipv6_data_out),
						 .i_valid2_in(ipv6_valid_out),
						 .i_ready2_out(ipv6_ready_in),
						 .o_data_out(o_data_out),
						 .o_valid_out(o_valid_out),
						 .o_ready_in(o_ready_in));


   // *** DEBUG ***

/* -----\/----- EXCLUDED -----\/-----
   logic sop_r, sop_next;
   always_ff @(posedge clk) sop_r <= (reset) ? 'b0 : sop_next;

   always @(negedge clk) begin
      sop_next = sop_r;

      if (o_valid_out && o_data_out[599]) begin

	 if (o_data_out[598]) begin

	    if (sop_r)
	      $error("IPS %.2d: Sending SOP before sending EOP for prev packet",PORT_ID);
	    else
	      sop_next = 1'b1;
	    
	 end
	 else if (o_data_out[597] || o_data_out[447] || o_data_out[297] || o_data_out[147]) begin

	    if (sop_r)
	      sop_next = 1'b0;
	    else
	      $error("IPS %.2d: Sending EOP without an SOP",PORT_ID);

	 end
	 else begin

	    if (!sop_r)
	      $error("IPS %.2d: Sending body flit without an SOP",PORT_ID);
	    
	 end

      end
      
   end // always_comb
 -----/\----- EXCLUDED -----/\----- */

   // **************
   

   // Sort incoming packets by destination: ipv4 or ipv6?   
   enum 		 {WAIT,IPV4,IPV6} fsm_r, fsm_next;
   always_ff @(posedge clk) fsm_r <= (reset) ? WAIT : fsm_next;

   mod_t ipv4_m,ipv6_m;
   assign ipv4_m = ipv4_mod;
   assign ipv6_m = ipv6_mod;
   
   always_comb begin
      // Defaults
      fsm_next 	       = fsm_r;
      ipv4_fifo_wrreq  = 1'b0;
      ipv4_fifo_in     = 'b0;
      ipv6_fifo_wrreq   = 1'b0;
      ipv6_fifo_in      = 'b0;
      i_ready_out      = (FIFO_DEPTH - ipv4_fifo_usedw > 1) && 
			 (FIFO_DEPTH - ipv6_fifo_usedw > 1) &&
			 ~ipv4_fifo_full &&
			 ~ipv6_fifo_full;
                  
      case (fsm_r)

	WAIT: 
	  if (i_valid_in && sop_in[3]) begin

	     if (dest_mod == ipv6_m) begin

		ipv6_fifo_wrreq = ~ipv6_fifo_full;
		ipv6_fifo_in = i_data_in;
		
		if (!eop || ipv6_fifo_full)
		  fsm_next = IPV6;
				
	     end
	     else if (dest_mod == ipv4_m) begin

		ipv4_fifo_wrreq = ~ipv4_fifo_full;
		ipv4_fifo_in = i_data_in;

		if (!eop || ipv4_fifo_full)
		  fsm_next = IPV4;
				
	     end
	     else
	       $error("Error in read of destination module.");
	     	   
	  end

	IPV4: 
	  if (i_valid_in) begin

	     ipv4_fifo_wrreq = ~ipv4_fifo_full;
	     ipv4_fifo_in = i_data_in;
	     fsm_next = IPV4;

	     if (eop)
	       fsm_next = WAIT;
	     	     
	  end

	IPV6: 
	  if (i_valid_in) begin

	     ipv6_fifo_wrreq = ~ipv6_fifo_full;
	     ipv6_fifo_in = i_data_in;
	     fsm_next = IPV6;

	     if (eop)
	       fsm_next = WAIT;

	  end

      endcase

   end // always_comb   						 
     

endmodule
   
