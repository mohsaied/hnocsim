/*
 * function : aggregates flits+control into single output; designer specifies head/tail/valid flits
 * author   : Andrew E. Bitar
 * date     : 15-SEP-2014
 */

module flit_aggregator #
  (
   parameter DATA_WIDTH = 128,
   parameter ADDRESS_WIDTH = 4,
   parameter VC_ADDRESS_WIDTH = 1,
   parameter NOC_SPEEDUP = 4,
   parameter [VC_ADDRESS_WIDTH-1:0] ASSIGNED_VC = 0
   )
   (
    input [DATA_WIDTH-1:0] 	 i_data_in [0:NOC_SPEEDUP-1],
    input [VC_ADDRESS_WIDTH-1:0] i_validfl_in [0:NOC_SPEEDUP-1],
    input 			 i_headfl_in [0:NOC_SPEEDUP-1],
    input 			 i_tailfl_in [0:NOC_SPEEDUP-1],
    
    input [ADDRESS_WIDTH-1:0] 	 i_dest_in [0:NOC_SPEEDUP-1],
    output 			 o_ready_in, 
    input 			 i_ready_out,

    input [ADDRESS_WIDTH-1:0] 	 i_extra_in [0:NOC_SPEEDUP-1];

    output [NOC_SPEEDUP*
    (DATA_WIDTH+
    ADDRESS_WIDTH+
    VC_ADDRESS_WIDTH+
    3) // VALID+HEAD+TAIL
    -1:0] 			 o_data_out
    );


   logic [$clog2(NOC_SPEEDUP)-1:0] 				     i;
   logic [DATA_WIDTH+ADDRESS_WIDTH+VC_ADDRESS_WIDTH+3-1:0] 	     flit;

   localparam VALID_BIT = DATA_WIDTH+ADDRESS_WIDTH+VC_ADDRESS_WIDTH+3-1;
   localparam HEAD_BIT = DATA_WIDTH+ADDRESS_WIDTH+VC_ADDRESS_WIDTH+2-1;
   localparam TAIL_BIT = DATA_WIDTH+ADDRESS_WIDTH+VC_ADDRESS_WIDTH+1-1;
   localparam VC_START = DATA_WIDTH+ADDRESS_WIDTH+VC_ADDRESS_WIDTH-1;
   localparam VC_END = DATA_WIDTH+ADDRESS_WIDTH;
   localparam DEST_START = DATA_WIDTH+ADDRESS_WIDTH-1;
   localparam DEST_END = DATA_WIDTH;
   localparam EXTRA_START = ADDRESS_WIDTH-1;
   localparam EXTRA_END = 0;
         
   always_comb begin

      for (i=0;i<NOC_SPEEDUP;i++) begin

	 flit[VALID_BIT] = i_validfl_in[i];
	 flit[HEAD_BIT]  = i_headfl_in[i];
	 flit[TAIL_BIT]  = i_tailfl_in[i];
	 flit[VC_START:VC_END] = ASSIGNED_VC;

	 if (i_headfl_in[i]) begin
	    flit[DEST_START:DEST_END] = i_dest_in[i];
	    flit[DEST_END-1:0] = i_data_in[i];
	 end
	 else begin
	    flit[DEST_START:EXTRA_START+1] = i_data_in[i];
	    flit[EXTRA_START:EXTRA_END] = i_extra_in[i];
	 end
	 	 

      end

   end

   assign o_ready_in = i_ready_out;
   

endmodule
    
    
