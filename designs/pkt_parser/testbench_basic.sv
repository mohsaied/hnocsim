`timescale 1ns / 1ps

module testbench_basic;

   parameter DATA_WIDTH = 512; // must be a multiple of 64
   parameter MAX_HEADER_SIZE = 10;
   parameter PCAP_FILENAME = "out.pcap";
   parameter NUM_NOC_VC = 2;
   parameter NOC_RADIX = 16;
   
   
   logic clk;
   logic clk_fast;
   logic reset;
   
   logic [$clog2(NUM_NOC_VC)-1:0] vc_id;
   logic [$clog2(NOC_RADIX)-1:0]  noc_dst;
      
   
   // generate clock
   initial clk = 1'b1;
   always #6400 clk = ~clk; // 156.25 MHz clock

   initial clk_fast = 1'b1;
   always #800 clk_fast = ~clk_fast; // MULT_FACTOR = 8
         
   initial begin
      reset = 1'b0;
      #50;
      reset = 1'b1;
      #20000;
      reset = 1'b0;
   end

   assign parser_in_pause = reset;
   
   avalonST #(.WIDTH(DATA_WIDTH)) pcap2dut ();
   avalonST #(.WIDTH(DATA_WIDTH)) dut2mon ();
   
   pcapreader512 #(.PCAP_FILENAME(PCAP_FILENAME)) pcapreader (.clk(clk),
							     .o_finished(finished),
							     .out(pcap2dut));

               
   txr_to_noc_basic #(.DATA_WIDTH(DATA_WIDTH),
		      .NUM_VC(NUM_NOC_VC),
		      .NOC_RADIX(NOC_RADIX)) dut (.clk(clk),
						  .reset(reset),
						  .in(pcap2dut),
						  .out(dut2mon),
						  .o_vc_id(vc_id),
						  .o_noc_dst(noc_dst));
   
   assign dut2mon.ready = 1'b1;
   
   int pkt_sent_r, pkt_sent_next;
   int pkt_rec_r, pkt_rec_next;

   always_ff @(posedge clk) pkt_sent_r <= (reset) ? 'b0 : pkt_sent_next;
   always_ff @(posedge clk) pkt_rec_r <= (reset) ? 'b0 : pkt_rec_next;

   always_comb begin
      
      pkt_sent_next = pkt_sent_r;
      pkt_rec_next = pkt_rec_r;

      if (pcap2dut.valid && pcap2dut.sop) pkt_sent_next = pkt_sent_r + 1;
      if (dut2mon.valid && 
	  dut2mon.sop && 
	  !dut2mon.data[DATA_WIDTH-1])   
	pkt_rec_next  = pkt_rec_r + 1;
      
   end

   always_ff @(posedge clk) begin
      
      if (dut2mon.valid) $display("SOP: %b, EOP: %b, Empty: %d, Data: %h, NoC_dst: %d",dut2mon.sop,dut2mon.eop,dut2mon.empty,dut2mon.data,noc_dst);
      
      //if ((pkt_rec_r == pkt_sent_r) && finished && dut2mon.eop) $finish;
      
   end
           						      
endmodule
   
