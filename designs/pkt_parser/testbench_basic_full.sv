`timescale 1ps / 1ps

module testbench_basic_full;

   parameter DATA_WIDTH = 512; // must be a multiple of 64
   parameter MAX_HEADER_SIZE = 1;
   parameter NUM_SRC = 4;
   //parameter string PCAP_FILENAME [0:NUM_SRC-1] = '{"src0.pcap","src1.pcap","src2.pcap","src3.pcap"};
   parameter NUM_VC = 2;
   parameter NOC_RADIX = 16;
   parameter PORT_WIDTH = 600;
   parameter NOC_WIDTH = PORT_WIDTH/4;
   parameter [$clog2(NUM_VC)-1:0] ASSIGNED_VC [0:NOC_RADIX-1] = '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

   parameter [3:0] SRC [0:NUM_SRC-1]  = '{4'd0,4'd1,4'd2,4'd3};
   parameter [3:0] DEST [0:NUM_SRC-1]  = '{4'd12,4'd13,4'd14,4'd15};
   parameter [3:0] IP_NODE [0:NUM_SRC-1] = '{4'd4,4'd5,4'd6,4'd7};
   parameter NUM_IPV4 = 4;
   parameter NUM_IPV6 = 1;
   parameter [$clog2(NUM_IPV4):0] START_IPV4 [0:NUM_SRC-1] = '{0,1,1,2};
   parameter [$clog2(NUM_IPV6):0] START_IPV6 [0:NUM_SRC-1] = '{0,0,0,0};
   parameter [$clog2(NOC_RADIX)-1:0] IPV4_DEST [0:NUM_IPV4-1] = '{4,5,6,7};
   parameter [$clog2(NOC_RADIX)-1:0] IPV6_DEST [0:NUM_IPV6-1] = '{10};
   parameter [3:0] TCP_NODE [0:NUM_SRC-1] = '{4'd8,4'd9,4'd10,4'd11};

   parameter NUM_PACKETS = 5;
   //parameter real INJECTION_RATE = 1250; // 100% flit inj rate
   //parameter real INJECTION_RATE = 875; // 87.5% flit inj rate
   parameter real INJECTION_RATE = 650; // 65.0% flit inj rate

   parameter string PCAP_FILENAME [0:NUM_SRC-1] = '{"src0.pcap",
						    "src1.pcap",
						    "src2.pcap",
						    "src3.pcap"};
      
   localparam N = NOC_RADIX;
   localparam IN_FIFO_DEPTH = 4096;

   //string PCAP_FILENAME [NUM_SRC];

   //initial PCAP_FILENAME[0:NUM_SRC-1] = '{"src0.pcap","src1.pcap","src2.pcap","src3.pcap"};

   
   logic 		 clk_noc;
   logic [N-1:0] 	 clk_rtl;
   logic [N-1:0] 	 clk_int;
   logic 		 reset;

   wire 		 valid_t2f [0:N-1];
   wire [PORT_WIDTH-1:0] data_t2f [0:N-1];
   wire 		 ready_t2f [0:N-1];
   
   wire 		 valid_f2t [0:N-1];
   wire [PORT_WIDTH-1:0] data_f2t [0:N-1];
   wire 		 ready_f2t [0:N-1];

   wire [NUM_SRC-1:0] 	 finished;
   
   genvar 		 i;

   avalonST #(.WIDTH(DATA_WIDTH)) pcap2dut [NUM_SRC] ();
   avalonST #(.WIDTH(DATA_WIDTH)) dut2mon [NUM_SRC] ();
   
   generate
      for (i=0;i<NUM_SRC;i++) begin
   	 
	 pcapreader512 #(.PCAP_FILENAME(PCAP_FILENAME[i]),
			 .INJECTION_RATE(INJECTION_RATE),
			 .SEED(i)) pcapreader (.clk(clk_rtl[0]),
					       .o_finished(finished[i]),
					       .out(pcap2dut[i]));

	 always_comb
	   if (pcap2dut[i].ready == 1'b0 && !reset) 
	     $warning("Warning: Backpressuring source %.2d",i);


	 if (i==0 || i==1 || i==2 || i==3) begin

	    txr_to_noc_basic #(.DATA_WIDTH(DATA_WIDTH),
			       .NUM_VC(NUM_VC),
			       .NOC_RADIX(NOC_RADIX),
			       .NOC_WIDTH(PORT_WIDTH),
			       .PORT_ID(i),
			       .FIFO_DEPTH(IN_FIFO_DEPTH),
			       .DEST(IP_NODE[i]),
			       .NUM_IPV4(NUM_IPV4),
			       .START_IPV4(START_IPV4[i]),
			       .IPV4_DEST(IPV4_DEST),
			       .NUM_IPV6(NUM_IPV6),
			       .START_IPV6(START_IPV6[i]),
			       .IPV6_DEST(IPV6_DEST)) txr_to_noc (.clk(clk_rtl[0]),
								  .reset(reset),
								  .in(pcap2dut[i]),
								  .o_data_out(data_t2f[i]),
								  .o_valid_out(valid_t2f[i]),
								  .o_ready_in(ready_t2f[i]));

	    if (i==4) begin
	       
	       ipv4_top #(.DATA_WIDTH(DATA_WIDTH),
			  .NOC_WIDTH(PORT_WIDTH),
			  .NOC_RADIX(NOC_RADIX),
			  .NUM_VC(NUM_VC),
			  .NUM_SRC(NUM_SRC),
			  .DEST(TCP_NODE),
			  .PORT_ID(IP_NODE[i])) ipv4 (.clk(clk_rtl[0]),
							   .reset(reset),
							   .i_data_in(data_f2t[i+4]),
							   .i_valid_in(valid_f2t[i+4]),
							   .i_ready_out(ready_f2t[i+4]),
							   .o_data_out(data_t2f[i+4]),
							   .o_valid_out(valid_t2f[i+4]),
							   .o_ready_in(ready_t2f[i+4]));

	       ipv6_top #(.DATA_WIDTH(DATA_WIDTH),
			  .NOC_WIDTH(PORT_WIDTH),
			  .NOC_RADIX(NOC_RADIX),
			  .NUM_VC(NUM_VC),
			  .NUM_SRC(NUM_SRC),
			  .DEST(TCP_NODE),
			  .PORT_ID(9)) ipv6 (.clk(clk_rtl[0]),
							   .reset(reset),
							   .i_data_in(data_f2t[i+8]),
							   .i_valid_in(valid_f2t[i+8]),
							   .i_ready_out(ready_f2t[i+8]),
							   .o_data_out(data_t2f[i+8]),
							   .o_valid_out(valid_t2f[i+8]),
							   .o_ready_in(ready_t2f[i+8]));

	       noc_to_tcp_to_txr #(.DATA_WIDTH(DATA_WIDTH),
				.NOC_WIDTH(PORT_WIDTH),
				.NUM_VC(NUM_VC),
				.NOC_RADIX(NOC_RADIX),
				.REPLY_DEST(SRC[i])) noc_to_tcp_to_txr (.clk(clk_rtl[0]),
								      .reset(reset),
								      .i_data_in(data_f2t[i+12]),
								      .i_valid_in(valid_f2t[i+12]),
								      .i_ready_out(ready_f2t[i+12]),
								      .o_data_out(data_t2f[i+12]),
								      .o_valid_out(valid_t2f[i+12]),
								      .o_ready_in(ready_t2f[i+12]),
								      .out(dut2mon[i]));

	    end // if (i == 1)
	    else begin
	    
	       ipv4_ipv6_top #(.DATA_WIDTH(DATA_WIDTH),
			  .NOC_WIDTH(PORT_WIDTH),
			  .NOC_RADIX(NOC_RADIX),
			  .NUM_VC(NUM_VC),
			  .NUM_SRC(NUM_SRC),
			  .DEST(TCP_NODE),
			  .PORT_ID(IP_NODE[i])) ipv4_ipv6 (.clk(clk_rtl[0]),
						      .reset(reset),
						      .i_data_in(data_f2t[i+4]),
						      .i_valid_in(valid_f2t[i+4]),
						      .i_ready_out(ready_f2t[i+4]),
						      .o_data_out(data_t2f[i+4]),
						      .o_valid_out(valid_t2f[i+4]),
						      .o_ready_in(ready_t2f[i+4]));
	       

	       tcp_top #(.DATA_WIDTH(DATA_WIDTH),
			 .NOC_WIDTH(PORT_WIDTH),
			 .NUM_VC(NUM_VC),
			 .NOC_RADIX(NOC_RADIX),
			 .NUM_SRC(NUM_SRC),
			 .DEST(DEST),
			 .REPLY_DEST(SRC[i]),
			 .PORT_ID(i+8)) tcp (.clk(clk_rtl[0]),
					     .reset(reset),
					     .i_data_in(data_f2t[i+8]),
					     .i_valid_in(valid_f2t[i+8]),
					     .i_ready_out(ready_f2t[i+8]),
					     .o_data_out(data_t2f[i+8]),
					     .o_valid_out(valid_t2f[i+8]),
					     .o_ready_in(ready_t2f[i+8]));	 	 
	       
	       
	       noc_to_txr_basic #(.DATA_WIDTH(DATA_WIDTH),
				  .NOC_WIDTH(PORT_WIDTH),
				  .NUM_VC(NUM_VC),
				  .NOC_RADIX(NOC_RADIX)) noc_to_txr (.clk(clk_rtl[0]),
								     .reset(reset),
								     .i_data_in(data_f2t[i+12]),
								     .i_valid_in(valid_f2t[i+12]),
								     .i_ready_out(ready_f2t[i+12]),
								     .out(dut2mon[i]));

	    end // else: !if(i == 1)
	    

	 end // if (i==0 || i==1 || i==2 || i==3)
	 else begin

	    txr_to_noc_basic #(.DATA_WIDTH(DATA_WIDTH),
			       .NUM_VC(NUM_VC),
			       .NOC_RADIX(NOC_RADIX),
			       .NOC_WIDTH(PORT_WIDTH),
			       .PORT_ID(i),
			       .FIFO_DEPTH(IN_FIFO_DEPTH),
			       .DEST(IP_NODE[i]),
			       .NUM_IPV4(NUM_IPV4),
			       .START_IPV4(START_IPV4[i]),
			       .IPV4_DEST(IPV4_DEST),
			       .NUM_IPV6(NUM_IPV6),
			       .START_IPV6(START_IPV6[i]),
			       .IPV6_DEST(IPV6_DEST)) txr_to_noc (.clk(clk_rtl[0]),
								  .reset(reset),
								  .in(pcap2dut[i]),
								  .o_data_out(data_t2f[i+12]),
								  .o_valid_out(valid_t2f[i+12]),
								  .o_ready_in(ready_t2f[i+12]));

	    if (i == 1) begin
	       
	       ipv4_top #(.DATA_WIDTH(DATA_WIDTH),
			  .NOC_WIDTH(PORT_WIDTH),
			  .NOC_RADIX(NOC_RADIX),
			  .NUM_VC(NUM_VC),
			  .NUM_SRC(NUM_SRC),
			  .DEST(TCP_NODE),
			  .PORT_ID(IP_NODE[i])) ipv4 (.clk(clk_rtl[0]),
							   .reset(reset),
							   .i_data_in(data_f2t[i+4]),
							   .i_valid_in(valid_f2t[i+4]),
							   .i_ready_out(ready_f2t[i+4]),
							   .o_data_out(data_t2f[i+4]),
							   .o_valid_out(valid_t2f[i+4]),
							   .o_ready_in(ready_t2f[i+4]));

	       ipv6_top #(.DATA_WIDTH(DATA_WIDTH),
			  .NOC_WIDTH(PORT_WIDTH),
			  .NOC_RADIX(NOC_RADIX),
			  .NUM_VC(NUM_VC),
			  .NUM_SRC(NUM_SRC),
			  .DEST(TCP_NODE),
			  .PORT_ID(IP_NODE[i])) ipv6 (.clk(clk_rtl[0]),
							   .reset(reset),
							   .i_data_in(data_f2t[i+8]),
							   .i_valid_in(valid_f2t[i+8]),
							   .i_ready_out(ready_f2t[i+8]),
							   .o_data_out(data_t2f[i+8]),
							   .o_valid_out(valid_t2f[i+8]),
							   .o_ready_in(ready_t2f[i+8]));

	    end // if (i == 1)
	    else begin

	       ipv4_top #(.DATA_WIDTH(DATA_WIDTH),
			  .NOC_WIDTH(PORT_WIDTH),
			  .NOC_RADIX(NOC_RADIX),
			  .NUM_VC(NUM_VC),
			  .NUM_SRC(NUM_SRC),
			  .DEST(TCP_NODE),
			  .PORT_ID(IP_NODE[i])) ipv4 (.clk(clk_rtl[0]),
							   .reset(reset),
							   .i_data_in(data_f2t[i+8]),
							   .i_valid_in(valid_f2t[i+8]),
							   .i_ready_out(ready_f2t[i+8]),
							   .o_data_out(data_t2f[i+8]),
							   .o_valid_out(valid_t2f[i+8]),
							   .o_ready_in(ready_t2f[i+8]));

	    end
	    

/* -----\/----- EXCLUDED -----\/-----
	    tcp_top #(.DATA_WIDTH(DATA_WIDTH),
		      .NOC_WIDTH(PORT_WIDTH),
		      .NUM_VC(NUM_VC),
		      .NOC_RADIX(NOC_RADIX),
		      .NUM_SRC(NUM_SRC),
		      .DEST(DEST),
		      .REPLY_DEST(SRC[i]),
		      .PORT_ID(i+4)) tcp (.clk(clk_rtl[0]),
					  .reset(reset),
					  .i_data_in(data_f2t[i+4]),
					  .i_valid_in(valid_f2t[i+4]),
					  .i_ready_out(ready_f2t[i+4]),
					  .o_data_out(data_t2f[i+4]),
					  .o_valid_out(valid_t2f[i+4]),
					  .o_ready_in(ready_t2f[i+4]));	 	 
	    
	    
	    noc_to_txr_basic #(.DATA_WIDTH(DATA_WIDTH),
			       .NOC_WIDTH(PORT_WIDTH),
			       .NUM_VC(NUM_VC),
			       .NOC_RADIX(NOC_RADIX)) noc_to_txr (.clk(clk_rtl[0]),
								  .reset(reset),
								  .i_data_in(data_f2t[i]),
								  .i_valid_in(valid_f2t[i]),
								  .i_ready_out(ready_f2t[i]),
								  .out(dut2mon[i]));
 -----/\----- EXCLUDED -----/\----- */

	    noc_to_tcp_to_txr #(.DATA_WIDTH(DATA_WIDTH),
				.NOC_WIDTH(PORT_WIDTH),
				.NUM_VC(NUM_VC),
				.NOC_RADIX(NOC_RADIX),
				.REPLY_DEST(SRC[i])) noc_to_tcp_to_txr (.clk(clk_rtl[0]),
								      .reset(reset),
								      .i_data_in(data_f2t[i]),
								      .i_valid_in(valid_f2t[i]),
								      .i_ready_out(ready_f2t[i]),
								      .o_data_out(data_t2f[i]),
								      .o_valid_out(valid_t2f[i]),
								      .o_ready_in(ready_t2f[i]),
								      .out(dut2mon[i]));

	 end
	 	 						    
	 
      end // for (i=0;i<NUM_SRC;i++)

   endgenerate

   // *** DEBUG ***

   logic sop_r [0:N-1];
   logic sop_next [0:N-1];

   generate
      for (i=0;i<N;i++) begin
	 
	 always_ff @(posedge clk_rtl[0]) sop_r[i] <= (reset) ? 1'b0 : sop_next[i];

	 always @(negedge clk_rtl[0]) begin
	    sop_next[i] = sop_r[i];

	    if (valid_t2f[i] && data_t2f[i][599]) begin

	       if (data_t2f[i][598]) begin
		  
		  if (sop_r[i])
		    $error("Node %.2d: Sending SOP before sending EOP for prev packet",i);
		  else if (!(data_t2f[i][597] || 
			     data_t2f[i][447] || 
			     data_t2f[i][297] || 
			     data_t2f[i][147]))
		    sop_next[i] = 1'b1;
		  
	       end
	       else if (data_t2f[i][597] || 
			data_t2f[i][447] || 
			data_t2f[i][297] || 
			data_t2f[i][147]) begin

		  if (sop_r[i])
		    sop_next[i] = 1'b0;
		  else
		    $error("Node %.2d: Sending EOP without an SOP",i);

	       end
	       else begin

		  if (!sop_r[i])
		    $error("Node %.2d: Sending body flit without an SOP",i);
		  
	       end

	    end
	    
	 end // always_comb

      end // for (i=0;i<N;i++)

   endgenerate

   // **************

   assign ready_f2t[SRC[0]] = 1'b1;
   assign ready_f2t[SRC[1]] = 1'b1;
   assign ready_f2t[SRC[2]] = 1'b1;
   assign ready_f2t[SRC[3]] = 1'b1;

   logic clk_quarter;
         
   fabric_interface_sw #(.WIDTH_NOC(NOC_WIDTH),
		      .WIDTH_RTL(PORT_WIDTH),
		      .N(NOC_RADIX),
		      .NUM_VC(NUM_VC),
		      .DEPTH_PER_VC(64),
		      //.ASSIGNED_VC(ASSIGNED_VC),
		      .VERBOSE(0)) fabric_interface (//.clk_noc(clk_noc),
						     .clk(clk_quarter),
						     .clk_rtl(clk_rtl),
						     //.clk_int(clk_int),
						     .rst(reset),
						     .i_packets_in(data_t2f),
						     .i_valids_in(valid_t2f),
						     .i_readys_out(ready_t2f),
						     .o_packets_out(data_f2t),
						     .o_valids_out(valid_f2t),
						     .o_readys_in(ready_f2t)
						     );

   
   monitor #(.DATA_WIDTH(DATA_WIDTH),
	     .NOC_RADIX(NOC_RADIX),
	     .BIDIRECTIONAL(0),
	     .NUM_SRC(NUM_SRC)) mon (.clk(clk_rtl[0]),
				     .reset(reset),
				     .in_injected(pcap2dut),
				     .in_received(dut2mon));

   
   // generate clock
   genvar j;
   generate
      for (j=0;j<N;j++) begin
	 initial clk_rtl[j] = 1'b1;
	 always #3332 clk_rtl[j] = ~clk_rtl[j]; // 215 MHz clock
	 //always #4648 clk_rtl[j] = ~clk_rtl[j]; // 215 MHz clock
	 //always #5000 clk_rtl[j] = ~clk_rtl[j]; // 200 MHz clock
	 //always #10000 clk_rtl[j] = ~clk_rtl[j]; // 100 MHz clock
	 //always #20000 clk_rtl[j] = ~clk_rtl[j]; // 50 MHz clock

	 initial clk_int[j] = 1'b1;
	 always #1162 clk_int[j] = ~clk_int[j];
	 //always #1250 clk_int[j] = ~clk_int[j];
	 //always #2500 clk_int[j] = ~clk_int[j];
	 //always #5000 clk_int[j] = ~clk_int[j];
	 
      end
   endgenerate
	 
   initial clk_noc = 1'b1;
   always #833 clk_noc = ~clk_noc; // 1.2 GHz clock

   initial clk_quarter = 1'b1;
   always #3332 clk_quarter = ~clk_quarter;

   initial begin
      reset = 1'b0;
      #50;
      reset = 1'b1;
      #41000;
      reset = 1'b0;
   end   

endmodule
