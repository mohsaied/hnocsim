module ipv6_512
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

   avalonst_t first_r, first_next;
   avalonst_t second_r, second_next;

   always_ff @(posedge clk) begin
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
   end

/* -----\/----- EXCLUDED -----\/-----
   always_comb begin
      // Defaults
      second_next  = second_r;

      if (out.ready)
      	second_next 	   = first_r;

   end // always_comb
 -----/\----- EXCLUDED -----/\----- */
   
   mod_map_t dst_mod;
   logic [7:0] protocol;
   logic [7:0] ttl;
   logic [127:0] src_addr;
   logic [127:0] dst_addr;
   logic       ttl_drop_r, ttl_drop_next; // drop flag based on TTL
   logic [3:0] 	src_id;
   always_ff @(posedge clk) ttl_drop_r <= (reset) ? 1'b0 : ttl_drop_next;

   logic [6:0] header_offset_r, header_offset_next;
   always_ff @(posedge clk) header_offset_r <= (reset) ? 'b0 : header_offset_next;

   logic [$clog2(NOC_RADIX)-1:0] out_port_r, out_port_next;
   always_ff @(posedge clk) out_port_r <= (reset) ? 'b0 : out_port_next;

   enum {SOP,HEADER,BODY} fsm_r, fsm_next;
   always_ff @(posedge clk) fsm_r <= (reset) ? SOP : fsm_next;

   logic ready_r;
   always_ff @(posedge clk) ready_r <= out.ready;

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

	 second_next 	   = first_r;

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
		// Update offset for 40 byte IPv6 header
		first_next.data[511-1-32 -: 7] = header_offset_next + 7'd40; 
		fsm_next = HEADER;
	     end

	   HEADER: 
	     if (in.valid) begin
		ttl = in.data[511-(header_offset_r*8)-56 -: 8];
		first_next.data[511-(header_offset_r*8)-56 -: 8] = ttl - 8'd1;
		
		if (ttl - 8'd1 == 0) begin
		   ttl_drop_next = 1'b1;
		   $display("WARNING: IPv6 to drop packet with TTL=0 at node %.2d (time=%.1t)",NODE_ID,$time);
		end 
		else
		  ttl_drop_next = 1'b0;
		
		protocol = in.data[511-(header_offset_r*8)-48-8 -: 8];

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

		src_addr = in.data[511-(header_offset_r*8)-64 -: 128];
		dst_addr = in.data[511-(header_offset_r*8)-64-128 -: 128];
		second_next.data[511-1-32-7-3-16 -: 128] = src_addr; // place src ip addr in header
		second_next.data[511-1-32-7-3-16-128 -: 128] = dst_addr; // place dst ip addr in header
		
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

   // Drop or send packet?
   always_comb begin

      if (ready_r && !ttl_drop_r) begin
	 // Send packet
	 out.valid  = second_r.valid;
	 out.sop    = second_r.sop;
	 out.eop    = second_r.eop;
	 out.error  = second_r.error;
	 out.empty  = second_r.empty;
	 out.data   = second_r.data;
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
