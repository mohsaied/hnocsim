`timescale 1ps/1ps

module testbench();

   parameter WIDTH = 12144; //bits (1518 bytes)
   parameter N = 16;
   parameter NUM_CYCLES = 10000;
   parameter SEED = 1;
      
   logic clk;
       
   logic [31:0] port_node_map_next [0:N-1];
   logic [31:0] port_node_map_r [0:N-1];
   
   int 	 i;

   wire [WIDTH-1:0] data_gen2i [0:N-1];
   wire 	    valid_gen2i [0:N-1];
   wire [7:0]	    dest_gen2i [0:N-1];
   wire [15:0] 	    pktsize_gen2i [0:N-1];
   
   wire [WIDTH-1:0] data_i2mon [0:N-1];
   wire 	    valid_i2mon [0:N-1];

   
   gen #(.WIDTH(WIDTH),
	 .N(N),
	 .SEED(SEED)) gen (.clk(clk),
			   .reset(1'b0),
			   .o_valid(valid_gen2i),
			   .o_data(data_gen2i),
			   .o_dest(dest_gen2i),
			   .o_pktsize(pktsize_gen2i));
   
   rtl_interface #(.WIDTH(WIDTH),
		   .N(N),
		   .NUM_CYCLES(NUM_CYCLES)) rtl_interface (.clk(clk),
							   .reset(1'b0),
							   .port_node_map(port_node_map_r),
							   .i_valid(valid_gen2i),
							   .i_dest(dest_gen2i),
							   .i_pktsize(pktsize_gen2i),
							   .i_data(data_gen2i),
							   .o_valid(valid_i2mon),
							   .o_data(data_i2mon));  

   // generate clock
   initial clk = 1'b1;
   always #2500 clk = ~clk; // 200 MHz clock


   always_comb begin

      // Two-sided port-node map
      port_node_map_next[0] = 32'd0;
      port_node_map_next[1] = 32'd1;
      port_node_map_next[2] = 32'd2;
      port_node_map_next[3] = 32'd3;
      port_node_map_next[4] = 32'd4;
      port_node_map_next[5] = 32'd5;
      port_node_map_next[6] = 32'd6;
      port_node_map_next[7] = 32'd7;
      port_node_map_next[8] = 32'd56;
      port_node_map_next[9] = 32'd57;
      port_node_map_next[10] = 32'd58;
      port_node_map_next[11] = 32'd59;
      port_node_map_next[12] = 32'd60;
      port_node_map_next[13] = 32'd61;
      port_node_map_next[14] = 32'd62;
      port_node_map_next[15] = 32'd63;
      
   end

   always_ff @(posedge clk) begin

      for (i=0; i<N; i=i+1)
	port_node_map_r[i] <= port_node_map_next[i];
      
   end

   
   
   

endmodule



   

   