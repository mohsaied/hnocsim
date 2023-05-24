module top #
  (
   parameter OUT_WIDTH = 600, // PACKET_WIDTH*4 + 8 + 4 + 4 + 4
   parameter PACKET_WIDTH = 142, // (DATA_WIDTH+1+1+1+3+1)*2
   parameter DATA_WIDTH = 64,
   parameter DEST_WIDTH = 4,
   parameter N = 16,
   parameter NUM_VC = 2,
   parameter INPUT_DEPTH = 256,
   parameter OUTPUT_DEPTH = 256,
   
   parameter STORAGE = 16,
   parameter WARMUP_CYCLES = 500,
   parameter NUM_CYCLES = 10000,
   parameter VERBOSE = 0,
   parameter END_SIM_COUNT = 10,
   parameter real END_SIM_THRESH = 0.5,
   parameter INJECTION_RATE = 122,
   parameter [$clog2(NUM_VC)-1:0] ASSIGNED_VC [0:N-1] = '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
   )
   (
    input 		    clk,
    input 		    reset,

    input 		    i_valid_avalon_in [0:N-1],
    input 		    i_sop_avalon_in [0:N-1],
    input 		    i_eop_avalon_in [0:N-1],
    input [DATA_WIDTH-1:0]  i_data_avalon_in [0:N-1],
    input [2:0] 	    i_empty_avalon_in [0:N-1],
    input 		    i_error_avalon_in [0:N-1],
    output 		    o_ready_avalon_in [0:N-1],

    output 		    o_valid_avalon_out [0:N-1],
    output 		    o_sop_avalon_out [0:N-1],
    output 		    o_eop_avalon_out [0:N-1],
    output [DATA_WIDTH-1:0] o_data_avalon_out [0:N-1],
    output [2:0] 	    o_empty_avalon_out [0:N-1],
    output 		    o_error_avalon_out [0:N-1],
    input 		    i_ready_avalon_out [0:N-1],


    output [OUT_WIDTH-1:0]  o_data_to_noc [0:N-1],
    output 		    o_valid_to_noc [0:N-1],
    input 		    i_ready_to_noc [0:N-1],

    input [OUT_WIDTH-1:0]   i_data_from_noc [0:N-1],
    input 		    i_valid_from_noc [0:N-1],
    output 		    o_ready_from_noc [0:N-1]
   
    );



   wire [PACKET_WIDTH-1:0] data_b2p [0:N-1];
   wire [DEST_WIDTH-1:0]   dest_b2p [0:N-1];
   wire 		   ready_bout2p [0:N-1];
   wire 		   ready_bin2p [0:N-1];
   wire 		   valid_b2p [0:N-1];
   wire [PACKET_WIDTH-1:0] data_p2b [0:N-1];
   wire 		   ready_p2b [0:N-1];
   wire 		   valid_p2b [0:N-1];

   
   logic [$clog2(INPUT_DEPTH)-1:0] space_left [0:N-1];
   logic 			   drop_r [0:N-1];
   logic 			   drop_next [0:N-1];
   logic 			   valid_in [0:N-1];
   
   int 				   unsigned drop_cnt_r, drop_cnt_next, drop_cnt;

   
   typedef struct {
      bit 	   valid;
      int 	   unsigned id;
      int 	   unsigned send_time;
      int 	   unsigned src;
   } pkts_in_flight;

   pkts_in_flight pif_buffer [0:2**STORAGE-1];

   int 		   unsigned r,q,k;
   int 		   unsigned cum_lat_r,cum_lat_next, cum_lat;
   int 		   unsigned received_pkt_cnt_r,received_pkt_cnt_next, received_pkt_cnt;
   int 		   unsigned cycle_count;
   int 		   unsigned received_id;
   int 		   unsigned received_send_time;
   int 		   unsigned src;
   int 		   unsigned inj_pkt_cnt_r, inj_pkt_cnt_next, inj_pkt_cnt;
         
   int 		   unsigned ob_cum_lat_r,ob_cum_lat_next, ob_cum_lat;
   int 		   unsigned ob_received_pkt_cnt_r,ob_received_pkt_cnt_next,ob_received_pkt_cnt;
   pkts_in_flight  ob_pif_buffer [0:2**STORAGE-1];

   int 		   unsigned received_warmup_pkt_cnt_r,received_warmup_pkt_cnt_next,received_warmup_pkt_cnt;
   int 		   unsigned ob_received_warmup_pkt_cnt_r,ob_received_warmup_pkt_cnt_next,ob_received_warmup_pkt_cnt;   
   
   int 		   unsigned max_lat_r,max_lat_next,max_lat;
   int 		   unsigned min_lat_r,min_lat_next,min_lat;
   int 		   unsigned ob_max_lat_r,ob_max_lat_next,ob_max_lat;
   int 		   unsigned ob_min_lat_r,ob_min_lat_next,ob_min_lat;
   

   int 		   unsigned pkts_dropped_noc;
   int 		   unsigned pkts_dropped_obuffer;
   int 		   unsigned pkts_inflight_noc;
   int 		   unsigned pkts_inflight_obuffer;
   int 		   unsigned max_pkts_inflight_noc;

   int 		   unsigned end_sim_cnt;
   int 		   unsigned curr_avg_lat;

   int 		   unsigned pkt_size_r [0:N-1];
   int 		   unsigned pkt_size_next [0:N-1];
   int 		   unsigned cum_pkt_size_r, cum_pkt_size_next, cum_pkt_size;


   int 		   unsigned inj_rate_eq_cycle_count;
      
                
   initial begin
      cycle_count = 0;
      inj_rate_eq_cycle_count = 0;
      end_sim_cnt = 0;
      curr_avg_lat = 0;
   end

   always_ff @(posedge clk or posedge reset) begin
      cycle_count 		    = (reset) ? 0 : cycle_count + 1;
      cum_lat_r 		   <= (reset) ? 'd0 : cum_lat_next;
      received_pkt_cnt_r 	   <= (reset) ? 'd0 : received_pkt_cnt_next;
      ob_cum_lat_r 		   <= (reset) ? 'd0 : ob_cum_lat_next;
      ob_received_pkt_cnt_r 	   <= (reset) ? 'd0 : ob_received_pkt_cnt_next;
      inj_pkt_cnt_r 		   <= (reset) ? 'd0 : inj_pkt_cnt_next;
      max_lat_r 		   <= (reset) ? 'd0 : max_lat_next;
      min_lat_r 		   <= (reset) ? 'd0 : min_lat_next; 
      ob_max_lat_r 		   <= (reset) ? 'd0 : ob_max_lat_next;
      ob_min_lat_r 		   <= (reset) ? 'd0 : ob_min_lat_next;
      received_warmup_pkt_cnt_r    <= (reset) ? 'd0 : received_warmup_pkt_cnt_next;
      ob_received_warmup_pkt_cnt_r <= (reset) ? 'd0 : ob_received_warmup_pkt_cnt_next;

      cum_pkt_size_r 		   <= (reset) ? 'd0 : cum_pkt_size_next;

      if (reset) begin

	 inj_rate_eq_cycle_count = 0;
	 
      end
      else if (real'(INJECTION_RATE)/real'(10000) - real'(real'(inj_pkt_cnt_r)/real'(16))/real'(cycle_count) < 0.00001 || 
	  real '(real'(inj_pkt_cnt_r)/real'(16))/real'(cycle_count) >= real'(INJECTION_RATE)/real'(10000)) begin
	  
	 inj_rate_eq_cycle_count = inj_rate_eq_cycle_count + 1;
	 	 
      end
	  
      
      for (r=0;r<N;r++)
	pkt_size_r[r] <= (reset) ? 'd0 : pkt_size_next[r];
                        
      if (cycle_count%200 == 0 && cycle_count>WARMUP_CYCLES) begin
	 $display(" ********** STATISTICS ********** ");
	 $display("Cycle count                          = %d",cycle_count);
	 $display("# pkts injected                      = %d",inj_pkt_cnt_r);
	 $display("# pkts received at input of obuffer  = %d",received_pkt_cnt_r+received_warmup_pkt_cnt_r);
	 $display("# pkts received at output of obuffer = %d",ob_received_pkt_cnt_r+ob_received_warmup_pkt_cnt_r);
 	 $display("Pkt injection rate                   = %f",real'(real'(inj_pkt_cnt_r)/real'(16))/real'(cycle_count));
	 //$display("Avg pkt size                         = %f",real'(cum_pkt_size_r)/real'(ob_received_pkt_cnt+ob_received_warmup_pkt_cnt));
	 $display("Avg pkt latency                      = %f",real'(cum_lat_r)/real'(received_pkt_cnt_r));
	 $display("Min pkt latency                      = %d",min_lat_r);
	 $display("Max pkt latency                      = %d",max_lat_r);
	 $display("Avg full pkt latency                 = %f",real'(ob_cum_lat_r)/real'(ob_received_pkt_cnt_r));
	 $display("Min full pkt latency                 = %d",ob_min_lat_r);
	 $display("Max full pkt latency                 = %d",ob_max_lat_r);
	 $display("Packets dropped from MAC             = %d (%f)",drop_cnt_r,real'((real'(drop_cnt_r)/(real'(inj_pkt_cnt_r)+1))*real'(100)));
	 

	 if (/*(real'(INJECTION_RATE)/real'(10000) - real'(real'(inj_pkt_cnt_r)/real'(16))/real'(cycle_count) < 0.00001 || 
	     real '(real'(inj_pkt_cnt_r)/real'(16))/real'(cycle_count) >= real'(INJECTION_RATE)/real'(10000) || */
	     /*real'((real'(drop_cnt_r)/(real'(inj_pkt_cnt_r)+1))*real'(100)) > 1*/
	     inj_rate_eq_cycle_count > 50000 /*||
	     cycle_count > 400000*/ /*)
	     && cycle_count > 50000*/) begin
	    
	    if (curr_avg_lat > (cum_lat_r/received_pkt_cnt_r)) begin
	       if ((real'(curr_avg_lat) - (real'(cum_lat_r)/real'(received_pkt_cnt_r))) < END_SIM_THRESH)
		 end_sim_cnt++;
	       else begin
		  end_sim_cnt = 0;
		  curr_avg_lat = cum_lat_r/received_pkt_cnt_r;
	       end
	    end
	    else begin
	       if (((real'(cum_lat_r)/real'(received_pkt_cnt_r))-real'(curr_avg_lat)) < END_SIM_THRESH)
		 end_sim_cnt++;
	       else begin
		  end_sim_cnt = 0;
		  curr_avg_lat = cum_lat_r/received_pkt_cnt_r;
	       end
	    end // else: !if(curr_avg_lat > (cum_lat_r/received_pkt_cnt_r))

	 end
	 	 
      end

      if (/*cycle_count >= NUM_CYCLES*/end_sim_cnt == END_SIM_COUNT /*|| cycle_count > 500000*//*real'((real'(drop_cnt_r)/(real'(inj_pkt_cnt_r)+1))*real'(100)) > 1*/) begin
	 $display(" ********** FINAL STATISTICS ********** ");
	 $display("Cycle count                          = %d",cycle_count);
	 $display("# pkts injected                      = %d",inj_pkt_cnt_r);
	 $display("# pkts received at input of obuffer  = %d",received_pkt_cnt_r+received_warmup_pkt_cnt_r);

	 pkts_inflight_noc = 0;
	 max_pkts_inflight_noc = 0;
	 
	 for (k=0; k<2**STORAGE; k=k+1) begin
	 
	    if (pif_buffer[k].valid)
	      pkts_inflight_noc++;

	    if (pif_buffer[k].id > 0)
	      max_pkts_inflight_noc++;
	    
	 end
	 pkts_dropped_noc = inj_pkt_cnt_r-(received_pkt_cnt_r+received_warmup_pkt_cnt_r+pkts_inflight_noc);
	 	 
	 $display("# pkts in flight in NoC              = %d",pkts_inflight_noc);
	 $display("# pkts dropped in NoC                = %d",pkts_dropped_noc);

	 pkts_inflight_obuffer = 0;
	 for (k=0; k<2**STORAGE; k=k+1) begin
	    if (ob_pif_buffer[k].valid)
	      pkts_inflight_obuffer++;
	 end
	 pkts_dropped_obuffer = inj_pkt_cnt_r-(ob_received_pkt_cnt_r+ob_received_warmup_pkt_cnt_r+pkts_inflight_obuffer);
	 	 
	 $display("# pkts received at output of obuffer = %d",ob_received_pkt_cnt_r+ob_received_warmup_pkt_cnt_r);
	 $display("# pkts in flight in OBuffer          = %d",pkts_inflight_obuffer);
	 $display("# pkts dropped in OBuffer            = %d",pkts_dropped_obuffer);

	 $display("Pkt injection rate                   = %f",(real'(real'(inj_pkt_cnt_r)/real'(16))/real'(cycle_count)));
	 $display("Max pkts in flight in NoC            = %d", max_pkts_inflight_noc);
	 //$display("Avg pkt size                         = %f",real'(cum_pkt_size_r)/real'(ob_received_pkt_cnt+ob_received_warmup_pkt_cnt));
	 $display("Avg pkt latency                      = %f",real'(cum_lat_r)/real'(received_pkt_cnt_r));
	 $display("Min pkt latency                      = %d",min_lat_r);
	 $display("Max pkt latency                      = %d",max_lat_r);
	 
	 $display("Avg full pkt latency                 = %f",real'(ob_cum_lat_r)/real'(ob_received_pkt_cnt_r));
	 $display("Min full pkt latency                 = %d",ob_min_lat_r);
	 $display("Max full pkt latency                 = %d",ob_max_lat_r);
	 $display("Packets dropped from MAC             = %d",drop_cnt_r);
	 	 	 
	 $finish;
      end
   end
   
      
   always @(negedge clk) begin
      // Defaults
      received_pkt_cnt_next 	  = received_pkt_cnt_r;
      ob_received_pkt_cnt_next 	  = ob_received_pkt_cnt_r;
      cum_lat_next 		  = cum_lat_r;
      ob_cum_lat_next 		  = ob_cum_lat_r;
      inj_pkt_cnt_next 		  = inj_pkt_cnt_r;
                        
      inj_pkt_cnt 		  = inj_pkt_cnt_r;
      received_pkt_cnt 		  = received_pkt_cnt_r;
      ob_received_pkt_cnt 	  = ob_received_pkt_cnt_r;
      cum_lat 			  = cum_lat_r;
      ob_cum_lat 		  = ob_cum_lat_r;
      max_lat 			  = max_lat_r;
      min_lat 			  = min_lat_r;
      ob_max_lat 		  = ob_max_lat_r;
      ob_min_lat 		  = ob_min_lat_r;
      received_warmup_pkt_cnt 	  = received_warmup_pkt_cnt_r;
      ob_received_warmup_pkt_cnt  = ob_received_warmup_pkt_cnt_r;
      cum_pkt_size 		  = cum_pkt_size_r;
                                                
      for (q=0;q<N;q++) begin
	 pkt_size_next[q] = pkt_size_r[q];
	 
	 if (i_valid_avalon_in[q] && i_sop_avalon_in[q]) begin

	    inj_pkt_cnt++;

	    if (space_left[q] >= i_data_avalon_in[q][DATA_WIDTH-1-DEST_WIDTH-1-32-1 -: 8]) begin
	    
	       // before obuffer
	       for (r=0; r<2**STORAGE; r=r+1) begin
		  if (pif_buffer[r].valid == 1'b0) begin
		     pif_buffer[r].id = i_data_avalon_in[q][DATA_WIDTH-1-DEST_WIDTH-1 -: 32];
		     pif_buffer[r].send_time = cycle_count + 1;
		     pif_buffer[r].valid = 1'b1;
		     pif_buffer[r].src = q;
		     break;
		  end
	       end

	       // after obuffer
	       for (r=0; r<2**STORAGE; r=r+1) begin
		  if (ob_pif_buffer[r].valid == 1'b0) begin
		     ob_pif_buffer[r].id = i_data_avalon_in[q][DATA_WIDTH-1-DEST_WIDTH-1 -: 32];
		     ob_pif_buffer[r].send_time = cycle_count + 1;
		     ob_pif_buffer[r].valid = 1'b1;
		     ob_pif_buffer[r].src = q;
		     break;
		  end
	       end

	    end

	 end // if (i_valid_avalon_in[q])

	 
	 // *** Before OBUFFER ***
	 
	 if (valid_p2b[q] && data_p2b[q][PACKET_WIDTH-1] && data_p2b[q][PACKET_WIDTH-2]) begin

	    received_id = data_p2b[q][PACKET_WIDTH-13 -: 32];
	    received_send_time = 0;
	    
	    for (r=0; r<2**STORAGE; r=r+1) begin
	       
	       if (pif_buffer[r].valid == 1'b1 && pif_buffer[r].id == received_id) begin

		  received_send_time = pif_buffer[r].send_time;
		  pif_buffer[r].valid = 1'b0;
		  src = pif_buffer[r].src;
		  break;
		  
	       end

	    end // for (r=0; r<2**STORAGE; r=r+1)

	    if (cycle_count < WARMUP_CYCLES) begin
	       if (VERBOSE > 0)
		 $display("**WARMUP** Pkt %d head latency: %d (Cycle: %d, Sent: %d)",received_id,cycle_count-received_send_time,cycle_count,received_send_time);

	       received_warmup_pkt_cnt++;
	    end
	    else begin
	       if (VERBOSE>0)
		 $display("Pkt %d head latency: %d (Cycle: %d, Sent: %d). Received at node %d from node %d.",received_id,cycle_count-received_send_time,cycle_count,received_send_time,q,src);
	       
	       received_pkt_cnt++;
	       cum_lat += cycle_count-received_send_time;

	       if (max_lat < cycle_count-received_send_time)
		 max_lat = cycle_count-received_send_time;

	       if (min_lat == 0 || min_lat > cycle_count-received_send_time)
		 min_lat = cycle_count-received_send_time;

	       if (VERBOSE > 0)
		 $display("*** AVERAGE PACKET HEAD LATENCY = %d", cum_lat/received_pkt_cnt);
	    end

	 end // if (valid_p2b[q] && data_p2b[q][PACKET_WIDTH-1] && data_p2b[q][PACKET_WIDTH-2])

	 
	 // *** After OBUFFER ***

	 if (o_valid_avalon_out[q] && o_sop_avalon_out[q]) begin

	    received_id = o_data_avalon_out[q][DATA_WIDTH-1-DEST_WIDTH-1 -: 32];
	    received_send_time = 0;

	    for (r=0; r<2**STORAGE; r=r+1) begin
	       
	       if (ob_pif_buffer[r].valid == 1'b1 && ob_pif_buffer[r].id == received_id) begin

		  received_send_time = ob_pif_buffer[r].send_time;
		  ob_pif_buffer[r].valid = 1'b0;
		  src = ob_pif_buffer[r].src;
		  break;
		  
	       end

	    end // for (r=0; r<2**STORAGE; r=r+1)

	    if (cycle_count >= WARMUP_CYCLES) begin
	       if (VERBOSE > 0)
		 $display("Obuffer Pkt %d head latency: %d (Cycle: %d, Sent: %d). Received at node %d from node %d.",received_id,cycle_count-received_send_time,cycle_count,received_send_time,q,src);

	       if (ob_max_lat < cycle_count-received_send_time)
		 ob_max_lat = cycle_count-received_send_time;

	       if (ob_min_lat == 0 || min_lat > cycle_count-received_send_time)
		 ob_min_lat = cycle_count-received_send_time;
	       
	       ob_received_pkt_cnt++;
	       ob_cum_lat += cycle_count-received_send_time;

	       if (VERBOSE > 0)
		 $display("*** OBUFFER AVERAGE PACKET HEAD LATENCY = %d", ob_cum_lat/ob_received_pkt_cnt);
	    end // if (cycle_count >= WARMUP_CYCLES)
	    else
	      ob_received_warmup_pkt_cnt++;
	    	    
	 end // if (o_valid_avalon_out[q] && o_sop_avalon_out[q])
	 	 
	 if (o_valid_avalon_out[q]) begin
	    
	    if (o_sop_avalon_out[q])
	      pkt_size_next[q] = 1;
	    else if (o_eop_avalon_out[q]) begin
	       if (pkt_size_r[q] != 64) begin
		  $error("Received packet size not equal to 64.");
		  $finish;
	       end
	       //cum_pkt_size += pkt_size_r[q];
	    end
	    else
	      pkt_size_next[q] = pkt_size_r[q] + 1;
	    
	 end
	 

      end // for (q=0;q<N;q++)

      inj_pkt_cnt_next 		       = inj_pkt_cnt;
      received_pkt_cnt_next 	       = received_pkt_cnt;
      ob_received_pkt_cnt_next 	       = ob_received_pkt_cnt;
      cum_lat_next 		       = cum_lat;
      ob_cum_lat_next 		       = ob_cum_lat;
      max_lat_next 		       = max_lat;
      min_lat_next 		       = min_lat;
      ob_max_lat_next 		       = ob_max_lat;
      ob_min_lat_next 		       = ob_min_lat;
      received_warmup_pkt_cnt_next     = received_warmup_pkt_cnt;
      ob_received_warmup_pkt_cnt_next  = ob_received_warmup_pkt_cnt;
      cum_pkt_size_next 	       = cum_pkt_size;
                              
   end

   always_ff @(posedge clk or posedge reset) drop_cnt_r = (reset) ? 1'b0 : drop_cnt_next;

   int 				   a;
   
   always_comb begin
      
      drop_cnt = drop_cnt_r;

      for (a = 0; a<N; a++) begin

	 if (i_valid_avalon_in[a] && i_sop_avalon_in[a] &&
	     space_left[a] < i_data_avalon_in[a][DATA_WIDTH-1-DEST_WIDTH-1-32-1 -: 8]) begin

	    drop_cnt++;
	    	    
	 end
	 
      end
      
      drop_cnt_next = drop_cnt;
            
   end
   
   genvar 		   i;
   
   generate
      for (i=0;i<N;i++) begin:A

	 /* INGRESS PATH *****************************************************************/

	 always_ff @(posedge clk or posedge reset) drop_r[i] = (reset) ? 1'b0 : drop_next[i];

	 always_comb begin
	    drop_next[i] = drop_r[i];
	    
	    if (drop_r[i] == 1'b0) begin
	       
	       if (i_valid_avalon_in[i] && i_sop_avalon_in[i]) begin
		  if (space_left[i] < i_data_avalon_in[i][DATA_WIDTH-1-DEST_WIDTH-1-32-1 -: 8]) begin
		     drop_next[i] = 1'b1;
		     $display("DROP: Dropping packet at node %d (t=%t)",i,$time);
		  end
	       end

	    end
	    else begin

	       if (i_valid_avalon_in[i] && i_eop_avalon_in[i])
		 drop_next[i] = 1'b0;
	       
	    end // else: !if(drop_r[i] == 1'b0)

	    valid_in[i] = (drop_r[i] || drop_next[i]) ? 1'b0 : i_valid_avalon_in[i];
	    	    
	 end // always_comb


	 //assign valid_in[i] = (drop_r[i]) ? 1'b0 : i_valid_avalon_in[i];
	 	 
	 ibuffer #(.PACKET_WIDTH(PACKET_WIDTH),
		   .DATA_WIDTH(DATA_WIDTH),
		   .DEST_WIDTH(DEST_WIDTH),
		   .DEPTH(INPUT_DEPTH)) ibuffer (.clk(clk),
						 .reset(reset),
						 .i_valid(valid_in[i]),
						 .i_sop(i_sop_avalon_in[i]),
						 .i_eop(i_eop_avalon_in[i]),
						 .i_error(i_error_avalon_in[i]),
						 .i_empty(i_empty_avalon_in[i]),
						 .i_data(i_data_avalon_in[i]),
						 .o_ready(o_ready_avalon_in[i]),
						 .o_valid(valid_b2p[i]),
						 .o_data(data_b2p[i]),
						 .o_dest(dest_b2p[i]),
						 .i_ready(ready_bin2p[i]),
						 .o_space_left(space_left[i]));

	 switch_packetizer #(.ADDRESS_WIDTH(DEST_WIDTH),
			     .VC_ADDRESS_WIDTH($clog2(NUM_VC)),
			     .WIDTH_IN(PACKET_WIDTH),
			     .WIDTH_OUT(OUT_WIDTH),
			     .ASSIGNED_VC(ASSIGNED_VC[i])) packetizer (.i_data_in(data_b2p[i]),
								.i_valid_in(valid_b2p[i]),
								.i_dest_in(dest_b2p[i]),
								.i_ready_out(ready_bin2p[i]),
								.o_data_out(o_data_to_noc[i]),
								.o_valid_out(o_valid_to_noc[i]),
								.o_ready_in(i_ready_to_noc[i]));

	 /********************************************************************************/

	 /* EGRESS PATH ******************************************************************/
							 
	 obuffer #(.PACKET_WIDTH(PACKET_WIDTH),
		   .DATA_WIDTH(DATA_WIDTH),
		   .DEPTH(OUTPUT_DEPTH)) obuffer (.clk(clk),
						     .reset(reset),
						     .i_valid(valid_p2b[i]),
						     .i_data(data_p2b[i]),
						     .o_ready(ready_bout2p[i]),
						     .o_valid(o_valid_avalon_out[i]),
						     .o_sop(o_sop_avalon_out[i]),
						     .o_eop(o_eop_avalon_out[i]),
						     .o_data(o_data_avalon_out[i]),
						     .o_empty(o_empty_avalon_out[i]),
						     .o_error(o_error_avalon_out[i]),
						     .i_ready(i_ready_avalon_out[i]));
							 
	 switch_depacketizer #(.WIDTH_IN(OUT_WIDTH),
			       .WIDTH_OUT(PACKET_WIDTH),
			       .VC_ADDRESS_WIDTH($clog2(NUM_VC)),
			       .ADDRESS_WIDTH(DEST_WIDTH)) depacketizer (.clk(clk),
									 .reset(reset),
									 .i_data_in(i_data_from_noc[i]),
									 .i_valid_in(i_valid_from_noc[i]),
									 .i_ready_out(o_ready_from_noc[i]),
									 .o_data_out(data_p2b[i]),
									 .o_valid_out(valid_p2b[i]),
									 .o_ready_in(ready_bout2p[i]));
	 
	 /********************************************************************************/
	 
      end // block: A
   endgenerate
   

endmodule
