module txr_to_noc_basic
  #(
    parameter DATA_WIDTH = 512,
    parameter NOC_WIDTH = 600,
    parameter FIFO_DEPTH = 32,
    parameter MAC_ADDRESS = 48'hA1B2C3D4E5F6,
    parameter MEM_DEPTH = 512,
    parameter NUM_VC = 2,
    parameter NOC_RADIX = 16,
    parameter PORT_ID = 2,
    parameter DEST = 4'd0,
    parameter MEM_WIDTH = $clog2(NOC_RADIX) + 1, // port # + valid bit
    parameter NUM_IPV4 = 4,
    parameter START_IPV4 = 0,
    parameter [$clog2(NOC_RADIX)-1:0] IPV4_DEST [0:NUM_IPV4-1] = '{4,9,6,11},
    parameter NUM_IPV6 = 1,
    parameter START_IPV6 = 0,
    parameter [$clog2(NOC_RADIX)-1:0] IPV6_DEST [0:NUM_IPV6-1] = '{10}
    )
   (
    input                  clk,
    input                  reset,
                           
    // From Txr
    avalonST.sink in,

    // To NoC
    output [NOC_WIDTH-1:0] o_data_out,
    output                 o_valid_out,
    input                  o_ready_in
    
    );

   avalonST #(.WIDTH(DATA_WIDTH)) pre2eth ();
   avalonST #(.WIDTH(DATA_WIDTH)) eth2trans ();

   logic [$clog2(NUM_VC)-1:0]     header_vc_id;
   logic [$clog2(NOC_RADIX)-1:0]  header_noc_dst;
   
   pre_process #(.DATA_WIDTH(DATA_WIDTH),
                 .FIFO_DEPTH(FIFO_DEPTH),
                 .NODE_ID(PORT_ID),
                 .NOC_RADIX(NOC_RADIX)) pre (.clk(clk),
                                             .reset(reset),
                                             .in(in),
                                             .out(pre2eth));

   ethernet512 #(.MAC_ADDRESS(MAC_ADDRESS),
                 .MEM_DEPTH(MEM_DEPTH),
                 .NUM_VC(NUM_VC),
                 .NOC_RADIX(NOC_RADIX),
                 .PORT_ID(PORT_ID),
                 .MEM_WIDTH(MEM_WIDTH),
		 .DEST(DEST),
		 .NUM_IPV4(NUM_IPV4),
		 .START_IPV4(START_IPV4),
		 .IPV4_DEST(IPV4_DEST),
		 .NUM_IPV6(NUM_IPV6),
		 .START_IPV6(START_IPV6),
		 .IPV6_DEST(IPV6_DEST)) ethernet (.clk(clk),
                                                  .reset(reset),
                                                  .in(pre2eth),
                                                  .out(eth2trans),
                                                  .o_vc_id(header_vc_id),
                                                  .o_noc_dst(header_noc_dst));

   

   translator_in #(.DATA_WIDTH(DATA_WIDTH),
                   .WIDTH_OUT(NOC_WIDTH),
                   .NUM_VC(NUM_VC),
                   .NOC_RADIX(NOC_RADIX)) translator (.in(eth2trans),
                                                      .i_dst_in(header_noc_dst),
                                                      .i_vc_in(1'b0),  // CHANGE ME
                                                      .i_pktid_in('b0),
                                                      .i_payload_in(1'b0),
                                                      .o_data_out(o_data_out),
                                                      .o_valid_out(o_valid_out),
                                                      .o_ready_in(o_ready_in));                                               
   
      
endmodule
