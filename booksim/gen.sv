module gen #
  (
   parameter WIDTH = 12144,
   parameter N = 16,
   parameter SEED = 1
   )
   (
    input 		     clk,
    input 		     reset,

    output logic 	     o_valid [0:N-1],
    output logic [WIDTH-1:0] o_data [0:N-1],
    output logic [7:0] 	     o_dest [0:N-1],
    output logic [15:0]      o_pktsize [0:N-1]

    );

   logic 		     valid_r [0:N-1];
   logic 		     valid_next [0:N-1];
   logic [WIDTH-1:0] 	     data_r [0:N-1];
   logic [WIDTH-1:0] 	     data_next [0:N-1];
   logic [7:0] 		     dest_r [0:N-1];
   logic [7:0] 		     dest_next [0:N-1];
   logic [15:0] 	     pktsize_r [0:N-1];
   logic [15:0] 	     pktsize_next [0:N-1];

   int 			     i;
   int 			     j;
   int 			     k;
   int 			     cycle_count;
      
   initial begin
      cycle_count = 0;
      $srandom(SEED);
   end

   always_ff @(posedge clk or posedge reset) begin

      if (reset) begin

	 for (k=0;k<N;k=k+1) begin
	    valid_r[k]   <= 0;
	    data_r[k]    <= 0;
	    dest_r[k]    <= 0;
	    pktsize_r[k] <= 0;
	 end

	 cycle_count = 0;
	 
      end
      else begin

	 for (k=0;k<N;k=k+1) begin
	    valid_r[k]   <= valid_next[k];
	    data_r[k]    <= data_next[k];
	    dest_r[k]    <= dest_next[k];
	    pktsize_r[k] <= pktsize_next[k];
	 end

	 cycle_count = cycle_count + 1;
	 	 
      end

   end


   always @(negedge clk) begin

      //outputs
      for (i=0;i<N;i=i+1) begin
	 o_valid[i] = valid_r[i];
	 o_data[i] = data_r[i];
	 o_dest[i] = dest_r[i];
	 o_pktsize[i] = pktsize_r[i];
      end
      
      //defaults
      for (i=0;i<N;i=i+1) begin
	 valid_next[i] = valid_r[i];
	 data_next[i] = data_r[i];
	 dest_next[i] = dest_r[i];
	 pktsize_next[i] = pktsize_r[i];
      end

      for (i=0;i<N;i=i+1) begin

	 if ($urandom_range(10000,0) < 24) begin // injection rate
	    valid_next[i] = 1'b1;
	    dest_next[i] = $urandom_range(N-1,0);
	    //pktsize_next[i] = $urandom_range(12144,512);
	    //pktsize_next[i] = $urandom_range(1518,64); // in bytes?
	    pktsize_next[i] = $urandom_range(640,512);
	    for (j=0;j<WIDTH;j=j+1) begin
	       data_next[i][j] = $urandom;
	    end
	    
	    $display("Injecting at node %d, to node %d. Pkt size = %d. (Cycle=%d)",i,dest_next[i],pktsize_next[i],cycle_count);
	 end // if ($urandom_range(10000,0) < 1688)
	 else begin
	    valid_next[i] = 1'b0;
	 end

      end

   end

   
endmodule
   