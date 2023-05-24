// ddr3_oontroller_example_sim_e0.v

// This file was auto-generated from alt_mem_if_ddr3_tg_ed_hw.tcl.  If you edit it your changes
// will probably be lost.
// 
// Generated using ACDS version 14.0 200 at 2015.03.04.21:56:00

`timescale 1 ps / 1 ps
module ddr3_top (
        output wire        e0_afi_clk_clk,                // avl_clock.clk
		output wire        e0_afi_reset_reset,            // avl_reset.reset_n
		input  wire        e0_drv_status_pass,            //    status.pass
		input  wire        e0_drv_status_fail,            //          .fail
		input  wire        e0_drv_status_test_complete,   //          .test_complete
		output wire        d0_avl_waitrequest,            //       avl.waitrequest_n
		input  wire [28:0] d0_avl_address,                //          .address
		input  wire [2:0]  d0_avl_burstcount,             //          .burstcount
		input  wire [511:0] d0_avl_writedata,             //          .writedata
		output wire [511:0] d0_avl_readdata,              //          .readdata
		input  wire        d0_avl_write,                  //          .write
		input  wire        d0_avl_read,                   //          .read
		output wire        d0_avl_readdatavalid,          //          .readdatavalid
		input  wire [63:0]  d0_avl_byteenable,            //          .byteenable
		input  wire        d0_avl_beginbursttransfer      //          .beginbursttransfer
	);

    
    wire d0_avl_ready;
    assign d0_avl_waitrequest = ~d0_avl_ready;

    wire         pll_ref_clk_clk_clk;                  // pll_ref_clk:clk -> [e0:pll_ref_clk, global_reset:clk]
	wire         global_reset_reset_reset;         // global_reset:reset -> [e0:global_reset_n, e0:soft_reset_n]
	wire         e0_emif_status_local_cal_fail;    // e0:local_cal_fail -> t0:local_cal_fail
	wire         e0_emif_status_local_cal_success; // e0:local_cal_success -> t0:local_cal_success
	wire         e0_emif_status_local_init_done;   // e0:local_init_done -> t0:local_init_done
	wire   [0:0] e0_memory_mem_odt;                // e0:mem_odt -> m0:mem_odt
	wire   [0:0] e0_memory_mem_cs_n;               // e0:mem_cs_n -> m0:mem_cs_n
	wire  [12:0] e0_memory_mem_a;                  // e0:mem_a -> m0:mem_a
	wire   [0:0] e0_memory_mem_ck_n;               // e0:mem_ck_n -> m0:mem_ck_n
	wire   [0:0] e0_memory_mem_ras_n;              // e0:mem_ras_n -> m0:mem_ras_n
	wire   [0:0] e0_memory_mem_cke;                // e0:mem_cke -> m0:mem_cke
	wire   [7:0] e0_memory_mem_dqs;                // [] -> [e0:mem_dqs, m0:mem_dqs]
	wire   [0:0] e0_memory_mem_we_n;               // e0:mem_we_n -> m0:mem_we_n
	wire   [2:0] e0_memory_mem_ba;                 // e0:mem_ba -> m0:mem_ba
	wire  [63:0] e0_memory_mem_dq;                 // [] -> [e0:mem_dq, m0:mem_dq]
	wire   [0:0] e0_memory_mem_ck;                 // e0:mem_ck -> m0:mem_ck
	wire         e0_memory_mem_reset_n;            // e0:mem_reset_n -> m0:mem_reset_n
	wire   [7:0] e0_memory_mem_dm;                 // e0:mem_dm -> m0:mem_dm
	wire   [0:0] e0_memory_mem_cas_n;              // e0:mem_cas_n -> m0:mem_cas_n
	wire   [7:0] e0_memory_mem_dqs_n;              // [] -> [e0:mem_dqs_n, m0:mem_dqs_n]
	wire          rst_controller_reset_out_reset;               // rst_controller:reset_out -> [mm_interconnect_0:d0_avl_reset_reset_bridge_in_reset_reset, mm_interconnect_0:d0_avl_translator_reset_reset_bridge_in_reset_reset]

	altera_avalon_clock_source #(
		.CLOCK_RATE (100000000),
		.CLOCK_UNIT (1)
	) pll_ref_clk (
		.clk (pll_ref_clk_clk_clk)  // clk.clk
	);

	altera_avalon_reset_source #(
		.ASSERT_HIGH_RESET    (0),
		.INITIAL_RESET_CYCLES (5)
	) global_reset (
		.reset (global_reset_reset_reset), // reset.reset_n
		.clk   (pll_ref_clk_clk_clk)       //   clk.clk
	);
    

	ddr3_oontroller_example_sim_e0_if0 if0 (
		.pll_ref_clk               (pll_ref_clk_clk_clk),                          //      pll_ref_clk.clk
		.global_reset_n            (global_reset_reset_reset),                     //     global_reset.reset_n
		.soft_reset_n              (global_reset_reset_reset),                     //       soft_reset.reset_n
		.afi_clk                   (e0_afi_clk_clk),                               //          afi_clk.clk
		.afi_half_clk              (),                                             //     afi_half_clk.clk
		.afi_reset_n               (e0_afi_reset_reset),                           //        afi_reset.reset_n
		.afi_reset_export_n        (),                                             // afi_reset_export.reset_n
		.mem_a                     (e0_memory_mem_a),                              //           memory.mem_a
		.mem_ba                    (e0_memory_mem_ba),                             //                 .mem_ba
		.mem_ck                    (e0_memory_mem_ck),                             //                 .mem_ck
		.mem_ck_n                  (e0_memory_mem_ck_n),                           //                 .mem_ck_n
		.mem_cke                   (e0_memory_mem_cke),                            //                 .mem_cke
		.mem_cs_n                  (e0_memory_mem_cs_n),                           //                 .mem_cs_n
		.mem_dm                    (e0_memory_mem_dm),                             //                 .mem_dm
		.mem_ras_n                 (e0_memory_mem_ras_n),                          //                 .mem_ras_n
		.mem_cas_n                 (e0_memory_mem_cas_n),                          //                 .mem_cas_n
		.mem_we_n                  (e0_memory_mem_we_n),                           //                 .mem_we_n
		.mem_reset_n               (e0_memory_mem_reset_n),                        //                 .mem_reset_n
		.mem_dq                    (e0_memory_mem_dq),                             //                 .mem_dq
		.mem_dqs                   (e0_memory_mem_dqs),                            //                 .mem_dqs
		.mem_dqs_n                 (e0_memory_mem_dqs_n),                          //                 .mem_dqs_n
		.mem_odt                   (e0_memory_mem_odt),                            //                 .mem_odt
		.avl_ready                 (d0_avl_ready),                                 //              avl.waitrequest_n
		.avl_burstbegin            (d0_avl_beginbursttransfer), //                 .beginbursttransfer
		.avl_addr                  (d0_avl_address),            //                 .address
		.avl_rdata_valid           (d0_avl_readdatavalid),      //                 .readdatavalid
		.avl_rdata                 (d0_avl_readdata),           //                 .readdata
		.avl_wdata                 (d0_avl_writedata),          //                 .writedata
		.avl_be                    (d0_avl_byteenable),         //                 .byteenable
		.avl_read_req              (d0_avl_read),               //                 .read
		.avl_write_req             (d0_avl_write),              //                 .write
		.avl_size                  (d0_avl_burstcount),         //                 .burstcount
		.local_init_done           (e0_emif_status_local_init_done),               //           status.local_init_done
		.local_cal_success         (e0_emif_status_local_cal_success),             //                 .local_cal_success
		.local_cal_fail            (e0_emif_status_local_cal_fail),                //                 .local_cal_fail
		.oct_rzqin                 (),                                             //              oct.rzqin
		.pll_mem_clk               (),                                             //      pll_sharing.pll_mem_clk
		.pll_write_clk             (),                                             //                 .pll_write_clk
		.pll_locked                (),                                             //                 .pll_locked
		.pll_write_clk_pre_phy_clk (),                                             //                 .pll_write_clk_pre_phy_clk
		.pll_addr_cmd_clk          (),                                             //                 .pll_addr_cmd_clk
		.pll_avl_clk               (),                                             //                 .pll_avl_clk
		.pll_config_clk            (),                                             //                 .pll_config_clk
		.pll_p2c_read_clk          (),                                             //                 .pll_p2c_read_clk
		.pll_c2p_write_clk         ()                                              //                 .pll_c2p_write_clk
	);


	altera_reset_controller #(
		.NUM_RESET_INPUTS          (1),
		.OUTPUT_RESET_SYNC_EDGES   ("deassert"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller (
		.reset_in0      (~e0_afi_reset_reset),            // reset_in0.reset
		.clk            (e0_afi_clk_clk),                 //       clk.clk
		.reset_out      (rst_controller_reset_out_reset), // reset_out.reset
		.reset_req      (),                               // (terminated)
		.reset_req_in0  (1'b0),                           // (terminated)
		.reset_in1      (1'b0),                           // (terminated)
		.reset_req_in1  (1'b0),                           // (terminated)
		.reset_in2      (1'b0),                           // (terminated)
		.reset_req_in2  (1'b0),                           // (terminated)
		.reset_in3      (1'b0),                           // (terminated)
		.reset_req_in3  (1'b0),                           // (terminated)
		.reset_in4      (1'b0),                           // (terminated)
		.reset_req_in4  (1'b0),                           // (terminated)
		.reset_in5      (1'b0),                           // (terminated)
		.reset_req_in5  (1'b0),                           // (terminated)
		.reset_in6      (1'b0),                           // (terminated)
		.reset_req_in6  (1'b0),                           // (terminated)
		.reset_in7      (1'b0),                           // (terminated)
		.reset_req_in7  (1'b0),                           // (terminated)
		.reset_in8      (1'b0),                           // (terminated)
		.reset_req_in8  (1'b0),                           // (terminated)
		.reset_in9      (1'b0),                           // (terminated)
		.reset_req_in9  (1'b0),                           // (terminated)
		.reset_in10     (1'b0),                           // (terminated)
		.reset_req_in10 (1'b0),                           // (terminated)
		.reset_in11     (1'b0),                           // (terminated)
		.reset_req_in11 (1'b0),                           // (terminated)
		.reset_in12     (1'b0),                           // (terminated)
		.reset_req_in12 (1'b0),                           // (terminated)
		.reset_in13     (1'b0),                           // (terminated)
		.reset_req_in13 (1'b0),                           // (terminated)
		.reset_in14     (1'b0),                           // (terminated)
		.reset_req_in14 (1'b0),                           // (terminated)
		.reset_in15     (1'b0),                           // (terminated)
		.reset_req_in15 (1'b0)                            // (terminated)
	);

	altera_mem_if_checker_no_ifdef_params #(
		.ENABLE_VCDPLUS          (0),
		.CONTINUE_AFTER_CAL_FAIL (0)
	) t0 (
		.clk                  (e0_afi_clk_clk),                   //   avl_clock.clk
		.reset_n              (e0_afi_reset_reset),               //   avl_reset.reset_n
		.test_complete        (e0_drv_status_test_complete),      //  drv_status.test_complete
		.fail                 (e0_drv_status_fail),               //            .fail
		.pass                 (e0_drv_status_pass),               //            .pass
		.local_init_done      (e0_emif_status_local_init_done),   // emif_status.local_init_done
		.local_cal_success    (e0_emif_status_local_cal_success), //            .local_cal_success
		.local_cal_fail       (e0_emif_status_local_cal_fail),    //            .local_cal_fail
		.test_complete_1      (1'b1),                             // (terminated)
		.fail_1               (1'b0),                             // (terminated)
		.pass_1               (1'b1),                             // (terminated)
		.local_init_done_1    (1'b1),                             // (terminated)
		.local_cal_success_1  (1'b1),                             // (terminated)
		.local_cal_fail_1     (1'b0),                             // (terminated)
		.test_complete_2      (1'b1),                             // (terminated)
		.fail_2               (1'b0),                             // (terminated)
		.pass_2               (1'b1),                             // (terminated)
		.local_init_done_2    (1'b1),                             // (terminated)
		.local_cal_success_2  (1'b1),                             // (terminated)
		.local_cal_fail_2     (1'b0),                             // (terminated)
		.test_complete_3      (1'b1),                             // (terminated)
		.fail_3               (1'b0),                             // (terminated)
		.pass_3               (1'b1),                             // (terminated)
		.local_init_done_3    (1'b1),                             // (terminated)
		.local_cal_success_3  (1'b1),                             // (terminated)
		.local_cal_fail_3     (1'b0),                             // (terminated)
		.test_complete_4      (1'b1),                             // (terminated)
		.fail_4               (1'b0),                             // (terminated)
		.pass_4               (1'b1),                             // (terminated)
		.local_init_done_4    (1'b1),                             // (terminated)
		.local_cal_success_4  (1'b1),                             // (terminated)
		.local_cal_fail_4     (1'b0),                             // (terminated)
		.test_complete_5      (1'b1),                             // (terminated)
		.fail_5               (1'b0),                             // (terminated)
		.pass_5               (1'b1),                             // (terminated)
		.local_init_done_5    (1'b1),                             // (terminated)
		.local_cal_success_5  (1'b1),                             // (terminated)
		.local_cal_fail_5     (1'b0),                             // (terminated)
		.test_complete_6      (1'b1),                             // (terminated)
		.fail_6               (1'b0),                             // (terminated)
		.pass_6               (1'b1),                             // (terminated)
		.local_init_done_6    (1'b1),                             // (terminated)
		.local_cal_success_6  (1'b1),                             // (terminated)
		.local_cal_fail_6     (1'b0),                             // (terminated)
		.test_complete_7      (1'b1),                             // (terminated)
		.fail_7               (1'b0),                             // (terminated)
		.pass_7               (1'b1),                             // (terminated)
		.local_init_done_7    (1'b1),                             // (terminated)
		.local_cal_success_7  (1'b1),                             // (terminated)
		.local_cal_fail_7     (1'b0),                             // (terminated)
		.test_complete_8      (1'b1),                             // (terminated)
		.fail_8               (1'b0),                             // (terminated)
		.pass_8               (1'b1),                             // (terminated)
		.local_init_done_8    (1'b1),                             // (terminated)
		.local_cal_success_8  (1'b1),                             // (terminated)
		.local_cal_fail_8     (1'b0),                             // (terminated)
		.test_complete_9      (1'b1),                             // (terminated)
		.fail_9               (1'b0),                             // (terminated)
		.pass_9               (1'b1),                             // (terminated)
		.local_init_done_9    (1'b1),                             // (terminated)
		.local_cal_success_9  (1'b1),                             // (terminated)
		.local_cal_fail_9     (1'b0),                             // (terminated)
		.test_complete_10     (1'b1),                             // (terminated)
		.fail_10              (1'b0),                             // (terminated)
		.pass_10              (1'b1),                             // (terminated)
		.local_init_done_10   (1'b1),                             // (terminated)
		.local_cal_success_10 (1'b1),                             // (terminated)
		.local_cal_fail_10    (1'b0),                             // (terminated)
		.test_complete_11     (1'b1),                             // (terminated)
		.fail_11              (1'b0),                             // (terminated)
		.pass_11              (1'b1),                             // (terminated)
		.local_init_done_11   (1'b1),                             // (terminated)
		.local_cal_success_11 (1'b1),                             // (terminated)
		.local_cal_fail_11    (1'b0)                              // (terminated)
	);

	alt_mem_if_ddr3_mem_model_top_ddr3_mem_if_dm_pins_en_mem_if_dqsn_en #(
		.MEM_IF_ADDR_WIDTH            (13),
		.MEM_IF_ROW_ADDR_WIDTH        (13),
		.MEM_IF_COL_ADDR_WIDTH        (10),
		.MEM_IF_CONTROL_WIDTH         (1),
		.MEM_IF_DQS_WIDTH             (8),
		.MEM_IF_CS_WIDTH              (1),
		.MEM_IF_BANKADDR_WIDTH        (3),
		.MEM_IF_DQ_WIDTH              (64),
		.MEM_IF_CK_WIDTH              (1),
		.MEM_IF_CLK_EN_WIDTH          (1),
		.MEM_TRCD                     (9),
		.MEM_TRTP                     (5),
		.MEM_DQS_TO_CLK_CAPTURE_DELAY (100),
		.MEM_CLK_TO_DQS_CAPTURE_DELAY (100000),
		.MEM_IF_ODT_WIDTH             (1),
		.MEM_IF_LRDIMM_RM             (0),
		.MEM_MIRROR_ADDRESSING_DEC    (0),
		.MEM_REGDIMM_ENABLED          (0),
		.MEM_LRDIMM_ENABLED           (0),
		.DEVICE_DEPTH                 (1),
		.MEM_NUMBER_OF_DIMMS          (1),
		.MEM_NUMBER_OF_RANKS_PER_DIMM (1),
		.MEM_GUARANTEED_WRITE_INIT    (0),
		.MEM_VERBOSE                  (1),
		.REFRESH_BURST_VALIDATION     (0),
		.MEM_INIT_EN                  (0),
		.MEM_INIT_FILE                (""),
		.DAT_DATA_WIDTH               (32)
	) m0 (
		.mem_a       (e0_memory_mem_a),       // memory.mem_a
		.mem_ba      (e0_memory_mem_ba),      //       .mem_ba
		.mem_ck      (e0_memory_mem_ck),      //       .mem_ck
		.mem_ck_n    (e0_memory_mem_ck_n),    //       .mem_ck_n
		.mem_cke     (e0_memory_mem_cke),     //       .mem_cke
		.mem_cs_n    (e0_memory_mem_cs_n),    //       .mem_cs_n
		.mem_dm      (e0_memory_mem_dm),      //       .mem_dm
		.mem_ras_n   (e0_memory_mem_ras_n),   //       .mem_ras_n
		.mem_cas_n   (e0_memory_mem_cas_n),   //       .mem_cas_n
		.mem_we_n    (e0_memory_mem_we_n),    //       .mem_we_n
		.mem_reset_n (e0_memory_mem_reset_n), //       .mem_reset_n
		.mem_dq      (e0_memory_mem_dq),      //       .mem_dq
		.mem_dqs     (e0_memory_mem_dqs),     //       .mem_dqs
		.mem_dqs_n   (e0_memory_mem_dqs_n),   //       .mem_dqs_n
		.mem_odt     (e0_memory_mem_odt)      //       .mem_odt
	);


endmodule