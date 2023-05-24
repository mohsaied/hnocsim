module ethernet512
  #(
    parameter MAC_ADDRESS = 48'hA1B2C3D4E5F6,
    parameter MEM_DEPTH = 512,
    parameter NUM_VC = 2,
    parameter NOC_RADIX = 16,
    parameter PORT_ID = 2,
    parameter MEM_WIDTH = $clog2(NOC_RADIX) + 1, // port # + valid bit
    parameter DEST = 4'd0,
    parameter NUM_IPV4 = 4,
    parameter START_IPV4 = 0,
    parameter [$clog2(NOC_RADIX)-1:0] IPV4_DEST [0:NUM_IPV4-1] = '{4,9,6,11},
    parameter NUM_IPV6 = 1,
    parameter START_IPV6 = 0,
    parameter [$clog2(NOC_RADIX)-1:0] IPV6_DEST [0:NUM_IPV6-1] = '{10}
    )
   (
    input  clk,
    input  reset,
	   
    avalonST.sink in,
    avalonST.src out,

    output logic [$clog2(NUM_VC)-1:0] o_vc_id, // Virtual Channel ID (for priority scheme)
    output logic [$clog2(NOC_RADIX)-1:0]  o_noc_dst

    );

   import global_package::*;
      
   logic [$clog2(MEM_DEPTH)-1:0] mem_addr;
   logic [MEM_WIDTH-1:0] 	 mem_data_in;
   logic [MEM_WIDTH-1:0] 	 mem_data_out;
   logic 			 mem_wren;
   logic 			 mem_rden;
         
   // Table stores MAC address -> port number assignment
   ram #(.WIDTH(MEM_WIDTH),
	 .DEPTH(MEM_DEPTH)) mac_table (.clock(clk),
				       .address(mem_addr),
				       .data(mem_data_in),
				       .wren(mem_wren),
				       .rden(mem_rden),
				       .q(mem_data_out));
      
   typedef struct packed {
      logic 	  valid;
      logic 	  sop;
      logic 	  eop;
      logic 	  error;
      logic [5:0] empty;
      logic [511:0] data;
   } avalonst_t;

   //assign in.ready = out.ready;
   
   // Need to hold first three beats of packet before
   // deciding what to do with it
   avalonst_t first_r, first_next;
   avalonst_t second_r, second_next;
   avalonst_t third_r, third_next;
   avalonst_t fourth_r, fourth_next;
   
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
   end
   
   always_comb begin
      // Defaults
      first_next   = first_r;
      second_next  = second_r;
      third_next   = third_r;
      fourth_next  = fourth_r;
                       
      if (out.ready/* && in.valid*/) begin
	 first_next.valid  = in.valid;
	 first_next.sop    = in.sop;
	 first_next.eop    = in.eop;
	 first_next.error  = in.error;
	 first_next.empty  = in.empty;
	 first_next.data   = in.data;
      end // if (out.ready && in.valid)

      if (out.ready/* && first_r.valid*/)
      	second_next 	   = first_r;

      if (out.ready/* && second_r.valid*/)
	 third_next 	   = second_r;

      if (out.ready/* && third_r.valid*/)
	fourth_next = third_r;
      
   end // always_comb

   
   // Parse Ethernet header
   enum {FIRST,SECOND,THIRD,FOURTH,SEND_HEAD} fsm_r, fsm_next;
   always_ff @(posedge clk) fsm_r <= (reset) ? FIRST : fsm_next;

   logic [47:0] mac_dst_r, mac_dst_next;
   logic [47:0] mac_src_r, mac_src_next;
   logic [15:0] ethtype_r, ethtype_next;
   logic [15:0] ethtype2_r, ethtype2_next;
   logic [2:0] 	pcp_r, pcp_next;
   logic 	dei_r, dei_next;
   logic [11:0] vid_r, vid_next;
   logic [$clog2(NOC_RADIX)-1:0] out_port_r, out_port_next;
   mod_map_t dst_mod;
   mod_t rout_mod_r,rout_mod_next;

   logic [$clog2(NUM_IPV4):0] 	 rr_ipv4_cnt_r, rr_ipv4_cnt_next;
   logic [$clog2(NUM_IPV6):0] 	 rr_ipv6_cnt_r, rr_ipv6_cnt_next;
         
   always_ff @(posedge clk) begin

      mac_dst_r  <= (reset) ? 'b0 : mac_dst_next;
      mac_src_r  <= (reset) ? 'b0 : mac_src_next;
      ethtype_r  <= (reset) ? 'b0 : ethtype_next;
      ethtype2_r <= (reset) ? 'b0 : ethtype2_next;
      pcp_r 	 <= (reset) ? 'b0 : pcp_next;
      dei_r 	 <= (reset) ? 'b0 : dei_next;
      vid_r 	 <= (reset) ? 'b0 : vid_next;
      out_port_r <= (reset) ? 'b0 : out_port_next;
      rout_mod_r <= (reset) ? ipv4_mod : rout_mod_next;
      rr_ipv4_cnt_r <= (reset) ? START_IPV4 : rr_ipv4_cnt_next;
      rr_ipv6_cnt_r <= (reset) ? START_IPV6 : rr_ipv6_cnt_next;
            
   end
   
   always_comb begin
      // Defaults
      fsm_next 		= fsm_r;
      mac_dst_next 	= mac_dst_r;
      mac_src_next 	= mac_src_r;
      ethtype_next 	= ethtype_r;
      ethtype2_next 	= ethtype2_r;
      pcp_next 		= pcp_r;
      dei_next 		= dei_r;
      vid_next 		= vid_r;
      out_port_next 	= out_port_r;
      rout_mod_next 	= rout_mod_r;
      mem_addr 		= 'b0;
      mem_data_in 	= 'b0;
      mem_wren 		= 1'b0;
      mem_rden 		= 1'b0;
      dst_mod 		= ipv4;
      rr_ipv4_cnt_next 	= rr_ipv4_cnt_r;
      rr_ipv6_cnt_next 	= rr_ipv6_cnt_r;
      in.ready 		= out.ready;
                                                
      // Assign output
      if (out.ready) begin

	 out.valid  = fourth_r.valid;
	 out.sop    = fourth_r.sop;
	 out.eop    = fourth_r.eop;
	 out.error  = fourth_r.error;
	 out.empty  = fourth_r.empty;
	 out.data   = fourth_r.data;
	 o_noc_dst  = out_port_r;
	 o_vc_id = 0;
	 
      end
      else begin

	 out.valid  = 1'b0;
	 out.sop    = 1'b0;
	 out.eop    = 1'b0;
	 out.error  = 1'b0;
	 out.empty  = 'b0;
	 out.data   = 'b0;
	 o_noc_dst  = 'b0;
	 o_vc_id = 0;
	 	 
      end
            
      case (fsm_r)

	FIRST:
	  if (out.ready) begin

	     //in.ready = 1'b1;
	     
	     if (in.sop && in.valid)
	       fsm_next = SECOND;
	     	     
	  end

	SECOND: 
	  if (out.ready) begin

	     if (in.valid) begin

		mac_dst_next = in.data[511 -: 48];
		mac_src_next = in.data[511-48 -: 48];
		ethtype_next = in.data[511-48-48 -: 16];

		if (ethtype_next == 16'h8100) begin // VLAN

		   pcp_next 	  = in.data[511-48-48-16 -: 3];
		   dei_next 	  = in.data[511-48-48-16-3];
		   vid_next 	  = in.data[511-48-48-16-3-1 -: 12];
		   ethtype2_next  = in.data[511-48-48-16-3-1-12 -: 16];
		   		   		   
		end
		else begin

		   pcp_next 	  = 'b0;
		   dei_next 	  = 'b0;
		   vid_next 	  = 'b0;
		   ethtype2_next  = 'b0;
		   		   
		end // else: !if(ethtype_next == 16'h8100)
		

		if (mac_dst_next != MAC_ADDRESS) begin
		   // Route through Layer 2
		   // Lookup port number to send out
		   mem_addr = mac_dst_r[$clog2(MEM_DEPTH)-1:0];
		   mem_rden = 1'b1;
		   		   
		end

		fsm_next = THIRD;
				
	     end // if (in.valid)
	     //else
	     //  in.ready = 1'b1;
	     	     
	  end

	THIRD: 
	  if (out.ready) begin

		// Determine if src address exists in mac_table
		mem_addr = mac_src_r[$clog2(MEM_DEPTH)-1:0];
		mem_rden = 1'b1;	
	
		// Compute out_port
		if (mac_dst_r != MAC_ADDRESS) begin

		   if (mem_data_out[MEM_WIDTH-1]) begin // valid bit

		      out_port_next = mem_data_out[MEM_WIDTH-2:0];
		      
		   end
		   else begin
		      // Broadcast packet to all ports
		      // or, for now, just use layer 3
		      if (ethtype_r == 16'h0800 || ethtype2_r == 16'h0800) begin
			 dst_mod = ipv4;
			 rout_mod_next = ipv4_mod;
		      end
		      else if (ethtype_r == 16'h86DD || ethtype2_r == 16'h86DD) begin
			 dst_mod = ipv6;
			 rout_mod_next = ipv6_mod;
		      end

		      if (dst_mod == ipv4) begin
			 //out_port_next = IPV4_DEST[rr_ipv4_cnt_r];
			 //out_port_next = DEST;
/* -----\/----- EXCLUDED -----\/-----
			 if (PORT_ID == 0 || PORT_ID == 1)
			   out_port_next = 4;
			 else if (PORT_ID == 2 || PORT_ID == 3)
			   out_port_next = 6;
			 else
			   $error("Ethernet PORT ID is not equal to 0,1,2,3");
 -----/\----- EXCLUDED -----/\----- */
			 out_port_next = IPV4_DEST[PORT_ID];
			 
			 //rr_ipv4_cnt_next = rr_ipv4_cnt_r+1;
			 //if (rr_ipv4_cnt_next >= NUM_IPV4)
			 //  rr_ipv4_cnt_next = 0;
		      end
		      else if (dst_mod == ipv6) begin
			 out_port_next = IPV4_DEST[PORT_ID];
			 //out_port_next = IPV6_DEST[0];
/* -----\/----- EXCLUDED -----\/-----
			 if (PORT_ID==0)
			   out_port_next = IPV6_DEST[0];
			 else if (PORT_ID==1)
			   out_port_next = IPV6_DEST[1];
			 else if (PORT_ID==3)
			   out_port_next = IPV6_DEST[2];
			 else if (PORT_ID==2) begin
			    out_port_next = IPV6_DEST[rr_ipv6_cnt_r];
			    rr_ipv6_cnt_next = rr_ipv6_cnt_r+1;
			    if (rr_ipv6_cnt_next >= NUM_IPV6)
			      rr_ipv6_cnt_next = 0;
			 end
			 else
			   $error("Ethernet PORT ID is not equal to 0,1,2,3");
 -----/\----- EXCLUDED -----/\----- */
/* -----\/----- EXCLUDED -----\/-----
			 if (PORT_ID == 0 || PORT_ID == 1)
			   out_port_next = IPV6_DEST[0];
			 else if (PORT_ID == 2 || PORT_ID == 3)
			   out_port_next = IPV6_DEST[1];
			 else
			   $error("Ethernet PORT ID is not equal to 0,1,2,3");
 -----/\----- EXCLUDED -----/\----- */
			 //out_port_next = 5;
			 //out_port_next = DEST;
			 //if (PORT_ID == 0)
			 //  out_port_next = IPV6_DEST[PORT_ID%NUM_IPV6];
			 //else if (PORT_ID == 1)
			 //  out_port_next = IPV6_DEST[1];
			 //else if (PORT_ID == 2 || PORT_ID == 3)
			 //  out_port_next = IPV6_DEST[2];
			 //else
			 //  $error("Ethernet PORT ID is not equal to 0,1,2,3");
			 //out_port_next = IPV6_DEST[rr_ipv6_cnt_r];
			 //rr_ipv6_cnt_next = rr_ipv6_cnt_r+1;
			 //if (rr_ipv6_cnt_next >= NUM_IPV6)
			 //  rr_ipv6_cnt_next = 0;
		      end
		      
		   end
		   
		end // if (mac_dst_r != MAC_ADDRESS)
		else begin
		   
		   if (ethtype_r == 16'h0800) begin
		      dst_mod = ipv4;
		      rout_mod_next = ipv4_mod;
		   end
		   if (ethtype_r == 16'h86DD) begin
		      dst_mod = ipv6;
		      rout_mod_next = ipv6_mod;
		   end

		   if (dst_mod == ipv4) begin
		      out_port_next = IPV4_DEST[PORT_ID];
		      //out_port_next = IPV4_DEST[rr_ipv4_cnt_r];
		      //out_port_next = DEST;
/* -----\/----- EXCLUDED -----\/-----
		      if (PORT_ID == 0 || PORT_ID == 1)
			out_port_next = 4;
		      else if (PORT_ID == 2 || PORT_ID == 3)
			out_port_next = 6;
		      else
			$error("Ethernet PORT ID is not equal to 0,1,2,3");
 -----/\----- EXCLUDED -----/\----- */
		      //rr_ipv4_cnt_next = rr_ipv4_cnt_r+1;
		      //if (rr_ipv4_cnt_next >= NUM_IPV4)
			//rr_ipv4_cnt_next = 0;
		   end
		   else if (dst_mod == ipv6) begin
		      out_port_next = IPV4_DEST[PORT_ID];
		      //out_port_next = IPV6_DEST[0];
/* -----\/----- EXCLUDED -----\/-----
		      if (PORT_ID==0)
			out_port_next = IPV6_DEST[0];
		      else if (PORT_ID==1)
			out_port_next = IPV6_DEST[1];
		      else if (PORT_ID==3)
			out_port_next = IPV6_DEST[2];
		      else if (PORT_ID==2) begin
			 out_port_next = IPV6_DEST[rr_ipv6_cnt_r];
			 rr_ipv6_cnt_next = rr_ipv6_cnt_r+1;
			 if (rr_ipv6_cnt_next >= NUM_IPV6)
			   rr_ipv6_cnt_next = 0;
		      end
		      else
			$error("Ethernet PORT ID is not equal to 0,1,2,3");
 -----/\----- EXCLUDED -----/\----- */
/* -----\/----- EXCLUDED -----\/-----
		      if (PORT_ID == 0 || PORT_ID == 1)
			out_port_next = IPV6_DEST[0];
		      else if (PORT_ID == 2 || PORT_ID == 3)
			out_port_next = IPV6_DEST[1];
		      else
			$error("Ethernet PORT ID is not equal to 0,1,2,3");
 -----/\----- EXCLUDED -----/\----- */
		      //out_port_next = 5;
		      //out_port_next = DEST;
/* -----\/----- EXCLUDED -----\/-----
		      if (PORT_ID == 0 || PORT_ID == 1)
			out_port_next = 5;
		      else if (PORT_ID == 2 || PORT_ID == 3)
			out_port_next = 7;
		      else
			$error("Ethernet PORT ID is not equal to 0,1,2,3");
 -----/\----- EXCLUDED -----/\----- */
		      //if (PORT_ID == 0)
			//out_port_next = IPV6_DEST[PORT_ID%NUM_IPV6];
		      //else if (PORT_ID == 1)
			//out_port_next = IPV6_DEST[1];
		      //else if (PORT_ID == 2 || PORT_ID == 3)
			//out_port_next = IPV6_DEST[2];
		      //else
			//$error("Ethernet PORT ID is not equal to 0,1,2,3");
		      //out_port_next = IPV6_DEST[rr_ipv6_cnt_r];
		      //rr_ipv6_cnt_next = rr_ipv6_cnt_r+1;
		      //if (rr_ipv6_cnt_next >= NUM_IPV6)
			//rr_ipv6_cnt_next = 0;
		   end
		   
		end // else: !if(mac_dst_r != MAC_ADDRESS)	     
	
		fsm_next = FOURTH;
					     	     
	  end // if (out.ready)

	FOURTH:
	  if (out.ready) begin

	     if (ethtype_r == 16'h8100) begin
		
		if (ethtype2_r == 16'h0800) begin
		   dst_mod = ipv4;
		   rout_mod_next = ipv4_mod;
		end
		if (ethtype2_r == 16'h86DD) begin
		   dst_mod = ipv6;
		   rout_mod_next = ipv6_mod;
		end

		if (dst_mod == ipv4) begin
		   out_port_next = IPV4_DEST[PORT_ID];
		   //out_port_next = IPV4_DEST[rr_ipv4_cnt_r];
		   //out_port_next = DEST;
/* -----\/----- EXCLUDED -----\/-----
		   if (PORT_ID == 0 || PORT_ID == 1)
		     out_port_next = 4;
		   else if (PORT_ID == 2 || PORT_ID == 3)
		     out_port_next = 6;
		   else
		     $error("Ethernet PORT ID is not equal to 0,1,2,3");
 -----/\----- EXCLUDED -----/\----- */
		   //rr_ipv4_cnt_next = rr_ipv4_cnt_r+1;
		   //if (rr_ipv4_cnt_next >= NUM_IPV4)
		     //rr_ipv4_cnt_next = 0;
		end
		else if (dst_mod == ipv6) begin
		   out_port_next = IPV4_DEST[PORT_ID];
		   //out_port_next = IPV6_DEST[0];
/* -----\/----- EXCLUDED -----\/-----
		   if (PORT_ID==0)
		     out_port_next = IPV6_DEST[0];
		   else if (PORT_ID==1)
		     out_port_next = IPV6_DEST[1];
		   else if (PORT_ID==3)
		     out_port_next = IPV6_DEST[2];
		   else if (PORT_ID==2) begin
		      out_port_next = IPV6_DEST[rr_ipv6_cnt_r];
		      rr_ipv6_cnt_next = rr_ipv6_cnt_r+1;
		      if (rr_ipv6_cnt_next >= NUM_IPV6)
			rr_ipv6_cnt_next = 0;
		   end
		   else
		     $error("Ethernet PORT ID is not equal to 0,1,2,3");
 -----/\----- EXCLUDED -----/\----- */
/* -----\/----- EXCLUDED -----\/-----
		   if (PORT_ID == 0 || PORT_ID == 1)
		     out_port_next = IPV6_DEST[0];
		   else if (PORT_ID == 2 || PORT_ID == 3)
		     out_port_next = IPV6_DEST[1];
		   else
		     $error("Ethernet PORT ID is not equal to 0,1,2,3");
 -----/\----- EXCLUDED -----/\----- */
		   //out_port_next = 5;
		   //out_port_next = DEST;
/* -----\/----- EXCLUDED -----\/-----
		   if (PORT_ID == 0 || PORT_ID == 1)
		     out_port_next = 5;
		   else if (PORT_ID == 2 || PORT_ID == 3)
		     out_port_next = 7;
		   else
		     $error("Ethernet PORT ID is not equal to 0,1,2,3");
 -----/\----- EXCLUDED -----/\----- */
		   //if (PORT_ID == 0)
		   //  out_port_next = IPV6_DEST[PORT_ID%NUM_IPV6];
		   //else if (PORT_ID == 1)
		   //  out_port_next = IPV6_DEST[1];
		   //else if (PORT_ID == 2 || PORT_ID == 3)
		   //  out_port_next = IPV6_DEST[2];
		   //else
		   //  $error("Ethernet PORT ID is not equal to 0,1,2,3");
		   //out_port_next = IPV6_DEST[rr_ipv6_cnt_r];
		   //rr_ipv6_cnt_next = rr_ipv6_cnt_r+1;
		   //if (rr_ipv6_cnt_next >= NUM_IPV6)
		   //  rr_ipv6_cnt_next = 0;
		end
		
	     end

	     fsm_next = SEND_HEAD;
	     	     
	  end

	SEND_HEAD:
	  if (out.ready) begin

	     // Determine if src address exists in mac_table
	     // If it doesn't update mac_table
	     // Note: It takes two cycles between rden and data being available
	     if (!mem_data_out[MEM_WIDTH-1]) begin // valid bit
		
		mem_wren = 1'b1;
		
		//if ($clog2(MEM_DEPTH) <= 32)
		mem_addr = mac_src_r[$clog2(MEM_DEPTH)-1:0];
		//else
		//  mem_addr = {mac_src_msb_r[$clog2(MEM_DEPTH)-32-1:0],mac_src_lsb_r[31:0]};

		mem_data_in[$clog2(NOC_RADIX)] = 1'b1;
		mem_data_in[$clog2(NOC_RADIX)-1:0] = PORT_ID;
		
	     end // if (!mem_data_out[MEM_WIDTH-1])

	     if (ethtype_r == 16'h8100)
	       out.data[511-1-32 -: 7] = 7'd18; // 18 byte header (w/ vlan) --> set offset to 18
	     else
	       out.data[511-1-32 -: 7] = 7'd14; // 14 byte header (no vlan) --> set offset to 14

	     // Add dest module to header
	     out.data[511-1-32-7 -: 3] = rout_mod_r;

	     if (ethtype_r == 16'h0800 || ethtype2_r == 16'h0800)
	       out.data[511-1-32-7-3 -: 16] = 16'h0800;
	     else if (ethtype_r == 16'h86DD || ethtype2_r == 16'h86DD)
	       out.data[511-1-32-7-3-: 16] = 16'h86DD;
	     	     
	     fsm_next = FIRST;
	     	     	     	     
	  end

	default:
	  if (reset) fsm_next = FIRST;
	
      endcase // case (fsm_r)
      
   end // always_comb
      


endmodule   
