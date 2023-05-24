/* -----\/----- EXCLUDED -----\/-----
class rand_seed;

   rand integer v;
   
   function new_seed(int seed);
      $srandom(seed);
   endfunction // new_seed
   
endclass
 -----/\----- EXCLUDED -----/\----- */

module avalon_eth_source_sink #
  (
   parameter DATA_WIDTH = 64,
   parameter DEST_WIDTH = 4,
   parameter STORAGE = 16,
   parameter N = 16,
   parameter NUM_CYCLES = 32'd10000,
   parameter FIXED_PACKET_SIZE = 0,
   parameter INJECTION_RATE = 100,
   parameter SEED = 0
   )
   (
    input 		    clk,
    input 		    reset,

    output 		    o_valid [0:N-1],
    output 		    o_sop [0:N-1],
    output 		    o_eop [0:N-1],
    output 		    o_error [0:N-1],
    output [2:0] 	    o_empty [0:N-1],
    output [DATA_WIDTH-1:0] o_data [0:N-1],
    input 		    i_ready [0:N-1],

    input 		    i_valid [0:N-1],
    input 		    i_sop [0:N-1],
    input 		    i_eop [0:N-1],
    input 		    i_error [0:N-1],
    input [2:0] 	    i_empty [0:N-1],
    input [DATA_WIDTH-1:0]  i_data [0:N-1],
    output 		    o_ready [0:N-1]

    );

   int 			    unsigned pkt_size_r [0:N-1];
   int 			    unsigned pkt_size_next [0:N-1];
   int 			    unsigned rec_pkt_size_r [0:N-1];
   int 			    unsigned rec_pkt_size_next [0:N-1];
   int 			    unsigned cycle_count;
   int 			    unsigned id_r,id_next,id;
   int 			    unsigned i,j,k,q,r,a;
   int 			    unsigned cum_lat_r,cum_lat_next;
   int 			    unsigned received_pkt_cnt_r,received_pkt_cnt_next;
   int 			    unsigned sent_pkt_cnt_r,sent_pkt_cnt_next;
   int 			    unsigned flit_cnt_r, flit_cnt_next;
         
   
   logic [DEST_WIDTH-1:0]   dest;
   
   typedef struct {
      bit 	   valid;
      int 	   unsigned id;
      int 	   unsigned send_time;
   } pkts_in_flight;

   pkts_in_flight pif_buffer [0:2**STORAGE-1];


   // register newly generated data before sending out (why? ¯\_(ツ)_/¯ )
   logic 	   valid_next [0:N-1];
   logic 	   valid_r [0:N-1];
   logic 	   sop_next [0:N-1];
   logic 	   sop_r [0:N-1];
   logic 	   eop_next [0:N-1];
   logic 	   eop_r [0:N-1];
   logic 	   error_next [0:N-1];
   logic 	   error_r [0:N-1];
   logic [2:0] 	   empty_next [0:N-1];
   logic [2:0]	   empty_r [0:N-1];
   logic [DATA_WIDTH-1:0] data_next [0:N-1];
   logic [DATA_WIDTH-1:0] data_r [0:N-1];

   int 			  unsigned received_id;
   int 			  unsigned received_send_time;

   logic 		  bern_r [0:N-1];
   int 			  unsigned pkts_to_send_r [0:N-1];
   int 			  unsigned pkts_to_send_next [0:N-1];   

   int 			  unsigned random;
   int 			  unsigned seed_bern_r,seed_bern_next,seed_bern;
   int 			  unsigned seed_size_r,seed_size_next,seed_size;
   int 			  unsigned seed_dest_r,seed_dest_next,seed_dest;

   //always_ff @(posedge clk or posedge reset) seed_bern_r <= (reset) ? SEED : seed_bern_next;
   always_ff @(posedge clk or posedge reset) seed_size_r <= (reset) ? SEED+1 : seed_size_next;
   always_ff @(posedge clk or posedge reset) seed_dest_r <= (reset) ? SEED+2 : seed_dest_next;

   initial begin 
      seed_bern = SEED;
      //seed_bern_r = seed_bern;
   end
      
   always_ff @(posedge clk or posedge reset) begin

      //seed_bern = (reset) ? SEED : seed_bern_r;
            
      for (a=0;a<N;a++) begin
	 seed_bern = $urandom(seed_bern);
	 
	 //random = $urandom_range(10000,0);
	 random = seed_bern%10001;
	 //$display("Random bern: %d",random);	  
	 	 
	 bern_r[a] <= (random > INJECTION_RATE || reset) ? 1'b0 : 1'b1;
      end

      //seed_bern_r = seed_bern;
   end

   
   initial begin
      cycle_count = 0;
      //new_seed(SEED);
   end

   always_ff @(posedge clk or posedge reset) begin
            
      if (reset) begin
	 cycle_count  = 0;
	 id_r <= 'd0;
	 cum_lat_r <= 'd0;
	 received_pkt_cnt_r <= 'd0;
	 sent_pkt_cnt_r <= 'd0;
	 flit_cnt_r <= 'd0;
	 	 	 	 	 	 
	 for (k=0;k<N;k++) begin
	    rec_pkt_size_r[k] <= 'd0;
	    pkt_size_r[k] <= 'd0;
	    valid_r[k] <= 1'b0;
	    sop_r[k]   <= 1'b0;
	    eop_r[k]   <= 1'b0;
	    error_r[k] <= 1'b0;
	    empty_r[k] <= 'b0;
	    data_r[k]  <= 'b0;
	    pkts_to_send_r[k] <= 'd0;
	 end
      end
      else begin
	 id_r <= id_next;
	 cum_lat_r <= cum_lat_next;
	 received_pkt_cnt_r <= received_pkt_cnt_next;
	 sent_pkt_cnt_r <= sent_pkt_cnt_next;
	 flit_cnt_r <= flit_cnt_next;
	 	 	 
	 for (k=0;k<N;k++) begin
	    rec_pkt_size_r[k] <= rec_pkt_size_next[k];
	    pkt_size_r[k] <= pkt_size_next[k];
	    valid_r[k] <= valid_next[k];
	    sop_r[k]   <= sop_next[k];
	    eop_r[k]   <= eop_next[k];
	    error_r[k] <= error_next[k];
	    empty_r[k] <= empty_next[k];
	    data_r[k]  <= data_next[k];
	    pkts_to_send_r[k] <= pkts_to_send_next[k];
	 end
      end

      cycle_count = cycle_count + 1;
      
   end
   

      
   always @(negedge clk) begin
     //new_seed(seed_r+1);
     if (!reset) begin
	// ***** SEND PACKETS  *****

	// defaults
	received_pkt_cnt_next = received_pkt_cnt_r;
	cum_lat_next = cum_lat_r;
	sent_pkt_cnt_next = sent_pkt_cnt_r;
	flit_cnt_next = flit_cnt_r;
	id_next = id_r;
	
	id = id_r;

	seed_size = seed_size_r;
	seed_dest = seed_dest_r;
		
	for (q=0;q<N;q++) begin
	   valid_next[q] 	= 1'b0;
	   sop_next[q] 	= 1'b0;
	   eop_next[q] 	= 1'b0;
	   error_next[q] 	= 1'b0;
	   empty_next[q] 	= 'b0;
	   data_next[q] 	= 'b0;
	   pkts_to_send_next[q] = pkts_to_send_r[q];
	   	   
	   if (1'b1/*i_ready[q] && sent_pkt_cnt_r < NUM_PACKETS*/) begin

	      flit_cnt_next = flit_cnt_r + 1;
	      	      
	      if (pkt_size_r[q] == 0) begin // done sending packet

		 // send a new packet?
		 if (bern_r[q] || pkts_to_send_r[q] > 0) begin
		    
		    if (!bern_r[q] && pkts_to_send_r[q] > 0)
		      pkts_to_send_next[q] = pkts_to_send_r[q] - 1;
		    		    
		    valid_next[q] = 1'b1;
		    sop_next[q] = 1'b1;
		    
		    if (FIXED_PACKET_SIZE > 0)
		      pkt_size_next[q] = FIXED_PACKET_SIZE;
		    else begin
		       seed_size = $urandom(seed_size);
		       
		       //pkt_size_next[q] = $urandom_range(190,8); // packet size (# of flits)
		       pkt_size_next[q] = (seed_size%183)+8; // packet size (# of flits)
		    end
		    
		    //dest = $urandom_range(N-1,0);
		    seed_dest = $urandom(seed_dest);
		    dest = seed_dest%N;
		    //$display("dest: %d",dest);
		    		    		    
		    data_next[q][DATA_WIDTH-1 -: DEST_WIDTH] = dest;
		    data_next[q][DATA_WIDTH-1-DEST_WIDTH-1 -: 32] = id;
		    data_next[q][DATA_WIDTH-1-DEST_WIDTH-1-32-1 -: 8] = pkt_size_next[q];
		    data_next[q][DEST_WIDTH-1:0] = q[DEST_WIDTH-1:0]; // src
		    		    
		    // save send_time for latency measurement
		    for (r=0; r<2**STORAGE; r=r+1) begin
		       if (pif_buffer[r].valid == 1'b0) begin
			  pif_buffer[r].id = id_r;
			  pif_buffer[r].send_time = cycle_count + 1;
			  pif_buffer[r].valid = 1'b1;
			  break;
		       end
		    end

		    sent_pkt_cnt_next = sent_pkt_cnt_r + 1;
		    id = id + 1;
		    
		 end // if ($urandom_range(100,0) <= INJECTION_RATE)
		 		 
	      end
	      else begin // still sending packet

		 if (bern_r[q]) begin
		    pkts_to_send_next[q] = pkts_to_send_r[q] + 1;
		    
		 end		 
		 //if (bern_r[q]) begin
		 	    
		 valid_next[q] = 1'b1;
		 data_next[q][DATA_WIDTH-1-DEST_WIDTH-1 -: 32] = flit_cnt_r;
		 
		 if (pkt_size_r[q] == 1) begin
		    eop_next[q] = 1'b1;
		    empty_next[q] = $urandom_range(7,0);
		 end

		 pkt_size_next[q] = pkt_size_r[q] - 1;

	         //end
	      

	      end // else: !if(pkt_size == 0)
	      
	   end // if (i_ready)
	   
	end // for (q=0;q<N;q++)

	seed_size_next = seed_size;
	seed_dest_next = seed_dest;
	
	id_next = id;
	
	// ***** RECEIVE PACKETS  *****
	
	for (i=0;i<N;i++) begin
	   rec_pkt_size_r[i] <= rec_pkt_size_next[i];
	   	   
	   if (i_valid[i]) begin

	      if (i_sop[i]) begin
		 rec_pkt_size_next[i] = rec_pkt_size_r[i] + 1;
		 		 
		 received_id = i_data[i][DATA_WIDTH-1-DEST_WIDTH-1 -: 32];
		 for (j=0; j<2**STORAGE; j=j+1) begin
		    
		    if (pif_buffer[j].valid == 1'b1 && pif_buffer[j].id == received_id) begin

		       received_send_time = pif_buffer[j].send_time;
		       pif_buffer[j].valid = 1'b0;
		       break;
		       
		    end

		 end
		 
		 //$display("Pkt %d head latency: %d (Cycle: %d, Sent: %d)",received_id,cycle_count-received_send_time,cycle_count,received_send_time);
		 received_pkt_cnt_next = received_pkt_cnt_r + 1;
		 cum_lat_next = cum_lat_r + cycle_count-received_send_time;

		 //$display("*** AVERAGE PACKET HEAD LATENCY = %d", cum_lat_next/received_pkt_cnt_next);
	       	 
	      end
	      else if (i_eop) begin
/* -----\/----- EXCLUDED -----\/-----
		 if (rec_pkt_size_r[i] + 1 > 31) begin
		    $error("ERROR: Received pkt that's too big (%d). (t=%d)",rec_pkt_size_r[i]+1,$time);
		    $finish;
		 end
		 rec_pkt_size_next[i] = 0;
 -----/\----- EXCLUDED -----/\----- */
		 //$display("Pkt %d tail latency: %d",received_id,cycle_count-received_send_time);

	      end
	      else
		rec_pkt_size_next[i] = rec_pkt_size_r[i] + 1;
	      
	   end // if (i_valid)
	   
	end
        
     end // if (!reset)
   end
   

   genvar z;

   generate
      for (z=0;z<N;z++) begin
	 assign o_ready[z]  = 1'b1; // always ready
	 assign o_valid[z]  = valid_r[z];
	 assign o_sop[z]    = sop_r[z];
	 assign o_eop[z]    = eop_r[z];
	 assign o_empty[z]  = empty_r[z];
	 assign o_error[z]  = error_r[z];
	 assign o_data[z]   = data_r[z];
      end
   endgenerate 
  
   
   
endmodule
