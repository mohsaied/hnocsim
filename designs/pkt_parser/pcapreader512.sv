`timescale 1ns / 1ps
`define NULL 0

module pcapreader512
  #(
    //parameter WIDTH = 64,
    parameter PCAP_FILENAME = "out.pcap",
    parameter real INJECTION_RATE = 1250,
    parameter SEED = 1
    )
   (
    input 	 clk,
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


            
   end // initial begin

   logic bern_r;
   logic send;
   int 	 unsigned seed_bern;
   int 	 unsigned random;
   int 	 unsigned pkts_to_send_r, pkts_to_send_next;
               
   initial begin 
      seed_bern = SEED;
   end
      
   always_ff @(posedge clk) begin
            
      seed_bern = $urandom(seed_bern);
      
      random = seed_bern%10001;
      //$display("Random bern: %d",random);	  
      
      bern_r <= (random > INJECTION_RATE || !out.ready) ? 1'b0 : 1'b1;

      pkts_to_send_r <= (!out.ready) ? 'd0 : pkts_to_send_next;
      
   end

   
   always_ff @(posedge clk) begin
      // defaults
      out.valid  = 1'b0;
      out.sop 	 = 1'b0;
      out.eop 	 = 1'b0;
      out.error  = 1'b0;
      out.empty  = 'b0;
      out.data 	 = 'b0;
      o_finished = 1'b0;
      send = 1'b1;
      pkts_to_send_next = pkts_to_send_r;
                        
      if (out.ready) begin
	 
	 eof = $feof(file);
	 
	 if (eof == 0) begin

	    if (packet_size == 0) begin

	       send = 1'b0;
	       if (bern_r || pkts_to_send_r > 0) begin
		  
		  send = 1'b1;
		  
		  if (!bern_r && pkts_to_send_r > 0)
		    pkts_to_send_next = pkts_to_send_r - 1;

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
	       
	    end

	    if (send == 1'b1) begin
	       
	       out.valid = 1'b1;
	       
	       if (bern_r)
		 pkts_to_send_next = pkts_to_send_r + 1;
	       
	       out.data[63*8+:8] <= packet_size > 0 ? $fgetc(file) : 8'b0;
	       out.data[62*8+:8] <= packet_size > 1 ? $fgetc(file) : 8'b0;
	       out.data[61*8+:8] <= packet_size > 2 ? $fgetc(file) : 8'b0;
	       out.data[60*8+:8] <= packet_size > 3 ? $fgetc(file) : 8'b0;
	       out.data[59*8+:8] <= packet_size > 4 ? $fgetc(file) : 8'b0;
	       out.data[58*8+:8] <= packet_size > 5 ? $fgetc(file) : 8'b0;
	       out.data[57*8+:8] <= packet_size > 6 ? $fgetc(file) : 8'b0;
	       out.data[56*8+:8] <= packet_size > 7 ? $fgetc(file) : 8'b0;
	       out.data[55*8+:8] <= packet_size > 8 ? $fgetc(file) : 8'b0;
	       out.data[54*8+:8] <= packet_size > 9 ? $fgetc(file) : 8'b0;
	       out.data[53*8+:8] <= packet_size > 10 ? $fgetc(file) : 8'b0;
	       out.data[52*8+:8] <= packet_size > 11 ? $fgetc(file) : 8'b0;
	       out.data[51*8+:8] <= packet_size > 12 ? $fgetc(file) : 8'b0;
	       out.data[50*8+:8] <= packet_size > 13 ? $fgetc(file) : 8'b0;
	       out.data[49*8+:8] <= packet_size > 14 ? $fgetc(file) : 8'b0;
	       out.data[48*8+:8] <= packet_size > 15 ? $fgetc(file) : 8'b0;
	       out.data[47*8+:8] <= packet_size > 16 ? $fgetc(file) : 8'b0;
	       out.data[46*8+:8] <= packet_size > 17 ? $fgetc(file) : 8'b0;
	       out.data[45*8+:8] <= packet_size > 18 ? $fgetc(file) : 8'b0;
	       out.data[44*8+:8] <= packet_size > 19 ? $fgetc(file) : 8'b0;
	       out.data[43*8+:8] <= packet_size > 20 ? $fgetc(file) : 8'b0;
	       out.data[42*8+:8] <= packet_size > 21 ? $fgetc(file) : 8'b0;
	       out.data[41*8+:8] <= packet_size > 22 ? $fgetc(file) : 8'b0;
	       out.data[40*8+:8] <= packet_size > 23 ? $fgetc(file) : 8'b0;
	       out.data[39*8+:8] <= packet_size > 24 ? $fgetc(file) : 8'b0;
	       out.data[38*8+:8] <= packet_size > 25 ? $fgetc(file) : 8'b0;
	       out.data[37*8+:8] <= packet_size > 26 ? $fgetc(file) : 8'b0;
	       out.data[36*8+:8] <= packet_size > 27 ? $fgetc(file) : 8'b0;
	       out.data[35*8+:8] <= packet_size > 28 ? $fgetc(file) : 8'b0;
	       out.data[34*8+:8] <= packet_size > 29 ? $fgetc(file) : 8'b0;
	       out.data[33*8+:8] <= packet_size > 30 ? $fgetc(file) : 8'b0;
	       out.data[32*8+:8] <= packet_size > 31 ? $fgetc(file) : 8'b0;
	       out.data[31*8+:8] <= packet_size > 32 ? $fgetc(file) : 8'b0;
	       out.data[30*8+:8] <= packet_size > 33 ? $fgetc(file) : 8'b0;
	       out.data[29*8+:8] <= packet_size > 34 ? $fgetc(file) : 8'b0;
	       out.data[28*8+:8] <= packet_size > 35 ? $fgetc(file) : 8'b0;
	       out.data[27*8+:8] <= packet_size > 36 ? $fgetc(file) : 8'b0;
	       out.data[26*8+:8] <= packet_size > 37 ? $fgetc(file) : 8'b0;
	       out.data[25*8+:8] <= packet_size > 38 ? $fgetc(file) : 8'b0;
	       out.data[24*8+:8] <= packet_size > 39 ? $fgetc(file) : 8'b0;
	       out.data[23*8+:8] <= packet_size > 40 ? $fgetc(file) : 8'b0;
	       out.data[22*8+:8] <= packet_size > 41 ? $fgetc(file) : 8'b0;
	       out.data[21*8+:8] <= packet_size > 42 ? $fgetc(file) : 8'b0;
	       out.data[20*8+:8] <= packet_size > 43 ? $fgetc(file) : 8'b0;
	       out.data[19*8+:8] <= packet_size > 44 ? $fgetc(file) : 8'b0;
	       out.data[18*8+:8] <= packet_size > 45 ? $fgetc(file) : 8'b0;
	       out.data[17*8+:8] <= packet_size > 46 ? $fgetc(file) : 8'b0;
	       out.data[16*8+:8] <= packet_size > 47 ? $fgetc(file) : 8'b0;
	       out.data[15*8+:8] <= packet_size > 48 ? $fgetc(file) : 8'b0;
	       out.data[14*8+:8] <= packet_size > 49 ? $fgetc(file) : 8'b0;
	       out.data[13*8+:8] <= packet_size > 50 ? $fgetc(file) : 8'b0;
	       out.data[12*8+:8] <= packet_size > 51 ? $fgetc(file) : 8'b0;
	       out.data[11*8+:8] <= packet_size > 52 ? $fgetc(file) : 8'b0;
	       out.data[10*8+:8] <= packet_size > 53 ? $fgetc(file) : 8'b0;
	       out.data[9*8+:8] <= packet_size > 54 ? $fgetc(file) : 8'b0;
	       out.data[8*8+:8] <= packet_size > 55 ? $fgetc(file) : 8'b0;
	       out.data[7*8+:8] <= packet_size > 56 ? $fgetc(file) : 8'b0;
	       out.data[6*8+:8] <= packet_size > 57 ? $fgetc(file) : 8'b0;
	       out.data[5*8+:8] <= packet_size > 58 ? $fgetc(file) : 8'b0;
	       out.data[4*8+:8] <= packet_size > 59 ? $fgetc(file) : 8'b0;
	       out.data[3*8+:8] <= packet_size > 60 ? $fgetc(file) : 8'b0;
	       out.data[2*8+:8] <= packet_size > 61 ? $fgetc(file) : 8'b0;
	       out.data[1*8+:8] <= packet_size > 62 ? $fgetc(file) : 8'b0;
	       out.data[0*8+:8] <= packet_size > 63 ? $fgetc(file) : 8'b0;
	       
	       out.empty = (packet_size > 63) ? 0 : 64 - packet_size;
	       packet_size = (packet_size > 63) ? packet_size - 64 : 0;

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

	    end // if (send == 1'b1)
	    
	 end // if (eof == 0)
	 else
	   o_finished = 1'b1;
	 

      end // if (out.ready)
      
   end // always_ff @

endmodule
