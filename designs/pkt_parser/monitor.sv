module monitor
  #(
    parameter DATA_WIDTH = 512,
    parameter NOC_RADIX = 16,
    parameter NUM_SRC = 4,
    parameter BIDIRECTIONAL = 0
    )
   (
    
    input clk,
    input reset,

    avalonST.sink in_injected [NUM_SRC],
    avalonST.sink in_received [NUM_SRC]

    );
   
   localparam ADDRESS_WIDTH = $clog2(NOC_RADIX);

   import global_package::*;
   
   int unsigned i,j;
   int unsigned beat_cnt [0:NUM_SRC-1];
   int unsigned ipv6_cnt [0:NUM_SRC-1];
   int unsigned payload_start [0:NUM_SRC-1];
   logic [27:0] pkt_id;
   logic [27:0] pkt_id_reversed;
   logic [27:0] max_pkt_id;
   logic [3:0] 	src_node [0:NUM_SRC-1];
   logic [6:0] 	header_offset;
      
   logic [27:0] id_cnt_rec [0:NUM_SRC-1];

   mod_t ipv6_m;
   assign ipv6_m = ipv6_mod;
   
   initial begin

      for (j=0;j<NUM_SRC;j++) begin
	 id_cnt_rec[j] = 0;
	 payload_start[j] = 1;
	 ipv6_cnt[j] = 0;
      end
      
   end

   genvar s;
   
   generate
      
      for (s=0; s<NUM_SRC; s++) begin : A
	 
	 assign in_received[s].ready = 1'b1;
   
	 always_ff @(negedge clk) begin

	    if (!reset) begin
		  
		  if (in_received[s].valid) begin

		     if (beat_cnt[s] > 0) begin

			if (beat_cnt[s] > payload_start[s]) begin
			   
			   // Check validity of payload data beats
			   if (in_received[s].data[DATA_WIDTH-1 -: 4] != (beat_cnt[s][3:0]-(payload_start[s][3:0]+1)))
			     $error("Missed payload beat %.2d in pkt ID %.4d from src ID %.2d at dest ID %.2d. Instead received payload beat %.2d.",(beat_cnt[s][3:0]-(payload_start[s][3:0]+1)),pkt_id,src_node[s],s,in_received[s].data[DATA_WIDTH-1 -: 4]);
			   
			end
			
			beat_cnt[s]++;


			if (in_received[s].eop) begin
			   
			   beat_cnt[s] = 0;
			   
			end // if (in_received[s].eop)
						
		     end // if (beat_cnt > 0)
		     else if (in_received[s].sop) begin

			if (in_received[s].eop) begin

			   $display("Received reply message at node %.2d",s);
			   $display("%h",in_received[s].data);
			   			   
			end
			else begin

			   if (in_received[s].data[DATA_WIDTH-1-1-32-7 -: 3] == ipv6_m)
			     ipv6_cnt[s]++;
			   			   
			   beat_cnt[s]++;
			   src_node[s] = in_received[s].data[DATA_WIDTH-2 -: 4];
			   pkt_id_reversed = in_received[s].data[DATA_WIDTH-2-4 -: 28];
			   for (i=0;i<28;i++)
			     pkt_id[i] = pkt_id_reversed[27-i];
			   
			   if (pkt_id > max_pkt_id)
			     max_pkt_id = pkt_id;

			   //if (id_cnt_rec[s] != pkt_id)
			   //  $display("WARNING: Received ID %.4d, expecting ID %.4d (Node %.2d).",pkt_id,id_cnt_rec[s],s);

			   id_cnt_rec[s]++;

			   header_offset = in_received[s].data[DATA_WIDTH-1-1-32 -: 7];

			   if (header_offset*8 > 512) payload_start[s] = 2;
			   else payload_start[s] = 1;
			   
			   //$display("N%.1d - ID:%.4d",src_node,pkt_id);

			end // else: !if(in_received[s].eop)
						
		     end // if (in_received.sop)
		     
		  end // if (in_received.valid)
	       
	    end // if (!reset)
	    
	 end // always_ff @

      end // block: A

   endgenerate

   
   import global_package::*;
   
   typedef struct packed {
      logic 	  valid;
      logic 	  sop;
      logic 	  eop;
      logic 	  error;
      logic [5:0] empty;
      logic [511:0] data;
   } avalonst_t;

   avalonst_t injected_pkts [NUM_SRC];
   avalonst_t received_pkts [NUM_SRC];

   generate

      for (s=0; s<NUM_SRC;s++) begin : B

	 assign injected_pkts[s].valid = in_injected[s].valid;
	 assign injected_pkts[s].sop = in_injected[s].sop;
	 assign injected_pkts[s].eop = in_injected[s].eop;
	 assign injected_pkts[s].error = in_injected[s].error;
	 assign injected_pkts[s].empty = in_injected[s].empty;
	 assign injected_pkts[s].data = in_injected[s].data;

	 assign received_pkts[s].valid = in_received[s].valid;
	 assign received_pkts[s].sop = in_received[s].sop;
	 assign received_pkts[s].eop = in_received[s].eop;
	 assign received_pkts[s].error = in_received[s].error;
	 assign received_pkts[s].empty = in_received[s].empty;
	 assign received_pkts[s].data = in_received[s].data;

      end

   endgenerate
      
   localparam STORAGE = 12;
   
   typedef struct {
      bit 	   valid;
      logic [31:0] id;
      int 	   unsigned send_time;
      int 	   unsigned src;
   } pkts_in_flight;

   pkts_in_flight pif_buffer [0:2**STORAGE-1];

   int 		   unsigned q,r,k,v;
   int 		   unsigned cycle_count;
   int 		   unsigned cum_lat_r,cum_lat_next, cum_lat;
   int 		   unsigned received_pkt_cnt_r,received_pkt_cnt_next, received_pkt_cnt;
   int 		   unsigned received_id;
   int 		   unsigned received_send_time;
   int 		   unsigned src;
   int 		   unsigned inj_pkt_cnt_r, inj_pkt_cnt_next, inj_pkt_cnt;
   int 		   unsigned max_lat_r,max_lat_next,max_lat;
   int 		   unsigned min_lat_r,min_lat_next,min_lat;
   int 		   unsigned ipv6_tot_cnt;
   
   logic [27:0]    id_cnt [0:NUM_SRC-1];
   logic [27:0]    id_cnt_reversed;

   logic [3:0] 	   id_node;
         
   
   initial begin
      
      cycle_count = 0;
      for (q=0;q<NUM_SRC;q++)
	id_cnt[q] = 0;

      id_node = 0;
            
   end

   always_ff @(posedge clk) begin
      cycle_count 		    = (reset) ? 0 : cycle_count + 1;
      cum_lat_r 		   <= (reset) ? 'd0 : cum_lat_next;
      received_pkt_cnt_r 	   <= (reset) ? 'd0 : received_pkt_cnt_next;
      inj_pkt_cnt_r 		   <= (reset) ? 'd0 : inj_pkt_cnt_next;
      max_lat_r 		   <= (reset) ? 'd0 : max_lat_next;
      min_lat_r 		   <= (reset) ? 'd0 : min_lat_next; 


      if (cycle_count%50 == 0 && cycle_count > 0) begin

	 ipv6_tot_cnt = 0;
	 for (v=0;v<NUM_SRC;v++) begin
	    ipv6_tot_cnt += ipv6_cnt[v];
	 end
	 	 	   
	 $display(" ********** STATISTICS ********** ");
	 $display("Cycle count                          = %d",cycle_count);
	 $display("# pkts injected                      = %d",inj_pkt_cnt_r);
	 $display("# pkts received                      = %d",received_pkt_cnt_r);
	 $display("Pkt injection rate                   = %f",real'(real'(inj_pkt_cnt_r)/real'(NUM_SRC))/real'(cycle_count));
	 $display("Avg pkt latency                      = %f",real'(cum_lat_r)/real'(received_pkt_cnt_r));
	 $display("Min pkt latency                      = %d",min_lat_r);
	 $display("Max pkt latency                      = %d",max_lat_r);
	 $display("Prct of received pkts ipv6           = %f",real'(ipv6_tot_cnt)/real'(received_pkt_cnt));
	 
      end
      
   end // always_ff @

   always @(negedge clk) begin
      // Defaults
      received_pkt_cnt_next  = received_pkt_cnt_r;
      cum_lat_next 	     = cum_lat_r;
      inj_pkt_cnt_next 	     = inj_pkt_cnt_r;

      inj_pkt_cnt 	     = inj_pkt_cnt_r;
      received_pkt_cnt 	     = received_pkt_cnt_r;
      cum_lat 		     = cum_lat_r;
      max_lat 		     = max_lat_r;
      min_lat 		     = min_lat_r;

      for (q=0; q<NUM_SRC; q++) begin

	 if (injected_pkts[q].valid && injected_pkts[q].sop) begin

	    inj_pkt_cnt++;
	    
	    for (k=0;k<28;k++)
	      id_cnt_reversed[k] = id_cnt[q][27-k];

	    id_cnt[q]++;

	    if (BIDIRECTIONAL) begin
	       
	       if (q < NUM_SRC/2)
		 id_node = q[3:0];
	       else
		 id_node = q[3:0] - (NUM_SRC/2) + 12;
	    
	    end
	    else
	      id_node = q[3:0];
	       
	    for (r=0; r<2**STORAGE; r=r+1) begin
	       if (pif_buffer[r].valid == 1'b0) begin
		  pif_buffer[r].id = {id_node,id_cnt_reversed};
		  pif_buffer[r].send_time = cycle_count + 1;
		  pif_buffer[r].valid = 1'b1;
		  pif_buffer[r].src = q;
		  break;
	       end
	    end
	    
	 end // if (injected_pkts[q].valid && injected_pkts[q].sop)

	 
	 if (received_pkts[q].valid && received_pkts[q].sop && !received_pkts[q].eop) begin

	    received_id = received_pkts[q].data[DATA_WIDTH-2 -: 32];
	    received_send_time = 0;

	    for (r=0; r<2**STORAGE; r=r+1) begin
	       
	       if (pif_buffer[r].valid == 1'b1 && pif_buffer[r].id == received_id) begin

		  received_send_time = pif_buffer[r].send_time;
		  pif_buffer[r].valid = 1'b0;
		  src = pif_buffer[r].src;

		  received_pkt_cnt++;
		  cum_lat += cycle_count-received_send_time;

		  if (max_lat < cycle_count-received_send_time)
		    max_lat = cycle_count-received_send_time;

		  if (min_lat == 0 || min_lat > cycle_count-received_send_time)
		    min_lat = cycle_count-received_send_time;

		  break;
		  
	       end

	    end // for (r=0; r<2**STORAGE; r=r+1)
	    	    
	 end

      end

      inj_pkt_cnt_next 	     = inj_pkt_cnt;
      received_pkt_cnt_next  = received_pkt_cnt;
      cum_lat_next 	     = cum_lat;
      max_lat_next 	     = max_lat;
      min_lat_next 	     = min_lat;
      
   end
   
endmodule
