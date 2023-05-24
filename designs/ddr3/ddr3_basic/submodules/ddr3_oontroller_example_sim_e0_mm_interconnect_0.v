// ddr3_oontroller_example_sim_e0_mm_interconnect_0.v

// This file was auto-generated from altera_mm_interconnect_hw.tcl.  If you edit it your changes
// will probably be lost.
// 
// Generated using ACDS version 14.0 200 at 2015.03.04.21:56:01

`timescale 1 ps / 1 ps
module ddr3_oontroller_example_sim_e0_mm_interconnect_0 (
		input  wire         if0_afi_clk_clk,                                     //                                   if0_afi_clk.clk
		input  wire         d0_avl_reset_reset_bridge_in_reset_reset,            //            d0_avl_reset_reset_bridge_in_reset.reset
		input  wire         d0_avl_translator_reset_reset_bridge_in_reset_reset, // d0_avl_translator_reset_reset_bridge_in_reset.reset
		input  wire [28:0]  d0_avl_address,                                      //                                        d0_avl.address
		output wire         d0_avl_waitrequest,                                  //                                              .waitrequest
		input  wire [2:0]   d0_avl_burstcount,                                   //                                              .burstcount
		input  wire [63:0]  d0_avl_byteenable,                                   //                                              .byteenable
		input  wire         d0_avl_beginbursttransfer,                           //                                              .beginbursttransfer
		input  wire         d0_avl_read,                                         //                                              .read
		output wire [511:0] d0_avl_readdata,                                     //                                              .readdata
		output wire         d0_avl_readdatavalid,                                //                                              .readdatavalid
		input  wire         d0_avl_write,                                        //                                              .write
		input  wire [511:0] d0_avl_writedata,                                    //                                              .writedata
		output wire [22:0]  if0_avl_address,                                     //                                       if0_avl.address
		output wire         if0_avl_write,                                       //                                              .write
		output wire         if0_avl_read,                                        //                                              .read
		input  wire [511:0] if0_avl_readdata,                                    //                                              .readdata
		output wire [511:0] if0_avl_writedata,                                   //                                              .writedata
		output wire         if0_avl_beginbursttransfer,                          //                                              .beginbursttransfer
		output wire [2:0]   if0_avl_burstcount,                                  //                                              .burstcount
		output wire [63:0]  if0_avl_byteenable,                                  //                                              .byteenable
		input  wire         if0_avl_readdatavalid,                               //                                              .readdatavalid
		input  wire         if0_avl_waitrequest                                  //                                              .waitrequest
	);

	wire          d0_avl_translator_avalon_universal_master_0_waitrequest;   // if0_avl_translator:uav_waitrequest -> d0_avl_translator:uav_waitrequest
	wire    [8:0] d0_avl_translator_avalon_universal_master_0_burstcount;    // d0_avl_translator:uav_burstcount -> if0_avl_translator:uav_burstcount
	wire  [511:0] d0_avl_translator_avalon_universal_master_0_writedata;     // d0_avl_translator:uav_writedata -> if0_avl_translator:uav_writedata
	wire   [28:0] d0_avl_translator_avalon_universal_master_0_address;       // d0_avl_translator:uav_address -> if0_avl_translator:uav_address
	wire          d0_avl_translator_avalon_universal_master_0_lock;          // d0_avl_translator:uav_lock -> if0_avl_translator:uav_lock
	wire          d0_avl_translator_avalon_universal_master_0_write;         // d0_avl_translator:uav_write -> if0_avl_translator:uav_write
	wire          d0_avl_translator_avalon_universal_master_0_read;          // d0_avl_translator:uav_read -> if0_avl_translator:uav_read
	wire  [511:0] d0_avl_translator_avalon_universal_master_0_readdata;      // if0_avl_translator:uav_readdata -> d0_avl_translator:uav_readdata
	wire          d0_avl_translator_avalon_universal_master_0_debugaccess;   // d0_avl_translator:uav_debugaccess -> if0_avl_translator:uav_debugaccess
	wire   [63:0] d0_avl_translator_avalon_universal_master_0_byteenable;    // d0_avl_translator:uav_byteenable -> if0_avl_translator:uav_byteenable
	wire          d0_avl_translator_avalon_universal_master_0_readdatavalid; // if0_avl_translator:uav_readdatavalid -> d0_avl_translator:uav_readdatavalid

	altera_merlin_master_translator #(
		.AV_ADDRESS_W                (29),
		.AV_DATA_W                   (512),
		.AV_BURSTCOUNT_W             (3),
		.AV_BYTEENABLE_W             (64),
		.UAV_ADDRESS_W               (29),
		.UAV_BURSTCOUNT_W            (9),
		.USE_READ                    (1),
		.USE_WRITE                   (1),
		.USE_BEGINBURSTTRANSFER      (1),
		.USE_BEGINTRANSFER           (0),
		.USE_CHIPSELECT              (0),
		.USE_BURSTCOUNT              (1),
		.USE_READDATAVALID           (1),
		.USE_WAITREQUEST             (1),
		.USE_READRESPONSE            (0),
		.USE_WRITERESPONSE           (0),
		.AV_SYMBOLS_PER_WORD         (64),
		.AV_ADDRESS_SYMBOLS          (1),
		.AV_BURSTCOUNT_SYMBOLS       (0),
		.AV_CONSTANT_BURST_BEHAVIOR  (1),
		.UAV_CONSTANT_BURST_BEHAVIOR (0),
		.AV_LINEWRAPBURSTS           (0),
		.AV_REGISTERINCOMINGSIGNALS  (0)
	) d0_avl_translator (
		.clk                      (if0_afi_clk_clk),                                           //                       clk.clk
		.reset                    (d0_avl_translator_reset_reset_bridge_in_reset_reset),       //                     reset.reset
		.uav_address              (d0_avl_translator_avalon_universal_master_0_address),       // avalon_universal_master_0.address
		.uav_burstcount           (d0_avl_translator_avalon_universal_master_0_burstcount),    //                          .burstcount
		.uav_read                 (d0_avl_translator_avalon_universal_master_0_read),          //                          .read
		.uav_write                (d0_avl_translator_avalon_universal_master_0_write),         //                          .write
		.uav_waitrequest          (d0_avl_translator_avalon_universal_master_0_waitrequest),   //                          .waitrequest
		.uav_readdatavalid        (d0_avl_translator_avalon_universal_master_0_readdatavalid), //                          .readdatavalid
		.uav_byteenable           (d0_avl_translator_avalon_universal_master_0_byteenable),    //                          .byteenable
		.uav_readdata             (d0_avl_translator_avalon_universal_master_0_readdata),      //                          .readdata
		.uav_writedata            (d0_avl_translator_avalon_universal_master_0_writedata),     //                          .writedata
		.uav_lock                 (d0_avl_translator_avalon_universal_master_0_lock),          //                          .lock
		.uav_debugaccess          (d0_avl_translator_avalon_universal_master_0_debugaccess),   //                          .debugaccess
		.av_address               (d0_avl_address),                                            //      avalon_anti_master_0.address
		.av_waitrequest           (d0_avl_waitrequest),                                        //                          .waitrequest
		.av_burstcount            (d0_avl_burstcount),                                         //                          .burstcount
		.av_byteenable            (d0_avl_byteenable),                                         //                          .byteenable
		.av_beginbursttransfer    (d0_avl_beginbursttransfer),                                 //                          .beginbursttransfer
		.av_read                  (d0_avl_read),                                               //                          .read
		.av_readdata              (d0_avl_readdata),                                           //                          .readdata
		.av_readdatavalid         (d0_avl_readdatavalid),                                      //                          .readdatavalid
		.av_write                 (d0_avl_write),                                              //                          .write
		.av_writedata             (d0_avl_writedata),                                          //                          .writedata
		.av_begintransfer         (1'b0),                                                      //               (terminated)
		.av_chipselect            (1'b0),                                                      //               (terminated)
		.av_lock                  (1'b0),                                                      //               (terminated)
		.av_debugaccess           (1'b0),                                                      //               (terminated)
		.uav_clken                (),                                                          //               (terminated)
		.av_clken                 (1'b1),                                                      //               (terminated)
		.uav_response             (2'b00),                                                     //               (terminated)
		.av_response              (),                                                          //               (terminated)
		.uav_writeresponserequest (),                                                          //               (terminated)
		.uav_writeresponsevalid   (1'b0),                                                      //               (terminated)
		.av_writeresponserequest  (1'b0),                                                      //               (terminated)
		.av_writeresponsevalid    ()                                                           //               (terminated)
	);

	altera_merlin_slave_translator #(
		.AV_ADDRESS_W                   (23),
		.AV_DATA_W                      (512),
		.UAV_DATA_W                     (512),
		.AV_BURSTCOUNT_W                (3),
		.AV_BYTEENABLE_W                (64),
		.UAV_BYTEENABLE_W               (64),
		.UAV_ADDRESS_W                  (29),
		.UAV_BURSTCOUNT_W               (9),
		.AV_READLATENCY                 (0),
		.USE_READDATAVALID              (1),
		.USE_WAITREQUEST                (1),
		.USE_UAV_CLKEN                  (0),
		.USE_READRESPONSE               (0),
		.USE_WRITERESPONSE              (0),
		.AV_SYMBOLS_PER_WORD            (64),
		.AV_ADDRESS_SYMBOLS             (0),
		.AV_BURSTCOUNT_SYMBOLS          (0),
		.AV_CONSTANT_BURST_BEHAVIOR     (0),
		.UAV_CONSTANT_BURST_BEHAVIOR    (0),
		.AV_REQUIRE_UNALIGNED_ADDRESSES (0),
		.CHIPSELECT_THROUGH_READLATENCY (0),
		.AV_READ_WAIT_CYCLES            (1),
		.AV_WRITE_WAIT_CYCLES           (0),
		.AV_SETUP_WAIT_CYCLES           (0),
		.AV_DATA_HOLD_CYCLES            (0)
	) if0_avl_translator (
		.clk                      (if0_afi_clk_clk),                                           //                      clk.clk
		.reset                    (d0_avl_translator_reset_reset_bridge_in_reset_reset),       //                    reset.reset
		.uav_address              (d0_avl_translator_avalon_universal_master_0_address),       // avalon_universal_slave_0.address
		.uav_burstcount           (d0_avl_translator_avalon_universal_master_0_burstcount),    //                         .burstcount
		.uav_read                 (d0_avl_translator_avalon_universal_master_0_read),          //                         .read
		.uav_write                (d0_avl_translator_avalon_universal_master_0_write),         //                         .write
		.uav_waitrequest          (d0_avl_translator_avalon_universal_master_0_waitrequest),   //                         .waitrequest
		.uav_readdatavalid        (d0_avl_translator_avalon_universal_master_0_readdatavalid), //                         .readdatavalid
		.uav_byteenable           (d0_avl_translator_avalon_universal_master_0_byteenable),    //                         .byteenable
		.uav_readdata             (d0_avl_translator_avalon_universal_master_0_readdata),      //                         .readdata
		.uav_writedata            (d0_avl_translator_avalon_universal_master_0_writedata),     //                         .writedata
		.uav_lock                 (d0_avl_translator_avalon_universal_master_0_lock),          //                         .lock
		.uav_debugaccess          (d0_avl_translator_avalon_universal_master_0_debugaccess),   //                         .debugaccess
		.av_address               (if0_avl_address),                                           //      avalon_anti_slave_0.address
		.av_write                 (if0_avl_write),                                             //                         .write
		.av_read                  (if0_avl_read),                                              //                         .read
		.av_readdata              (if0_avl_readdata),                                          //                         .readdata
		.av_writedata             (if0_avl_writedata),                                         //                         .writedata
		.av_beginbursttransfer    (if0_avl_beginbursttransfer),                                //                         .beginbursttransfer
		.av_burstcount            (if0_avl_burstcount),                                        //                         .burstcount
		.av_byteenable            (if0_avl_byteenable),                                        //                         .byteenable
		.av_readdatavalid         (if0_avl_readdatavalid),                                     //                         .readdatavalid
		.av_waitrequest           (if0_avl_waitrequest),                                       //                         .waitrequest
		.av_begintransfer         (),                                                          //              (terminated)
		.av_writebyteenable       (),                                                          //              (terminated)
		.av_lock                  (),                                                          //              (terminated)
		.av_chipselect            (),                                                          //              (terminated)
		.av_clken                 (),                                                          //              (terminated)
		.uav_clken                (1'b0),                                                      //              (terminated)
		.av_debugaccess           (),                                                          //              (terminated)
		.av_outputenable          (),                                                          //              (terminated)
		.uav_response             (),                                                          //              (terminated)
		.av_response              (2'b00),                                                     //              (terminated)
		.uav_writeresponserequest (1'b0),                                                      //              (terminated)
		.uav_writeresponsevalid   (),                                                          //              (terminated)
		.av_writeresponserequest  (),                                                          //              (terminated)
		.av_writeresponsevalid    (1'b0)                                                       //              (terminated)
	);

endmodule
