module ipv4_512
  #(
    parameter NOC_RADIX = 16,
    parameter NUM_VC = 2,
    parameter NODE_ID = 4,
    parameter NUM_SRC = 4,
    parameter [3:0] DEST [0:NUM_SRC-1] = '{4'd12,4'd13,4'd14,4'd15}
    )
   (
    input clk,
    input reset,
    
    avalonST.sink in,
    avalonST.src out,

    output logic [$clog2(NUM_VC)-1:0] o_vc_id, // Virtual Channel ID (for priority scheme)
    output logic [$clog2(NOC_RADIX)-1:0]  o_noc_dst

    );


   import global_package::*;
      
   typedef struct packed {
      logic 	  valid;
      logic 	  sop;
      logic 	  eop;
      logic 	  error;
      logic [5:0] empty;
      logic [511:0] data;
   } avalonst_t;

   assign in.ready = out.ready;

   logic ready_r;
   always_ff @(posedge clk) ready_r <= out.ready;
   
   // Four cycles to calculate checksum
   avalonst_t first_r, first_next;
   avalonst_t second_r, second_next;
   avalonst_t third_r, third_next;
   avalonst_t fourth_r, fourth_next;
   avalonst_t fifth_r, fifth_next;
   
   always_ff @(posedge clk) begin

      //if (in.valid && in.sop)
	//$display("N%.2d: IPv4 received packet",NODE_ID);
            
      first_r.valid <= (reset) ? 1'b0 : first_next.valid;
      first_r.sop   <= (reset) ? 1'b0 : first_next.sop;
      first_r.eop   <= (reset) ? 1'b0 : first_next.eop;
      first_r.error <= (reset) ? 1'b0 : first_next.error;
      first_r.empty <= (reset) ? 'b0  : first_next.empty;
      first_r.data  <= (reset) ? 'b0  : first_next.data;

      second_r.valid <= (reset) ? 1'b0 : second_next.valid;
      second_r.sop   <= (reset) ? 1'b0 : second_next.sop;
      second_r.eop   <= (reset) ? 1'b0 : second_next.eop;
      second_r.error <= (reset) ? 1'b0 : second_next.error;
      second_r.empty <= (reset) ? 'b0  : second_next.empty;
      second_r.data  <= (reset) ? 'b0  : second_next.data;

      third_r.valid <= (reset) ? 1'b0 : third_next.valid;
      third_r.sop   <= (reset) ? 1'b0 : third_next.sop;
      third_r.eop   <= (reset) ? 1'b0 : third_next.eop;
      third_r.error <= (reset) ? 1'b0 : third_next.error;
      third_r.empty <= (reset) ? 'b0  : third_next.empty;
      third_r.data  <= (reset) ? 'b0  : third_next.data;

      fourth_r.valid <= (reset) ? 1'b0 : fourth_next.valid;
      fourth_r.sop   <= (reset) ? 1'b0 : fourth_next.sop;
      fourth_r.eop   <= (reset) ? 1'b0 : fourth_next.eop;
      fourth_r.error <= (reset) ? 1'b0 : fourth_next.error;
      fourth_r.empty <= (reset) ? 'b0  : fourth_next.empty;
      fourth_r.data  <= (reset) ? 'b0  : fourth_next.data;

      fifth_r.valid <= (reset) ? 1'b0 : fifth_next.valid;
      fifth_r.sop   <= (reset) ? 1'b0 : fifth_next.sop;
      fifth_r.eop   <= (reset) ? 1'b0 : fifth_next.eop;
      fifth_r.error <= (reset) ? 1'b0 : fifth_next.error;
      fifth_r.empty <= (reset) ? 'b0  : fifth_next.empty;
      fifth_r.data  <= (reset) ? 'b0  : fifth_next.data;
   end
   
   always_comb begin
      // Defaults
      //first_next   = first_r;
      //second_next  = second_r;
      third_next   = third_r;
      fourth_next  = fourth_r;
      fifth_next   = fifth_r;
                             
