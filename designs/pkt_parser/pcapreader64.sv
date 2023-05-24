`timescale 1ns / 1ps
`define NULL 0

module pcapreader64
  #(
    //parameter WIDTH = 64,
    parameter PCAP_FILENAME = "out.pcap"
    )
   (
    input 	 clk,
    input 	 system_clk,
    input 	 system_reset,
    output logic o_finished,
		 
		 avalonST.src out

    );

   localparam WIDTH = 64; // sadly can't figure out a way to parametrize width here :(
   
   logic [7:0]  global_header [0:23];
   logic [7:0]  packet_header [0:15]; // 16 bytes = 128 bit packet header field
   int 		packet_size; // (32 bits wide) in bytes
   int 		file = 0;
   int 	        r = 0;
   int 	        swapped = 0;
   int 		eof = 0;
   //int 		i;

   logic send_flag;
   
   initial begin

      file = $fopen(PCAP_FILENAME, "rb");
      if (file == `NULL) begin
	 $display("can't read pcap input %s", PCAP_FILENAME);
	 $finish;
      end

      r = $fread(global_header,file);

      if ((global_header[0] == 8'hD4 && global_header[1] == 8'hC3 && global_header[2] == 8'hB2) ||
	  (global_header[0] == 8'h4D && global_header[1] == 8'h3C && global_header[2] == 8'hB2))
	begin
	   swapped = 1;
	end
      else begin
	 swapped = 0;
      end

      r = $fread(packet_header,file);

      //send_flag = 1'b0;

      @(negedge system_reset);
      @(posedge system_clk);
            
   end // initial begin

/* -----\/----- EXCLUDED -----\/-----
   always_ff @(posedge system_clk)
     if (system_reset) send_flag = 1'b0;
     else send_flag = 1'b1;
 -----/\----- EXCLUDED -----/\----- */
   
   always_ff @(posedge clk) begin
      // defaults
      out.valid  = 1'b0;
      out.sop 	 = 1'b0;
      out.eop 	 = 1'b0;
      out.error  = 1'b0;
      out.empty  = 'b0;
      out.data 	 = 'b0;
      o_finished = 1'b0;
                  
      if (out.ready /*&& send_flag*/) begin

	 eof = $feof(file);
	 
	 if (eof == 0) begin

	    out.valid = 1'b1;
	    
	    if (packet_size == 0) begin
	              
	       if (swapped == 1)
		 packet_size = {packet_header[11],
				packet_header[10],
				packet_header[9],
				packet_header[8]};
	       else
		 packet_size = {packet_header[8],
				packet_header[9],
				packet_header[10],
				packet_header[11]};

	       out.sop = 1'b1;
	    end
	    
	    out.data[7*8+:8] <= packet_size > 0 ? $fgetc(file) : 8'b0;
	    out.data[6*8+:8] <= packet_size > 1 ? $fgetc(file) : 8'b0;
	    out.data[5*8+:8] <= packet_size > 2 ? $fgetc(file) : 8'b0;
	    out.data[4*8+:8] <= packet_size > 3 ? $fgetc(file) : 8'b0;
	    out.data[3*8+:8] <= packet_size > 4 ? $fgetc(file) : 8'b0;
	    out.data[2*8+:8] <= packet_size > 5 ? $fgetc(file) : 8'b0;
	    out.data[1*8+:8] <= packet_size > 6 ? $fgetc(file) : 8'b0;
	    out.data[0*8+:8] <= packet_size > 7 ? $fgetc(file) : 8'b0;

	    out.empty = (packet_size > 7) ? 0 : 8 - packet_size;
	    packet_size = (packet_size > 7) ? packet_size - 8 : 0;

	    if (packet_size == 0) begin
	       out.eop = 1'b1;
	       r = $fread(packet_header,file);
	    end
	    
	    /* -----\/----- EXCLUDED -----\/-----
	    for (i=0; i<$clog2(WIDTH); i++) begin

	       out.data[WIDTH -: 8*(i+1)] = $fgetc(file);
	       packet_size -= 1;
	       if (packet_size == 0) break;
	       
	    end	    
	     -----/\----- EXCLUDED -----/\----- */
	    
	 end // if (eof == 0)
	 else
	   o_finished = 1'b1;
	 	 
      end

   end // always_ff @

endmodule
