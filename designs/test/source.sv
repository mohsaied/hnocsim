
module source #
  (
   parameter DATA_WIDTH = 500,
   parameter DEST_WIDTH = 4,
   parameter DEST = 1
   )
   (
    input 		    clk,
    input 		    reset,

    output [DATA_WIDTH-1:0] pkt_data_out,
    output [DEST_WIDTH-1:0] pkt_dest_out,
    output 		    pkt_valid_out,

    input 		    pkt_ready_in
    );


   logic [DATA_WIDTH-1:0]   data_r, data_next;
   logic [DEST_WIDTH-1:0]   dest_r, dest_next;
   logic 		    valid_r, valid_next;
   logic [31:0] 	    id_r, id_next;
   


   always_ff @(posedge clk or posedge reset) begin
      
      data_r  <= (reset) ? 'b0 : data_next;
      dest_r  <= (reset) ? 'b0 : dest_next;
      valid_r <= (reset) ? 'b0 : valid_next;
      id_r    <= (reset) ? 'b0 : id_next;
      
   end

   always_comb begin
      // Defaults
      data_next   = data_r;
      dest_next   = dest_r;
      valid_next  = valid_r;
      id_next 	  = id_r;
                  
      if (pkt_ready_in) begin

	 valid_next 		      = 1'b1;
	 dest_next 		      = DEST;
	 data_next[DATA_WIDTH-1 -: 32]  = id_r;
	 id_next 		      = id_r + 1;
	 	 	 
      end
      else
	valid_next = 1'b0;
      
   end

   assign pkt_data_out  = data_r;
   assign pkt_dest_out 	= dest_r;
   assign pkt_valid_out = valid_r;
   
   
endmodule
    
		    
