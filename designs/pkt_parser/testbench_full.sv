`timescale 1ns / 1ps

module testbench_full;

   parameter DATA_WIDTH = 512; // must be a multiple of 64
   parameter MAX_HEADER_SIZE = 1;
   parameter NUM_SRC = 4;
   //parameter string PCAP_FILENAME [0:NUM_SRC-1] = '{"src0.pcap","src1.pcap","src2.pcap","src3.pcap"};
   parameter NUM_VC = 2;
   parameter NOC_RADIX = 16;
   parameter PORT_WIDTH = 600;
   parameter NOC_WIDTH = PORT_WIDTH/4;
   parameter [$clog2(NUM_VC)-1:0] ASSIGNED_VC [0:NOC_RADIX-1] = '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

   parameter [3:0] DEST [NUM_SRC-1:0]  = '{4'd15,4'd14,4'd13,4'd12};
   parameter [3:0] IP_NODE [NUM_SRC-1:0] = '{4'd7,4'd6,4'd5,4'd4};
   parameter [3:0] TCP_NODE [NUM_SRC-1:0] = '{4'd11,4'd10,4'd9,4'd8};
   

   parameter DDR_PORT = 4;
      
   parameter real INJECTION_RATE = 1250;
   
   localparam N = NOC_RADIX;

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

   generate
      for (i=0;i<NUM_SRC;i++) begin
   
	 avalonST #(.WIDTH(DATA_WIDTH)) pcap2dut ();
	 avalonST #(.WIDTH(DATA_WIDTH)) dut2mon ();
	 
	 pcapreader512 #(.PCAP_FILENAME("src0.pcap"),
			 .INJECTION_RATE(INJECTION_RATE),
			 .SEED(i)) pcapreader (.clk(clk_rtl[0]),
					       .o_finished(finished[i]),
					       .out(pcap2dut));

         
	 txr_to_noc #(.DATA_WIDTH(DATA_WIDTH),
		      .NUM_VC(NUM_VC),
		      .MAX_HEADER_SIZE(MAX_HEADER_SIZE),
		      .NOC_RADIX(NOC_RADIX),
		      .NOC_WIDTH(PORT_WIDTH),
		      .PORT_ID(i),
		      .DEST(IP_NODE[i]),
		      .DDR_PORT(DDR_PORT)) txr_to_noc (.clk(clk_rtl[0]),
						.reset(reset),
						.in(pcap2dut),
						.o_data_out(data_t2f[i]),
						.o_valid_out(valid_t2f[i]),
						.o_ready_in(ready_t2f[i]));
	 

	 if (i == 0) begin

	    ddr_ipv4_top #(.DATA_WIDTH(DATA_WIDTH),
			   .NOC_WIDTH(PORT_WIDTH),
			   .NUM_VC(NUM_VC),
			   .NOC_RADIX(NOC_RADIX),
			   .DEST(TCP_NODE[i]),
			   .NODE_ID(i+4)) ddr_ipv4 (.clk(clk_rtl[0]),
						.reset(reset),
						.i_data_in(data_f2t[i+4]),
						.i_valid_in(valid_f2t[i+4]),
						.i_ready_out(ready_f2t[i+4]),
						.o_data_out(data_t2f[i+4]),
						.o_valid_out(valid_t2f[i+4]),
						.o_ready_in(ready_t2f[i+4]));

	 end
	 else begin
	    
	    ipv4_top #(.DATA_WIDTH(DATA_WIDTH),
		       .NOC_WIDTH(PORT_WIDTH),
		       .NUM_VC(NUM_VC),
		       .NOC_RADIX(NOC_RADIX),
		       .DEST(TCP_NODE[i]),
		       .PORT_ID(i+4)) ipv4 (.clk(clk_rtl[0]),
					    .reset(reset),
					    .i_data_in(data_f2t[i+4]),
					    .i_valid_in(valid_f2t[i+4]),
					    .i_ready_out(ready_f2t[i+4]),
					    .o_data_out(data_t2f[i+4]),
					    .o_valid_out(valid_t2f[i+4]),
					    .o_ready_in(ready_t2f[i+4]));

	 end // else: !if(i == 0)

	 tcp_top #(.DATA_WIDTH(DATA_WIDTH),
		   .NOC_WIDTH(PORT_WIDTH),
		   .NUM_VC(NUM_VC),
		   .NOC_RADIX(NOC_RADIX),
		   .DEST(DEST[i]),
		   .PORT_ID(i+8)) tcp (.clk(clk_rtl[0]),
					.reset(reset),
					.i_data_in(data_f2t[i+8]),
					.i_valid_in(valid_f2t[i+8]),
					.i_ready_out(ready_f2t[i+8]),
					.o_data_out(data_t2f[i+8]),
					.o_valid_out(valid_t2f[i+8]),
					.o_ready_in(ready_t2f[i+8]));
	 
	 
	 noc_to_txr #(.DATA_WIDTH(DATA_WIDTH),
		      .NOC_WIDTH(PORT_WIDTH),
		      .NUM_VC(NUM_VC),
		      .NODE_ID(i+12),
		      .DDR_PORT(DDR_PORT),
		      .NOC_RADIX(NOC_RADIX)) noc_to_txr (.clk(clk_rtl[0]),
							 .reset(reset),
							 .i_data_in(data_f2t[i+12]),
							 .i_valid_in(valid_f2t[i+12]),
							 .i_ready_out(ready_f2t[i+12]),
							 .o_data_out(data_t2f[i+12]),
							 .o_valid_out(valid_t2f[i+12]),
							 .o_ready_in(ready_t2f[i+12]),
							 .out(dut2mon));
	 

	 assign dut2mon.ready = 1'b1;
      
	 always_ff @(posedge clk_rtl) begin
	    
	    if (dut2mon.valid) $display("N%.1d - SOP: %b, EOP: %b, Empty: %d, Data: %h",i,dut2mon.sop,dut2mon.eop,dut2mon.empty,dut2mon.data);
            
	 end

      end // for (i=0;i<NUM_SRC;i++)

   endgenerate

/* -----\/----- EXCLUDED -----\/-----
   ddr_top #(.DATA_WIDTH(DATA_WIDTH/-*+$clog2(DATA_WIDTH/8)*-/),
	     .PORT_WIDTH(PORT_WIDTH),
	     .NUM_VC(NUM_VC),
	     .NOC_RADIX(NOC_RADIX)) ddr (.clk(clk_rtl[0]),
					 .reset(reset),
					 .i_data_in(data_f2t[DDR_PORT]),
					 .i_valid_in(valid_f2t[DDR_PORT]),
					 .i_ready_out(ready_f2t[DDR_PORT]),
					 .o_data_out(data_t2f[DDR_PORT]),
					 .o_valid_out(valid_t2f[DDR_PORT]),
					 .o_ready_in(ready_t2f[DDR_PORT]));
 -----/\----- EXCLUDED -----/\----- */
   	     

   fabric_interface #(.WIDTH_NOC(NOC_WIDTH),
		      .WIDTH_RTL(PORT_WIDTH),
		      .N(NOC_RADIX),
		      .NUM_VC(NUM_VC),
		      .DEPTH_PER_VC(16),
		      .ASSIGNED_VC(ASSIGNED_VC),
		      .VERBOSE(0)) fabric_interface (.clk_noc(clk_noc),
						     .clk_rtl(clk_rtl),
						     .clk_int(clk_int),
						     .rst(reset),
						     .i_packets_in(data_t2f),
						     .i_valids_in(valid_t2f),
						     .i_readys_out(ready_t2f),
						     .o_packets_out(data_f2t),
						     .o_valids_out(valid_f2t),
						     .o_readys_in(ready_f2t)
						     );
   
   
   // generate clock
   genvar j;
   generate
      for (j=0;j<N;j++) begin
	 initial clk_rtl[j] = 1'b1;
	 always #5000 clk_rtl[j] = ~clk_rtl[j]; // 200 MHz clock
	 //always #10000 clk_rtl[j] = ~clk_rtl[j]; // 100 MHz clock
	 //always #20000 clk_rtl[j] = ~clk_rtl[j]; // 50 MHz clock
	 
	 initial clk_int[j] = 1'b1;
	 always #1250 clk_int[j] = ~clk_int[j];
	 //always #2500 clk_int[j] = ~clk_int[j];
	 //always #5000 clk_int[j] = ~clk_int[j];
	 
      end
   endgenerate
	 
   initial clk_noc = 1'b1;
   always #833 clk_noc = ~clk_noc; // 1.2 GHz clock

   initial begin
      reset = 1'b0;
      #50;
      reset = 1'b1;
      #41000;
      reset = 1'b0;
   end   

endmodule
