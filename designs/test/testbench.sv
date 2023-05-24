`timescale 1ps/1ps

module testbench();

   parameter VERBOSE = 1;
   parameter PORT_WIDTH = 600;
   parameter NOC_WIDTH = PORT_WIDTH/4;
   parameter N = 16;
   parameter NUM_VC = 2;
   parameter [$clog2(NUM_VC)-1:0] ASSIGNED_VC [0:N-1] = '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
   parameter STORAGE = 8;
   parameter DATA_WIDTH = 500;
   parameter SIM_LENGTH = 50; // in cycles

   parameter SRC0 = 0;
   parameter DEST0 = 14;
            
   localparam DEST_WIDTH = $clog2(N);
   localparam VC_ADDRESS_WIDTH = $clog2(NUM_VC);

   logic [N-1:0] 	 clk_rtl;
   logic [N-1:0] 	 clk_int;
   logic 		 clk_noc;
   logic 		 reset;
   
   //connections from rtl modules to noc
   logic [PORT_WIDTH-1:0] i_packets_in [0:N-1];
   logic 		  i_valids_in  [0:N-1];
   logic 		  i_readys_out [0:N-1];

   //connections from noc to rtl modules
   logic [PORT_WIDTH-1:0] o_packets_out [0:N-1];	
   logic 		  o_valids_out  [0:N-1];	
   logic 		  o_readys_in   [0:N-1];

   //pkt input interfaces
   logic [DATA_WIDTH-1:0] pkt_data_in;
   logic 		  pkt_valid_in;
   logic [DEST_WIDTH-1:0] pkt_dest_in;
   logic 		  pkt_ready_out;
   
   //pkt output interfaces
   logic [DATA_WIDTH-1:0]    pkt_data_out;
   logic 		     pkt_valid_out;
   logic 		     pkt_ready_in;

   typedef struct {
      bit 	   valid;
      int 	   unsigned id;
      int 	   unsigned send_time;
   } pkts_in_flight;

   pkts_in_flight pif_buffer [0:2**STORAGE-1];

   genvar 	   k;

   generate
      for (k=0;k<N;k++) begin
	 if (k != 0)
	   always_comb i_valids_in[k] = 1'b0;
	 
      end
   endgenerate
   
   fabric_interface #(.WIDTH_NOC(NOC_WIDTH),
		      .WIDTH_RTL(PORT_WIDTH),
		      .N(N),
		      .NUM_VC(NUM_VC),
		      .DEPTH_PER_VC(16),
		      .ASSIGNED_VC(ASSIGNED_VC),
		      .VERBOSE(0)
		      ) fabric_interface (.clk_noc(clk_noc),
					  .clk_rtl(clk_rtl),
					  .clk_int(clk_int),
					  .rst(reset),
					  .i_packets_in(i_packets_in),
					  .i_valids_in(i_valids_in),
					  .i_readys_out(i_readys_out),
					  .o_packets_out(o_packets_out),
					  .o_valids_out(o_valids_out),
					  .o_readys_in(o_readys_in)
					  );


   source #(.DATA_WIDTH(DATA_WIDTH),
	    .DEST_WIDTH(DEST_WIDTH),
	    .DEST(DEST0)
	    ) src0 (.clk(clk_rtl[0]),
			 .reset(reset),
			 .pkt_data_out(pkt_data_in),
			 .pkt_dest_out(pkt_dest_in),
			 .pkt_valid_out(pkt_valid_in),
			 .pkt_ready_in(pkt_ready_out));
   
   
   packetizer #(.ADDRESS_WIDTH(DEST_WIDTH),
		.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
		.WIDTH_IN(DATA_WIDTH),
		.WIDTH_OUT(PORT_WIDTH),
		.ASSIGNED_VC(0)
		) pkt0_inst (.i_data_in(pkt_data_in),
			    .i_valid_in(pkt_valid_in),
			    .i_dest_in(pkt_dest_in),
			    .i_ready_out(pkt_ready_out),
			    
			    .o_data_out(i_packets_in[SRC0]),
			    .o_valid_out(i_valids_in[SRC0]),
			    .o_ready_in(i_readys_out[SRC0])
			    );

   depacketizer #(.ADDRESS_WIDTH(DEST_WIDTH),
		  .VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
		  .WIDTH_PKT(PORT_WIDTH),
		  .WIDTH_DATA(DATA_WIDTH)
		  ) depkt1_inst (.i_packet_in(o_packets_out[DEST0]),
				.i_valid_in(o_valids_out[DEST0]),
				.i_ready_out(o_readys_in[DEST0]),
				
				.o_data_out(pkt_data_out),
				.o_valid_out(pkt_valid_out),
				.o_ready_in(1'b1)
				);

   int unsigned cycle_count;
   int unsigned received_pkt_cnt_r, received_pkt_cnt_next;
   int unsigned cum_lat_r, cum_lat_next;
            
   initial begin
      cycle_count = 0;
   end

   always_ff @(posedge clk_rtl or posedge reset) begin
      cycle_count 	  = (reset) ? 0 : cycle_count + 1;
      received_pkt_cnt_r <= (reset) ? 'b0 : received_pkt_cnt_next;
      cum_lat_r 	 <= (reset) ? 'b0 : cum_lat_next;
            
      if (cycle_count > SIM_LENGTH) begin
	 $display("\n*** FINAL STATS ***");
	 $display("Cycle count                = %d",cycle_count);
	 $display("Number of packets received = %d",received_pkt_cnt_r);
	 $display("Average packet latency     = %f",real'(cum_lat_r)/real'(received_pkt_cnt_r));
	 $finish;
      end
            
   end

   int unsigned r;
   int unsigned received_send_time;
   logic [31:0] received_id;
   
         
   always @(negedge clk_rtl) begin
      // defaults
      received_pkt_cnt_next  = received_pkt_cnt_r;
      cum_lat_next 	     = cum_lat_r;
            
      if (pkt_valid_in) begin

	 for (r=0; r<2**STORAGE; r=r+1) begin

	    if (pif_buffer[r].valid == 1'b0) begin
	       pif_buffer[r].id = pkt_data_in[DATA_WIDTH-1 -: 32];
	       pif_buffer[r].send_time = cycle_count;
	       pif_buffer[r].valid = 1'b1;
	       break;
	    end

	 end

      end

      if (pkt_valid_out) begin // received a packet
	 
	 received_pkt_cnt_next = received_pkt_cnt_r + 1;
	 received_id = pkt_data_out[DATA_WIDTH-1 -: 32];
	 	 	 	 
	 for (r=0; r<2**STORAGE; r=r+1) begin

	    if (pif_buffer[r].valid == 1'b1 && pif_buffer[r].id == received_id) begin
	       received_send_time = pif_buffer[r].send_time;
	       pif_buffer[r].valid = 1'b0;
	       cum_lat_next = cum_lat_r + (cycle_count - received_send_time);

	       if (VERBOSE > 0)
		 $display("Received pkt %d with latency: %d (Cycle: %d, Sent: %d)", received_id,(cycle_count - received_send_time),cycle_count,received_send_time);
	       	       
	       break;
	    end

	 end

      end
      
   end // always_comb

   genvar j;
   
   generate
      for (j=0;j<N;j++) begin
	 initial clk_rtl[j] = 1'b1;
	 always #6400 clk_rtl[j] = ~clk_rtl[j]; // 156.25 MHz clock
	 
	 initial clk_int[j] = 1'b1;
	 always #1600 clk_int[j] = ~clk_int[j]; // 625 MHz clock
	 	 
      end
   endgenerate
   
   initial clk_noc = 1'b1;
   always #833 clk_noc = ~clk_noc; // 1.2 GHz clock
   

   initial begin
      reset = 1'b0;
      #100;
      reset = 1'b1;
      #13000;
      reset = 1'b0;
   end
   

endmodule
