module ibuffer #
  (
   parameter PACKET_WIDTH = 142,
   parameter DATA_WIDTH = 64,
   parameter DEST_WIDTH = 4
   )
   (
    input 		      clk,
    input 		      reset,

    input 		      i_valid,
    input 		      i_sop,
    input 		      i_eop,
    input [DATA_WIDTH-1:0]    i_data,
    input [2:0] 	      i_empty,
    input 		      i_error,
    output 		      o_ready,

    output 		      o_valid,
    output [PACKET_WIDTH-1:0] o_data,
    output [DEST_WIDTH-1:0]   o_dest,
    input 		      i_ready

    );
   

   logic [PACKET_WIDTH-1:0] fifo_in_data;
   wire [PACKET_WIDTH-1:0]  fifo_out_data; 
   wire 		    empty;
   wire 		    full;
   logic 		    wrreq;

   localparam HALF_PACKET = PACKET_WIDTH/2;
      
   logic [HALF_PACKET-1:0]    half_pkt_r, half_pkt_next;
   logic 		      valid_r,valid_next;
      
   
   fifo144 fifo (.clock(clk),
		 .sclr(reset),
		 .rdreq(i_ready&&!empty),
		 .wrreq(wrreq&&!full),
		 .full(full),
		 .empty(empty),
		 .data(fifo_in_data),
		 .q(fifo_out_data));


   always_ff @(posedge clk or posedge reset) half_pkt_r = (reset) ? 'b0 : half_pkt_next;
   always_ff @(posedge clk or posedge reset) valid_r = (reset) ? 'b0 : valid_next;

   always_comb valid_next = i_ready&&!empty;   
   
   always_comb begin
      // Defaults
      wrreq 	     = 1'b0;
      half_pkt_next  = 'b0;
      fifo_in_data   = 'b0;
                  
      if (half_pkt_r[HALF_PACKET-1]) begin

	 if (i_valid && !full) begin
	    wrreq = 1'b1;
	    fifo_in_data = {half_pkt_r,i_valid,i_sop,i_eop,i_empty,i_error,i_data};
	 end
	 else
	   half_pkt_next = half_pkt_r;
	 
      end
      else begin

	 if (i_valid) begin
	   if (i_eop) begin
	      wrreq = 1'b1;
	      fifo_in_data = {i_valid,i_sop,i_eop,i_empty,i_error,i_data,{HALF_PACKET{1'b0}}};
	   end
	   else
	     half_pkt_next = {i_valid,i_sop,i_eop,i_empty,i_error,i_data};
	 end
	 
      end
      
   end
   
   assign o_ready = !full;
   assign o_valid = valid_r;
   assign o_data  = fifo_out_data[PACKET_WIDTH-1:0];
   assign o_dest  = fifo_out_data[PACKET_WIDTH-8 -: DEST_WIDTH];

         
endmodule