/* -----\/----- EXCLUDED -----\/-----
      if (out.ready) begin
	 first_next.valid  = in.valid;
	 first_next.sop    = in.sop;
	 first_next.eop    = in.eop;
	 first_next.error  = in.error;
	 first_next.empty  = in.empty;
	 first_next.data   = in.data;
      end // if (out.ready && in.valid)
 -----/\----- EXCLUDED -----/\----- */

      //if (out.ready)
      	//second_next 	   = first_r;

      if (ready_r)
	 third_next 	   = second_r;

      if (ready_r)
	fourth_next = third_r;

      if (ready_r)
	fifth_next = fourth_r;
            
   end // always_comb


   mod_map_t dst_mod;
   logic [7:0] protocol;
   logic [7:0] ttl;
   logic [31:0] src_addr;
   logic [31:0] dst_addr;
   logic 	ttl_drop_r, ttl_drop_next; // drop flag based on TTL
   logic [3:0] 	src_id;
   always_ff @(posedge clk) ttl_drop_r <= (reset) ? 1'b0 : ttl_drop_next;

   logic [6:0] header_offset_r, header_offset_next;
   always_ff @(posedge clk) header_offset_r <= (reset) ? 'b0 : header_offset_next;

   logic [$clog2(NOC_RADIX)-1:0] out_port_r, out_port_next;
   always_ff @(posedge clk) out_port_r <= (reset) ? 'b0 : out_port_next;

   enum {SOP,HEADER,BODY} fsm_r, fsm_next;
   always_ff @(posedge clk) fsm_r <= (reset) ? SOP : fsm_next;
   
   // Logic for decrementing TTL and determining protocol
   always_comb begin
      // Defaults
      first_next 	  = first_r;
      second_next 	  = second_r;
      fsm_next 		  = fsm_r;
      ttl_drop_next 	  = ttl_drop_r;
      header_offset_next  = header_offset_r;
      out_port_next 	  = out_port_r;
      ttl 		  = 'b0;
      protocol 		  = 'b0;
      dst_mod 		  = ipv4;
      dst_addr 		  = 'b0;
      src_addr 		  = 'b0;   
      src_id = 'b0;   

      if (ready_r) begin
	 
	 first_next.valid  = in.valid;
	 first_next.sop    = in.sop;
	 first_next.eop    = in.eop;
	 first_next.error  = in.error;
	 first_next.empty  = in.empty;
	 first_next.data   = in.data;

	 second_next = first_r;
	 
	 case (fsm_r)

	   SOP:
	     // SOP: Internal header
	     if (in.valid && in.sop) begin
		src_id = in.data[511-1 -: 4];
		if (src_id == 4'd0)
		  out_port_next = DEST[0];
		else if (src_id == 4'd1)
		  out_port_next = DEST[1];
		else if (src_id == 4'd2)
		  out_port_next = DEST[2];
		else if (src_id == 4'd3)
		  out_port_next = DEST[3];
		
		header_offset_next = in.data[511-1-32 -: 7];
		// Update offset for 20 byte IPv4 header
		first_next.data[511-1-32 -: 7] = header_offset_next + 7'd20; 
		fsm_next = HEADER;
	     end

	   HEADER: 
	     if (in.valid) begin
		ttl = in.data[511-(header_offset_r*8)-64 -: 8];
		first_next.data[511-(header_offset_r*8)-64 -: 8] = ttl - 8'd1;
		
		if (ttl - 8'd1 == 0) begin
		   ttl_drop_next = 1'b1;
		   $display("WARNING: IPv4 to drop packet with TTL=0 at node %.2d (time=%.1t)",NODE_ID,$time);
		end
		else begin
		   ttl_drop_next = 1'b0;
		end
		
		protocol = in.data[511-(header_offset_r*8)-64-8 -: 8];

/* -----\/----- EXCLUDED -----\/-----
		if (protocol == 8'h06) begin
		   // TCP
		   dst_mod = tcp;
		   out_port_next = dst_mod;
		end
		else if (protocol == 8'h11) begin
		   // UDP
		   dst_mod = udp;
		   out_port_next = dst_mod;
		end
 -----/\----- EXCLUDED -----/\----- */

		src_addr = in.data[511-(header_offset_r*8)-64 -: 32];
		dst_addr = in.data[511-(header_offset_r*8)-96 -: 32];
		second_next.data[511-1-32-7-3-16 -: 32] = src_addr; // place src ip addr in header
		second_next.data[511-1-32-7-3-16-32 -: 32] = dst_addr; // place dst ip addr in header
				
		if (in.eop)
		  fsm_next = SOP;
		else
		  fsm_next = BODY;
	     end
	   
	   BODY: 
	     if (in.valid && in.eop) begin
		fsm_next = SOP;
	     end

	   default: begin
	      fsm_next = SOP;
	   end

	 endcase // case (fsm_r)

      end
           
   end // always_comb


   // --------------- CHECKSUM COMPUTE LOGIC --------------------

   logic [19:0] s01_r, s23_r, s45_r, s67_r, s89_r, s89p1_r, s89p2_r;
   logic [19:0] s0123_r,s4567_r;
   logic [19:0] s01234567_r;
   logic [19:0] checksum_r, checksum_next;
   logic [7:0] 	beat_cnt_r, beat_cnt_next;

   always_ff @(posedge clk) beat_cnt_r <= (reset) ? 'b1 : beat_cnt_next;

   always_comb begin
      beat_cnt_next = beat_cnt_r;
      
      if (beat_cnt_r == 0) begin

	 if (in.valid && !in.sop)
	   beat_cnt_next = beat_cnt_r + 1;

      end
      else begin

	 if (in.valid && in.sop && in.ready)
	   beat_cnt_next = 0;
	 else
	   beat_cnt_next = beat_cnt_r + 1;

      end
      
   end
   
   always_ff @(posedge clk) begin

      s01_r <= (reset || in.sop || !in.valid) ? 'b0 : 
	      in.data[511-(header_offset_r*8) -: 16] +
	      in.data[511-(header_offset_r*8)-16 -: 16];

      s23_r <= (reset || in.sop || !in.valid) ? 'b0 : 
	      in.data[511-(header_offset_r*8)-32 -: 16] +
	      in.data[511-(header_offset_r*8)-48 -: 16];

      s45_r <= (reset || in.sop || !in.valid) ? 'b0 : 
	      in.data[511-(header_offset_r*8)-64 -: 16] +
	      in.data[511-(header_offset_r*8)-80 -: 16];

      s67_r <= (reset || in.sop || !in.valid) ? 'b0 : 
	      in.data[511-(header_offset_r*8)-96 -: 16] +
	      in.data[511-(header_offset_r*8)-112 -: 16];
      
      s89_r <= (reset || in.sop || !in.valid) ? 'b0 : 
	      in.data[511-(header_offset_r*8)-128 -: 16] +
	      in.data[511-(header_offset_r*8)-144 -: 16];

      s0123_r <= (reset) ? 'b0 : s01_r + s23_r;

      s4567_r <= (reset) ? 'b0 : s45_r + s67_r;

      s89p1_r <= (reset) ? 'b0 : s89_r;
      
      s01234567_r <= (reset) ? 'b0 : s0123_r + s4567_r;

      s89p2_r <= (reset) ? 'b0 : s89p1_r;
      
      checksum_r <= (reset) ? 'b0 : checksum_next;
      
   end // always_ff @

   always_comb begin
      checksum_next = checksum_r;
            
      if (beat_cnt_r == 3) begin
	 checksum_next = s01234567_r + s89p2_r;
	 checksum_next[15:0] = {12'b0,checksum_next[19:16]} + checksum_next[15:0];
	 checksum_next [19:16] = 4'b0;
      end
      
   end

   logic checksum_drop_r, checksum_drop_next;
   always_ff @(posedge clk) checksum_drop_r <= (reset) ? 1'b0 : checksum_drop_next;

   logic ttl_drop_flag_r, ttl_drop_flag_next;
   always_ff @(posedge clk) ttl_drop_flag_r <= (reset) ? 1'b0 : ttl_drop_flag_next;
   
   always_comb begin
      // Default
      checksum_drop_next = checksum_drop_r;
      ttl_drop_flag_next = ttl_drop_flag_r;
            
      if (fifth_r.sop) begin

	 if (checksum_r[15:0] == 16'hFFFF)
	   checksum_drop_next = 1'b0;
	 else begin
	    checksum_drop_next = 1'b1;
	    $display("WARNING: IPv4 to drop packet with bad checksum at node %.2d (time=%.1t)",NODE_ID,$time);
	 end

	 	 
      end

      if (fourth_r.valid && fourth_r.sop) begin

	 ttl_drop_flag_next = ttl_drop_r;
	 
      end
	
   end
   
   // -----------------------------------------------------------
   
   
   // Drop or send packet?
   always_comb begin

      if (ready_r && !ttl_drop_flag_r /*&& !checksum_drop_r && !checksum_drop_next*/) begin
	 // Send packet
	 out.valid  = fifth_r.valid;
	 out.sop    = fifth_r.sop;
	 out.eop    = fifth_r.eop;
	 out.error  = fifth_r.error;
	 out.empty  = fifth_r.empty;
	 out.data   = fifth_r.data;
	 o_noc_dst  = out_port_r;
	 o_vc_id    = 0;
      end
      else begin
	 out.valid  = 1'b0;
	 out.sop    = 1'b0;
	 out.eop    = 1'b0;
	 out.error  = 1'b0;
	 out.empty  = 'b0;
	 out.data   = 'b0;
	 o_noc_dst  = 'b0;
	 o_vc_id    = 0;
      end

   end // always_comb

   
endmodule
