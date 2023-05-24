module ethernet64
  #(
    parameter MAC_ADDRESS = 48'hA1B2C3D4E5F6,
    parameter MEM_DEPTH = 512,
    parameter NUM_NOC_VC = 2,
    parameter NOC_RADIX = 16,
    parameter PORT_ID = 2,
    parameter MEM_WIDTH = $clog2(NOC_RADIX) + 1 // port # + valid bit
    )
   (
    input  clk,
    input  reset,
	   
    avalonST.sink in,
    avalonST.src out,

    output logic [$clog2(NUM_NOC_VC)-1:0] o_vc_id, // Virtual Channel ID (for priority scheme)
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
      logic [2:0] empty;
      logic [63:0] data;
   } avalonst_t;

   assign in.ready = out.ready;
   
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
                       
      if (out.ready) begin
	 first_next.valid  = in.valid;
	 first_next.sop    = in.sop;
	 first_next.eop    = in.eop;
	 first_next.error  = in.error;
	 first_next.empty  = in.empty;
	 first_next.data   = in.data;
      end // if (out.ready && in.valid)

      if (out.ready)
      	second_next 	   = first_r;

      if (out.ready)
	 third_next 	   = second_r;

      if (out.ready)
	fourth_next = third_r;
      
   end // always_comb

   
   // Parse Ethernet header
   enum {FIRST,SECOND,THIRD,FOURTH,SEND_HEAD} fsm_r, fsm_next;
   always_ff @(posedge clk) fsm_r <= (reset) ? FIRST : fsm_next;

   logic [47:0] mac_dst_r, mac_dst_next;
   logic [15:0] mac_src_msb_r, mac_src_msb_next;
   logic [31:0] mac_src_lsb_r, mac_src_lsb_next;
   logic [48:0] mac_src;
   logic [15:0] ethtype_r, ethtype_next;
   logic [2:0] 	pcp_r, pcp_next;
   logic 	dei_r, dei_next;
   logic [11:0] vid_r, vid_next;
   logic [$clog2(NOC_RADIX)-1:0] out_port_r, out_port_next;
   mod_map_t dst_mod;
      
   always_ff @(posedge clk) begin

      mac_dst_r     <= (reset) ? 'b0 : mac_dst_next;
      mac_src_msb_r <= (reset) ? 'b0 : mac_src_msb_next;
      mac_src_lsb_r <= (reset) ? 'b0 : mac_src_lsb_next;
      ethtype_r     <= (reset) ? 'b0 : ethtype_next;
      pcp_r 	    <= (reset) ? 'b0 : pcp_next;
      dei_r 	    <= (reset) ? 'b0 : dei_next;
      vid_r 	    <= (reset) ? 'b0 : vid_next;
      out_port_r    <= (reset) ? 'b0 : out_port_next;
      
   end
   
   always_comb begin
      // Defaults
      fsm_next 		= fsm_r;
      mac_dst_next 	= mac_dst_r;
      mac_src_msb_next 	= mac_src_msb_r;
      mac_src_lsb_next 	= mac_src_lsb_r;
      ethtype_next 	= ethtype_r;
      pcp_next 		= pcp_r;
      dei_next 		= dei_r;
      vid_next 		= vid_r;
      out_port_next 	= out_port_r;
      mem_addr 		= 'b0;
      mem_data_in 	= 'b0;
      mem_wren 		= 1'b0;
      mem_rden 		= 1'b0;
      dst_mod 		= ipv4;
                                          
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

	     if (in.sop && in.valid)
	       fsm_next = SECOND;
	     	     
	  end

	SECOND: 
	  if (out.ready) begin

	     if (in.valid) begin

		mac_dst_next = in.data[63 -: 48];
		mac_src_msb_next = in.data[15:0];

		if (mac_dst_next != MAC_ADDRESS) begin
		   // Route through Layer 2
		   // Lookup port number to send out
		   mem_addr = mac_dst_r[$clog2(MEM_DEPTH)-1:0];
		   mem_rden = 1'b1;
		   		   
		end

		fsm_next = THIRD;
				
	     end
	     
	  end

	THIRD: 
	  if (out.ready) begin

	     if (in.valid) begin

		mac_src_lsb_next = in.data[63 -: 32];
		ethtype_next = in.data[31 -: 16];

		// Determine if src address exists in mac_table
		//if ($clog2(MEM_DEPTH) <= 32)
		mem_addr = mac_src_lsb_next[$clog2(MEM_DEPTH)-1:0];
		mem_rden = 1'b1;
		//else
		//  mem_addr = {mac_src_msb_r[$clog2(MEM_DEPTH)-32-1:0],mac_src_lsb_next[31:0]};
		
		if (ethtype_next == 16'h8100) begin // VLAN

		   pcp_next = in.data[15 -: 3];
		   dei_next = in.data[12];
		   vid_next = in.data[11:0];
		   		   
		end
		else begin

		   pcp_next = 'b0;
		   dei_next = 'b0;
		   vid_next = 'b0;
		   
		end // else: !if(ethtype_next == 16'h8100)
	
		// Compute out_port
		if (mac_dst_r != MAC_ADDRESS) begin

		   if (mem_data_out[MEM_WIDTH-1]) begin // valid bit

		      out_port_next = mem_data_out[MEM_WIDTH-2:0];
		      
		   end
		   else begin
		      // Broadcast packet to all ports
		      // or, for now, just use layer 3
		      if (ethtype_next == 16'h0800 ||
			  (ethtype_next == 16'h8100 && in.data[63 -: 16] == 16'h0800)) begin
			 dst_mod = ipv4;
			 out_port_next = dst_mod;
		      end
		      
		   end
		   
		end
		else begin
		   
		   if (ethtype_next == 16'h0800) begin
		      dst_mod = ipv4;
		      out_port_next = dst_mod;
		   end
		   
		end // else: !if(mac_dst_r != MAC_ADDRESS)	     
	
		fsm_next = FOURTH;
				
	     end // if (in.valid)
	     
	     	     
	  end // if (out.ready)

	FOURTH:
	  if (out.ready) begin

	     if (in.valid) begin

		if (ethtype_r == 16'h8100) begin
		   
		   if (in.data[63 -: 16] == 16'h0800) begin
		      dst_mod = ipv4;
		      out_port_next = dst_mod;
		   end

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
		mem_addr = mac_src_lsb_r[$clog2(MEM_DEPTH)-1:0];
		//else
		//  mem_addr = {mac_src_msb_r[$clog2(MEM_DEPTH)-32-1:0],mac_src_lsb_r[31:0]};

		mem_data_in[$clog2(NOC_RADIX)] = 1'b1;
		mem_data_in[$clog2(NOC_RADIX)-1:0] = PORT_ID;
		
	     end // if (!mem_data_out[MEM_WIDTH-1])

	     if (ethtype_r == 16'h8100)
	       out.data[30 -: 6] = 6'd18; // 18 byte header (w/ vlan) --> set offset to 18
	     else
	       out.data[30 -: 6] = 6'd14; // 14 byte header (no vlan) --> set offset to 14

	     fsm_next = FIRST;
	     	     
	  end

	default:
	  if (reset) fsm_next = FIRST;
	
      endcase // case (fsm_r)
      
   end // always_comb
      


endmodule   
