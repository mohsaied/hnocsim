module ddr_ipv4_top
  #(
    parameter DATA_WIDTH = 512,
    parameter NOC_WIDTH = 600,
    parameter NUM_VC = 2,
    parameter NOC_RADIX = 16,
    parameter DEST = 12,
    parameter NODE_ID = 4
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

   localparam FIFO_DEPTH = 8;

   wire [3:0]		 valid_in;
   wire [3:0]		 sop_in;
   wire [3:0]		 eop_in;
   wire 		 eop;
   wire 		 payload_flag;

   genvar 		 i;

   generate
      for (i=3; i>=0; i--) begin : WWW

	 assign valid_in[i] = i_valid_in && i_data_in[((i+1)*NOC_WIDTH/4)-1];
	 assign sop_in[i] = i_data_in[((i+1)*NOC_WIDTH/4)-2];
	 assign eop_in[i] = i_data_in[((i+1)*NOC_WIDTH/4)-3];
	 
      end
   endgenerate

   assign eop = eop_in[3] || eop_in[2] || eop_in[1] || eop_in[0];
   
   assign payload_flag = i_data_in[NOC_WIDTH-1-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-1] ||
			 i_data_in[NOC_WIDTH-1-3-$clog2(NUM_VC)-$clog2(NOC_RADIX)-2];
   

   logic [NOC_WIDTH-1:0] 	  ipv4_fifo_out; 
   logic [NOC_WIDTH-1:0] 	  ipv4_fifo_in;
   logic 			  ipv4_fifo_empty;
   logic 			  ipv4_fifo_full;
   logic 			  ipv4_fifo_wrreq;
   logic 			  ipv4_fifo_rdreq;
   logic [$clog2(FIFO_DEPTH)-1:0] ipv4_fifo_usedw;

   logic [NOC_WIDTH-1:0] 	  ddr_fifo_out; 
   logic [NOC_WIDTH-1:0] 	  ddr_fifo_in;
   logic 			  ddr_fifo_empty;
   logic 			  ddr_fifo_full;
   logic 			  ddr_fifo_wrreq;
   logic 			  ddr_fifo_rdreq;
   logic [$clog2(FIFO_DEPTH)-1:0] ddr_fifo_usedw;

   logic [NOC_WIDTH-1:0] 	  ipv4_data_in;
   logic 			  ipv4_valid_in;
   logic 			  ipv4_ready_out;
   logic [NOC_WIDTH-1:0] 	  ipv4_data_out;
   logic 			  ipv4_valid_out;
   logic 			  ipv4_ready_in;
   
   logic [NOC_WIDTH-1:0] 	  ddr_data_in;
   logic 			  ddr_valid_in;
   logic 			  ddr_ready_out;
   logic [NOC_WIDTH-1:0] 	  ddr_data_out;
   logic 			  ddr_valid_out;
   logic 			  ddr_ready_in; 
   
   
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

   // Fifo to store ddr packets
   fifo_emptyw #(.DEPTH(FIFO_DEPTH),
		 .WIDTH(NOC_WIDTH)) ddr_fifo (.clock(clk),
					      .sclr(reset),
					      .rdreq(ddr_fifo_rdreq && !ddr_fifo_empty),
					      .wrreq(ddr_fifo_wrreq),
					      .full(ddr_fifo_full),
					      .empty(ddr_fifo_empty),
					      .data(ddr_fifo_in),
					      .q(ddr_fifo_out),
					      .usedw(ddr_fifo_usedw)); 


   logic 			  ipv4_empty_r;
   always_ff @(posedge clk) ipv4_empty_r <= (reset) ? 1'b1 : ipv4_fifo_empty;

   logic 			  ddr_empty_r;
   always_ff @(posedge clk) ddr_empty_r <= (reset) ? 1'b1 : ddr_fifo_empty;

   always_comb begin
      ipv4_data_in   = ipv4_fifo_out;
      ipv4_valid_in  = ~ipv4_empty_r;
      ddr_data_in    = ddr_fifo_out;
      ddr_valid_in   = ~ddr_empty_r;
   end
   
   ipv4_top #(.DATA_WIDTH(DATA_WIDTH),
	      .NOC_WIDTH(NOC_WIDTH),
	      .NUM_VC(NUM_VC),
	      .NOC_RADIX(NOC_RADIX),
	      .DEST(DEST),
	      .PORT_ID(NODE_ID)) ipv4 (.clk(clk),
				       .reset(reset),
				       .i_data_in(ipv4_data_in),
				       .i_valid_in(ipv4_valid_in),
				       .i_ready_out(ipv4_fifo_rdreq),
				       .o_data_out(ipv4_data_out),
				       .o_valid_out(ipv4_valid_out),
				       .o_ready_in(ipv4_ready_in));
				   
   ddr_top #(.DATA_WIDTH(DATA_WIDTH/*+$clog2(DATA_WIDTH/8)*/),
	     .PORT_WIDTH(NOC_WIDTH),
	     .NUM_VC(NUM_VC),
	     .NOC_RADIX(NOC_RADIX)) ddr (.clk(clk),
					 .reset(reset),
					 .i_data_in(ddr_data_in),
					 .i_valid_in(ddr_valid_in),
					 .i_ready_out(ddr_fifo_rdreq),
					 .o_data_out(ddr_data_out),
					 .o_valid_out(ddr_valid_out),
					 .o_ready_in(ddr_ready_in));


   // Arbitrate between outputs of ipv4 and ddr module
   arbiter2to1 #(.NOC_WIDTH(NOC_WIDTH)) arbiter (.clk(clk),
						 .reset(reset),
						 .i_data1_in(ipv4_data_out),
						 .i_valid1_in(ipv4_valid_out),
						 .i_ready1_out(ipv4_ready_in),
						 .i_data2_in(ddr_data_out),
						 .i_valid2_in(ddr_valid_out),
						 .i_ready2_out(ddr_ready_in),
						 .o_data_out(o_data_out),
						 .o_valid_out(o_valid_out),
						 .o_ready_in(o_ready_in));
   

   // Sort incoming packets by destination: ipv4 or ddr?   
   enum 		 {WAIT,IPV4,DDR} fsm_r, fsm_next;
   always_ff @(posedge clk) fsm_r <= (reset) ? WAIT : fsm_next;

   always_comb begin
      // Defaults
      fsm_next 	       = fsm_r;
      ipv4_fifo_wrreq  = 1'b0;
      ipv4_fifo_in     = 'b0;
      ddr_fifo_wrreq   = 1'b0;
      ddr_fifo_in      = 'b0;
      i_ready_out      = (FIFO_DEPTH - ipv4_fifo_usedw > 1) && 
			 (FIFO_DEPTH - ddr_fifo_usedw > 1) &&
			 ~ipv4_fifo_full &&
			 ~ddr_fifo_full;
                  
      case (fsm_r)

	WAIT: 
	  if (i_valid_in && sop_in[3]) begin

	     if (payload_flag) begin

		ddr_fifo_wrreq = ~ddr_fifo_full;
		ddr_fifo_in = i_data_in;
		
		if (!eop || ddr_fifo_full)
		  fsm_next = DDR;
				
	     end
	     else begin

		ipv4_fifo_wrreq = ~ipv4_fifo_full;
		ipv4_fifo_in = i_data_in;

		if (!eop || ipv4_fifo_full)
		  fsm_next = IPV4;
				
	     end
	   
	  end

	IPV4: 
	  if (i_valid_in) begin

	     ipv4_fifo_wrreq = ~ipv4_fifo_full;
	     ipv4_fifo_in = i_data_in;
	     fsm_next = IPV4;

	     if (eop)
	       fsm_next = WAIT;
	     	     
	  end

	DDR: 
	  if (i_valid_in) begin

	     ddr_fifo_wrreq = ~ddr_fifo_full;
	     ddr_fifo_in = i_data_in;
	     fsm_next = DDR;

	     if (eop)
	       fsm_next = WAIT;

	  end

      endcase

   end // always_comb   						 
     

endmodule
   
