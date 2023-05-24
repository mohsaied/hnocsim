`timescale 1ns / 1ps

module pcapreader_testbench;

   parameter DATA_WIDTH = 64;
   parameter PCAP_FILENAME = "out.pcap";
   
   logic clk;
   logic reset;

   logic finished;
   
   avalonST #(.WIDTH(DATA_WIDTH)) pcap2pre ();
   
   // generate clock
   initial clk = 1'b1;
   always #6400 clk = ~clk; // 156.25 MHz clock

   initial begin
      reset = 1'b0;
      #50;
      reset = 1'b1;
      #20000;
      reset = 1'b0;
   end

   pcapreader64 #(.PCAP_FILENAME(PCAP_FILENAME)) pcapreader (.clk(clk),
							     .o_finished(finished),
							     .out(pcap2pre));
   

   assign pcap2pre.ready = 1'b1;
      
   always_ff @(posedge clk) begin

      if (pcap2pre.valid) $display("SOP: %b, EOP %b, EMPTY: %d, Data: %h",pcap2pre.sop,pcap2pre.eop,pcap2pre.empty,pcap2pre.data);
      else if (finished)
	$finish;
           
   end

endmodule
