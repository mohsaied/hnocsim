module tcp512
   #(
     parameter NOC_RADIX = 16,
     parameter NUM_VC = 2,
     parameter NUM_SRC = 4,
     parameter [3:0] DEST [0:NUM_SRC-1]  = '{4'd12,4'd13,4'd14,4'd15}
    )
   (
    input 				 clk,
    input 				 reset,
					 
    avalonST.sink in,
    avalonST.src out,

    avalonST.src out_reply,
    
    output logic [$clog2(NUM_VC)-1:0] 	 o_vc_id, // Virtual Channel ID (for priority scheme)
    output logic [$clog2(NOC_RADIX)-1:0] o_noc_dst

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

   //assign in.ready = out.ready;
   
   localparam FIFO_DEPTH = 8;

   avalonst_t 		  reply_fifo_out; 
   avalonst_t 		  reply_fifo_in,reply_fifo_in_r;
   logic 			  reply_fifo_empty;
   logic 			  reply_fifo_full;
   logic 			  reply_fifo_wrreq,reply_fifo_wrreq_r;
   logic 			  reply_fifo_rdreq;
   logic [$clog2(FIFO_DEPTH)-1:0] reply_fifo_usedw;
   
   // Fifo to store reply packets
   fifo_emptyw #(.DEPTH(FIFO_DEPTH),
		 .WIDTH($bits(avalonst_t))) reply_fifo (.clock(clk),
							.sclr(reset),
							.rdreq(reply_fifo_rdreq),
							.wrreq(reply_fifo_wrreq_r),
							.full(reply_fifo_full),
							.empty(reply_fifo_empty),
							.data(reply_fifo_in_r),
							.q(reply_fifo_out),
							.usedw(reply_fifo_usedw));

   always_ff @(posedge clk) reply_fifo_in_r <= reply_fifo_in;
   always_ff @(posedge clk) reply_fifo_wrreq_r <= reply_fifo_wrreq;
      
   logic reply_fifo_empty_r;
   always_ff @(posedge clk) reply_fifo_empty_r <= (reset) ? 1'b0 : reply_fifo_empty;
      
   always_comb begin

      reply_fifo_rdreq = out_reply.ready && !reply_fifo_empty;

      if (!reply_fifo_empty_r) begin

	 out_reply.valid  = reply_fifo_out.valid;
	 out_reply.sop 	  = reply_fifo_out.sop;
	 out_reply.eop 	  = reply_fifo_out.eop;
	 out_reply.error  = reply_fifo_out.error;
	 out_reply.empty  = reply_fifo_out.empty;
	 out_reply.data   = reply_fifo_out.data;

      end
      else begin

	 out_reply.valid  = 1'b0;
	 out_reply.sop 	  = 1'b0;
	 out_reply.eop 	  = 1'b0;
	 out_reply.error  = 1'b0;
	 out_reply.empty  = 'b0;
	 out_reply.data   = 'b0;
	 
      end

   end
   
   
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
   
   
   //mod_map_t dst_mod;
   logic [15:0] dst_port;
   logic 	syn_flag;
   logic 	ack_flag;
   logic 	fin_flag;
   logic [3:0] 	src_id;
   
   logic [31:0] seq_num_next,seq_num_r;
   always_ff @(posedge clk) seq_num_r <= (reset) ? 'b0 : seq_num_next;
         
   logic [31:0] ack_cnt_r, ack_cnt_next;
   always_ff @(posedge clk) ack_cnt_r <= (reset) ? 'b0 : ack_cnt_next;
   
   logic [6:0] header_offset_r, header_offset_next;
   always_ff @(posedge clk) header_offset_r <= (reset) ? 'b0 : header_offset_next;

   logic [127:0] src_addr_r, src_addr_next;
   always_ff @(posedge clk) src_addr_r <= (reset) ? 'b0 : src_addr_next;
   
   logic [127:0] dst_addr_r, dst_addr_next;
   always_ff @(posedge clk) dst_addr_r <= (reset) ? 'b0 : dst_addr_next;

   logic [15:0]  ethtype_r,ethtype_next;
   always_ff @(posedge clk) ethtype_r <= (reset)  ? 'b0 : ethtype_next;

   logic 	 ready_r;
   always_ff @(posedge clk) ready_r <= out.ready;
         
   logic [$clog2(NOC_RADIX)-1:0] out_port_r, out_port_next;
   always_ff @(posedge clk) out_port_r <= (reset) ? 'b0 : out_port_next;

   enum {SOP,HEADER1,HEADER2,BODY} fsm_r, fsm_next;
   always_ff @(posedge clk) fsm_r <= (reset) ? SOP : fsm_next;

   always_comb begin
      // Defaults
      in.ready 		   = out.ready && (FIFO_DEPTH - reply_fifo_usedw > 1);
      first_next 	   = first_r;
      second_next 	   = second_r;
      fsm_next 		   = fsm_r;
      header_offset_next   = header_offset_r;
      out_port_next        = out_port_r;
      ack_cnt_next 	   = ack_cnt_r;
      src_addr_next 	   = src_addr_r;
      dst_addr_next 	   = dst_addr_r;
      ethtype_next 	   = ethtype_r;
      seq_num_next 	   = seq_num_r;
      dst_port 		   = 'b0;
      seq_num_next 	   = seq_num_r;
      syn_flag 		   = 1'b0;
      ack_flag 		   = 1'b0;
      fin_flag 		   = 1'b0;
      reply_fifo_wrreq 	   = 1'b0;
      reply_fifo_in.data   = 'b0;
      reply_fifo_in.sop    = 1'b0;
      reply_fifo_in.eop    = 1'b0;
      reply_fifo_in.valid  = 1'b0;
      reply_fifo_in.error  = 1'b0;
      reply_fifo_in.empty  = 'b0;
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

		if (in.eop) begin

		   // received reply message
		   // no need to process, simply forward
		   		   
		end
		else begin

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
		   // Update offset for 20 byte tcp header
		   first_next.data[511-1-32 -: 7] = header_offset_next + 7'd20;

		   ethtype_next = in.data[511-1-32-7-3 -: 16];
		   if (ethtype_next == 16'h0800) begin
		      src_addr_next[31:0] = in.data[511-1-32-7-3-16 -: 32];
		      dst_addr_next[31:0] = in.data[511-1-32-7-3-16-32 -: 32];
		   end
		   else if (ethtype_next == 16'h86DD) begin
		      src_addr_next = in.data[511-1-32-7-3-16 -: 128];
		      dst_addr_next = in.data[511-1-32-7-3-16-128 -: 128];
		   end
		   else
		     $error("TCP: Received packet that is neither IPv4 nor IPv6");
		   
		   fsm_next = HEADER1;

		end
	     end

	   HEADER1: 
	     if (in.valid) begin
		
		dst_port = in.data[511-(header_offset_r*8)-16 -: 16];
		second_next.data[511-1-32-7-128-128 -: 16] = dst_port; // place dst port in header

		if (header_offset_r > 50) begin

		   if (header_offset_r == 58) begin
		      seq_num_next[31 -: 16] = in.data[15:0];
		      fsm_next = HEADER2;
		   end
		   else begin
		      seq_num_next = in.data[511-(header_offset_r*8)-32 -: 32];
		      fsm_next = HEADER2;
		   end

		end
		else begin
		
		   ack_flag = in.data[511-(header_offset_r*8)-107];
		   syn_flag = in.data[511-(header_offset_r*8)-110];
		   fin_flag = in.data[511-(header_offset_r*8)-111];
		   seq_num_next  = in.data[511-(header_offset_r*8)-32 -: 32];

		   if (syn_flag && !ack_flag) begin
		      // Generate ack reply
		      reply_fifo_wrreq = 1'b1;
		      
		      reply_fifo_in.sop = 1'b1;
		      reply_fifo_in.eop = 1'b1;
		      reply_fifo_in.valid = 1'b1;
		      
		      // Ethernet header (reverse src and dest mac addresses)
		      reply_fifo_in.data[511 -: 48] = in.data[511-48 -: 48];
		      reply_fifo_in.data[511-48 -: 48] = in.data[511 -: 48];
		      reply_fifo_in.data[511-48-48 -: 16] = ethtype_r; // ethertype
		      // IP header
		      // IPv4 (reverse src and dest ip addres)
		      reply_fifo_in.data[511-48-48-16 -: 16] = 16'h4500;
		      reply_fifo_in.data[511-48-48-16-16 -: 16] = 16'd40; // IPv4 + TCP
		      reply_fifo_in.data[511-48-48-16-16-16 -: 32] = 32'h00004000;
		      reply_fifo_in.data[511-48-48-16-16-16-32 -: 8] = 8'd10; // TTL
		      reply_fifo_in.data[511-48-48-16-16-16-32-8 -: 8] = 8'h06; // prot=TCP
		      reply_fifo_in.data[511-48-48-16-16-16-32-8-8 -: 16] = 16'd0; // checksum invalid
		      reply_fifo_in.data[511-48-48-16-16-16-32-8-8-16 -: 32] = dst_addr_r[31:0];
		      reply_fifo_in.data[511-48-48-16-16-16-32-8-8-16-32 -: 32] = src_addr_r[31:0];
		      
		      // TCP
		      reply_fifo_in.data[511-272 -: 16] = dst_port; // switch src and dst port
		      reply_fifo_in.data[511-272-16 -: 16] = in.data[511-(header_offset_r*8) -: 16];
		      reply_fifo_in.data[511-272-16-16 -: 32] = ack_cnt_r; // seq num
		      ack_cnt_next = ack_cnt_r + 1; // update ack cnt for next
		      reply_fifo_in.data[511-272-16-16-32 -: 32] = seq_num_next + 1; // ack num
		      reply_fifo_in.data[511-272-16-16-32-32 -: 16] = 16'h0012; // set ack and syn flags
		      reply_fifo_in.data[511-272-16-16-32-32-16 -: 48] = 48'd0;

		   end
		   
		   if (in.eop)
		     fsm_next = SOP;
		   else
		     fsm_next = BODY;

		end // else: !if(header_offset_r > 50)
		
	     end // if (in.valid)

	   HEADER2:
	     if (in.valid) begin

		ack_flag = in.data[511+(512-(header_offset_r*8)-107)];
		syn_flag = in.data[511+(512-(header_offset_r*8)-110)];
		fin_flag = in.data[511+(512-(header_offset_r*8)-111)];
		if (header_offset_r == 58) begin
		   seq_num_next[15:0] = in.data[511 -: 16];
		end

		if (syn_flag && !ack_flag) begin
		   // Generate ack reply
		   reply_fifo_wrreq = 1'b1;
		   
		   reply_fifo_in.sop = 1'b1;
		   reply_fifo_in.eop = 1'b1;
		   reply_fifo_in.valid = 1'b1;
		   
		   // Ethernet header (reverse src and dest mac addresses)
		   reply_fifo_in.data[511 -: 48] = first_r.data[511-48 -: 48];
		   reply_fifo_in.data[511-48 -: 48] = first_r.data[511 -: 48];
		   reply_fifo_in.data[511-48-48 -: 16] = ethtype_r; // ethertype
		   // IP header
		   // IPv4 (reverse src and dest ip addres)
		   reply_fifo_in.data[511-48-48-16 -: 16] = 16'h4500;
		   reply_fifo_in.data[511-48-48-16-16 -: 16] = 16'd40; // IPv4 + TCP
		   reply_fifo_in.data[511-48-48-16-16-16 -: 32] = 32'h00004000;
		   reply_fifo_in.data[511-48-48-16-16-16-32 -: 8] = 8'd10; // TTL
		   reply_fifo_in.data[511-48-48-16-16-16-32-8 -: 8] = 8'h06; // prot=TCP
		   reply_fifo_in.data[511-48-48-16-16-16-32-8-8 -: 16] = 16'd0; // checksum invalid
		   reply_fifo_in.data[511-48-48-16-16-16-32-8-8-16 -: 32] = dst_addr_r[31:0];
		   reply_fifo_in.data[511-48-48-16-16-16-32-8-8-16-32 -: 32] = src_addr_r[31:0];
		   
		   // TCP
		   // switch src and dst port
		   reply_fifo_in.data[511-272 -: 16] = first_r.data[511-(header_offset_r*8)-16 -: 16];
		   reply_fifo_in.data[511-272-16 -: 16] = first_r.data[511-(header_offset_r*8) -: 16];
		   reply_fifo_in.data[511-272-16-16 -: 32] = ack_cnt_r; // seq num
		   ack_cnt_next = ack_cnt_r + 1; // update ack cnt for next
		   reply_fifo_in.data[511-272-16-16-32 -: 32] = seq_num_next + 1; // ack num
		   reply_fifo_in.data[511-272-16-16-32-32 -: 16] = 16'h0012; // set ack and syn flags
		   reply_fifo_in.data[511-272-16-16-32-32-16 -: 48] = 48'd0;

		end
		
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

      if (ready_r) begin
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
