module ddr_top
  #(
    parameter DATA_WIDTH = 512+6,
    parameter PORT_WIDTH = 600,
    parameter NUM_VC = 2,
    parameter NOC_RADIX = 16
    )
   (
    input 		    clk,
    input 		    reset,

    // From NoC
    input [PORT_WIDTH-1:0]  i_data_in,
    input 		    i_valid_in,
    output 		    i_ready_out,

    // To NoC
    output [PORT_WIDTH-1:0] o_data_out,
    output 		    o_valid_out,
    input 		    o_ready_in

    );

   localparam AVL_ADDR_WIDTH = 29;
   localparam AVL_DATA_WIDTH = DATA_WIDTH;
   localparam AVL_BYTE_EN_WIDTH = AVL_DATA_WIDTH/8;
   localparam FRAME_ID_WIDTH = 4+28;   //4 bits for each port, and 14 bits for each frame 2^14 = 16384
   localparam BIN_ADDR_WIDTH = 8;      // how many frame buffers will we have
   localparam FRAME_OFFSET_WIDTH = 5;  // what is the maximum frame length in (4-flit) cycles?
                                   // the frame offset is log2 that value
   localparam WIDTH_PKT_IN = DATA_WIDTH+1+1+FRAME_ID_WIDTH; //this is the data width after the translator strips away the flit headers
   localparam WIDTH_PKT_OUT = DATA_WIDTH+FRAME_ID_WIDTH+1;
   
   localparam VC_ADDRESS_WIDTH = $clog2(NUM_VC);
   localparam ADDRESS_WIDTH = $clog2(NOC_RADIX);
   localparam NOC_ADDR_WIDTH = ADDRESS_WIDTH;

   // ddr ports
   wire [WIDTH_PKT_IN-1:0]      ddr_noc_data_in;
   wire [3:0] 		     ddr_noc_valid_in;
   wire 		     ddr_noc_ready_out;
   wire [3:0] 		     ddr_noc_sop_in;
   wire [3:0] 		     ddr_noc_eop_in;

   wire [WIDTH_PKT_OUT-1:0]      ddr_noc_data_out;
   wire [NOC_ADDR_WIDTH-1:0] ddr_noc_dest_out;
   wire [3:0] 		     ddr_noc_valid_out;
   wire 		     ddr_noc_ready_in;
   wire [3:0] 		     ddr_noc_sop_out;
   wire [3:0] 		     ddr_noc_eop_out;
   
   ethernet_frame_buffer 
     #(
       .AVL_ADDR_WIDTH(AVL_ADDR_WIDTH),
       .AVL_DATA_WIDTH(AVL_DATA_WIDTH),
       .AVL_BYTE_EN_WIDTH(AVL_BYTE_EN_WIDTH),
       .FRAME_ID_WIDTH(FRAME_ID_WIDTH),
       .BIN_ADDR_WIDTH(BIN_ADDR_WIDTH),
       .FRAME_OFFSET_WIDTH(FRAME_OFFSET_WIDTH),
       .NOC_ADDR_WIDTH(NOC_ADDR_WIDTH),
       .WIDTH_PKT_IN(WIDTH_PKT_IN),
       .WIDTH_PKT_OUT(WIDTH_PKT_OUT)) 
   fb_inst
     ( .clk(clk),
       .rst(reset),

       .top_noc_data_in  (ddr_noc_data_in), 
       .top_noc_valid_in (ddr_noc_valid_in),
       .top_noc_ready_out(ddr_noc_ready_out),
       .top_noc_sop_in   (ddr_noc_sop_in),
       .top_noc_eop_in   (ddr_noc_eop_in),
      
       .top_noc_data_out (ddr_noc_data_out), 
       .top_noc_dest_out (ddr_noc_dest_out), 
       .top_noc_valid_out(ddr_noc_valid_out),
       .top_noc_ready_in (ddr_noc_ready_in),
       .top_noc_sop_out  (ddr_noc_sop_out),
       .top_noc_eop_out  (ddr_noc_eop_out)
       );
   

   packetizer_sop
     #(
       .ADDRESS_WIDTH(ADDRESS_WIDTH),
       .VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
       .WIDTH_IN(WIDTH_PKT_OUT),
       .WIDTH_OUT(PORT_WIDTH),
       .ASSIGNED_VC()
       )
   ddr_pktizer
     (
      .i_data_in  (ddr_noc_data_out),
      .i_valid_in (ddr_noc_valid_out),
      .i_sop_in   (ddr_noc_sop_out),
      .i_eop_in   (ddr_noc_eop_out),
      .i_dest_in  (ddr_noc_dest_out),
      .i_ready_out(ddr_noc_ready_in),
      
      //which node are we connected to?
      .o_packet_out (o_data_out),
      .o_valid_out(o_valid_out),
      .o_ready_in (o_ready_in)
      );
   

   depacketizer_sop
     #(
       .ADDRESS_WIDTH(ADDRESS_WIDTH),
       .VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
       .WIDTH_PKT(PORT_WIDTH),
       .WIDTH_DATA(WIDTH_PKT_IN)
       )
   ddr_depktizer
     (
      .i_packet_in(i_data_in),
      .i_valid_in (i_valid_in),
      .i_ready_out(i_ready_out),

      .o_data_out (ddr_noc_data_in),
      .o_valid_out(ddr_noc_valid_in),
      .o_ready_in (ddr_noc_ready_out),
      .o_sop_out  (ddr_noc_sop_in),
      .o_eop_out  (ddr_noc_eop_in)
      );
   
endmodule
