module switch_packetizer #
  (
   parameter DATA_WIDTH = 64,
   parameter ADDRESS_WIDTH = 4,
   parameter VC_ADDRESS_WIDTH = 1,
   parameter WIDTH_IN  = 142,
   parameter WIDTH_OUT = 600,
   parameter [VC_ADDRESS_WIDTH-1:0] ASSIGNED_VC = 0
   )
   (
    //input port
    input [WIDTH_IN-1:0]      i_data_in,
    input                     i_valid_in,
    input [ADDRESS_WIDTH-1:0] i_dest_in,
    output                    i_ready_out,
    
    //output port
    output [WIDTH_OUT-1:0] o_data_out,
    output                 o_valid_out,
    input                  o_ready_in
    );

   wire [DATA_WIDTH+3+1+1-1:0] eth_flit1_data, eth_flit2_data; // data + empty + error
   wire 		     eth_flit1_valid, eth_flit2_valid;
   wire 		     eth_flit1_sop, eth_flit2_sop;
   wire 		     eth_flit1_eop, eth_flit2_eop;
   
   assign eth_flit1_valid = i_data_in[WIDTH_IN-1];
   assign eth_flit1_sop = i_data_in[WIDTH_IN-2];
   assign eth_flit1_eop = i_data_in[WIDTH_IN-3];
   assign eth_flit1_data = {eth_flit1_eop,i_data_in[WIDTH_IN-4 -: DATA_WIDTH+3+1]};
   assign eth_flit2_valid = i_data_in[WIDTH_IN/2-1];
   assign eth_flit2_sop = i_data_in[WIDTH_IN/2-2];
   assign eth_flit2_eop = i_data_in[WIDTH_IN/2-3];
   assign eth_flit2_data = {eth_flit2_eop,i_data_in[WIDTH_IN/2-4:0]};

   always_comb
     if (eth_flit1_valid && eth_flit2_valid && eth_flit2_sop)
       $display("*******ERROR: Second flit is SOP!");

   always_comb
     if (eth_flit1_eop && eth_flit2_valid)
       $display("*******ERROR: Flit 2 valid when Flit 1 is EOP!");
      
   assign o_data_out[WIDTH_OUT-1 -: WIDTH_OUT/4] = {
						    (i_valid_in & eth_flit1_valid),
						    eth_flit1_sop,
						    (eth_flit1_eop || eth_flit2_eop),
						    ASSIGNED_VC,
						    i_dest_in,
						    {eth_flit1_data,eth_flit2_data},
						    {4{1'b0}}
						    };

   assign o_data_out [WIDTH_OUT-WIDTH_OUT/4-1:0] = 'b0;
      
   assign o_valid_out = i_valid_in;
   assign i_ready_out = o_ready_in;   


endmodule
