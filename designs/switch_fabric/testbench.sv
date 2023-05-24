`timescale 1ps/1ps

module testbench();

   parameter DATA_WIDTH = 64;
   parameter NUM_VC = 2;
   parameter PACKET_WIDTH = (DATA_WIDTH+1+1+1+3+1)*2;
   parameter PORT_WIDTH = 600 /*PACKET_WIDTH*4+DEST_WIDTH+4*(3+$clog2(NUM_VC))*/;
   parameter NOC_WIDTH = PORT_WIDTH/4;
   parameter N = 16;
   parameter DEST_WIDTH = $clog2(N);
   parameter INPUT_DEPTH = 320;
   parameter OUTPUT_DEPTH = 640;
   
   parameter STORAGE = 16;
   parameter WARMUP_CYCLES = 2000;
   parameter NUM_CYCLES = 5000;
   parameter VERBOSE = 0;
   parameter [$clog2(NUM_VC)-1:0] ASSIGNED_VC [0:N-1] = '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
   parameter END_SIM_COUNT = 10;
   parameter real END_SIM_THRESH = 1.5;
                        
   parameter FIXED_PACKET_SIZE = 64;
   parameter INJECTION_RATE = 313; // 1.33% packet injection rate

   parameter SEED = 12;
                        
   logic [N-1:0] 	 clk_rtl;
   logic [N-1:0] 	 clk_int;
   logic 		 clk_noc;
   logic 		 reset;

   wire 		 valid_s2t [0:N-1];
   wire 		 sop_s2t [0:N-1];
   wire 		 eop_s2t [0:N-1];
   wire 		 error_s2t [0:N-1];
   wire [2:0] 		 empty_s2t [0:N-1];
   wire [DATA_WIDTH-1:0] data_s2t [0:N-1];
   wire 		 ready_s2t [0:N-1];

   wire 		 valid_t2s [0:N-1];
   wire 		 sop_t2s [0:N-1];
   wire 		 eop_t2s [0:N-1];
   wire 		 error_t2s [0:N-1];
   wire [2:0] 		 empty_t2s [0:N-1];
   wire [DATA_WIDTH-1:0] data_t2s [0:N-1];
   wire 		 ready_t2s [0:N-1];

   wire 		 valid_t2f [0:N-1];
   wire [PORT_WIDTH-1:0] data_t2f [0:N-1];
   wire 		 ready_t2f [0:N-1];

   wire 		 valid_f2t [0:N-1];
   wire [PORT_WIDTH-1:0] data_f2t [0:N-1];
   wire 		 ready_f2t [0:N-1];

   
   avalon_eth_source_sink #(.DATA_WIDTH(DATA_WIDTH),
			    .DEST_WIDTH(DEST_WIDTH),
			    .N(N),
			    .FIXED_PACKET_SIZE(FIXED_PACKET_SIZE),
			    .INJECTION_RATE(INJECTION_RATE),
			    .NUM_CYCLES(NUM_CYCLES),
			    .SEED(SEED)
			    ) avalon_eth_source_sink (.clk(clk_rtl[0]),
							    .reset(reset),
							    .o_valid(valid_s2t),
							    .o_sop(sop_s2t),
							    .o_eop(eop_s2t),
							    .o_error(error_s2t),
							    .o_empty(empty_s2t),
							    .o_data(data_s2t),
							    .i_ready(ready_s2t),
							    .i_valid(valid_t2s),
							    .i_sop(sop_t2s),
							    .i_eop(eop_t2s),
							    .i_error(error_t2s),
							    .i_empty(empty_t2s),
							    .i_data(data_t2s),
							    .o_ready(ready_t2s));
   							    

   top #(.OUT_WIDTH(PORT_WIDTH),
	 .PACKET_WIDTH(PACKET_WIDTH),
	 .DATA_WIDTH(DATA_WIDTH),
	 .DEST_WIDTH(DEST_WIDTH),
	 .N(N),
	 .NUM_VC(NUM_VC),
	 .WARMUP_CYCLES(WARMUP_CYCLES),
	 .NUM_CYCLES(NUM_CYCLES),
	 .VERBOSE(VERBOSE),
	 .ASSIGNED_VC(ASSIGNED_VC),
	 .END_SIM_COUNT(END_SIM_COUNT),
	 .END_SIM_THRESH(END_SIM_THRESH),
	 .INPUT_DEPTH(INPUT_DEPTH),
	 .OUTPUT_DEPTH(OUTPUT_DEPTH),
	 .INJECTION_RATE(INJECTION_RATE)) dut (.clk(clk_rtl[0]),
			       .reset(reset),
			       .i_valid_avalon_in(valid_s2t),
			       .i_sop_avalon_in(sop_s2t),
			       .i_eop_avalon_in(eop_s2t),
			       .i_data_avalon_in(data_s2t),
			       .i_empty_avalon_in(empty_s2t),
			       .i_error_avalon_in(error_s2t),
			       .o_ready_avalon_in(ready_s2t),

			       .o_valid_avalon_out(valid_t2s),
			       .o_sop_avalon_out(sop_t2s),
			       .o_eop_avalon_out(eop_t2s),
			       .o_data_avalon_out(data_t2s),
			       .o_empty_avalon_out(empty_t2s),
			       .o_error_avalon_out(error_t2s),
			       .i_ready_avalon_out(ready_t2s),

			       .o_data_to_noc(data_t2f),
			       .o_valid_to_noc(valid_t2f),
			       .i_ready_to_noc(ready_t2f),

			       .i_data_from_noc(data_f2t),
			       .i_valid_from_noc(valid_f2t),
			       .o_ready_from_noc(ready_f2t));
   
			       

   fabric_interface #(.WIDTH_NOC(NOC_WIDTH),
		      .WIDTH_RTL(PORT_WIDTH),
		      .N(N),
		      .NUM_VC(NUM_VC),
		      .DEPTH_PER_VC(16),
		      .ASSIGNED_VC(ASSIGNED_VC),
		      .VERBOSE(0)
		      )
		      fabric_interface (.clk_noc(clk_noc),
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
   
		      
   genvar 		 j;

   // generate clock
   
   generate
      for (j=0;j<N;j++) begin
	 initial clk_rtl[j] = 1'b1;
	 //always #6400 clk_rtl[j] = ~clk_rtl[j]; // 156.25 MHz clock
	 always #1600 clk_rtl[j] = ~clk_rtl[j];

	 initial clk_int[j] = 1'b1;
	 //always #1600 clk_int[j] = ~clk_int[j]; // 625 MHz clock
	 always #400 clk_int[j] = ~clk_int[j];
	 
      end
   endgenerate
	 
   initial clk_noc = 1'b1;
   always #833 clk_noc = ~clk_noc; // 1.2 GHz clock
      

   initial begin
      reset = 1'b0;
      #400;
      reset = 1'b1;
      #13000;
      reset = 1'b0;
   end
	   
   
endmodule
