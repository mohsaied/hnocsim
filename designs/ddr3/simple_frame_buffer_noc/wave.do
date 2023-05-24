onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group fabric_interface /testbench/fi_inst/clk_noc
add wave -noupdate -group fabric_interface /testbench/fi_inst/rst
add wave -noupdate -group fabric_interface /testbench/fi_inst/clk_rtl
add wave -noupdate -group fabric_interface /testbench/fi_inst/clk_int
add wave -noupdate -group fabric_interface /testbench/fi_inst/i_packets_in
add wave -noupdate -group fabric_interface /testbench/fi_inst/i_valids_in
add wave -noupdate -group fabric_interface /testbench/fi_inst/i_readys_out
add wave -noupdate -group fabric_interface /testbench/fi_inst/o_packets_out
add wave -noupdate -group fabric_interface /testbench/fi_inst/o_valids_out
add wave -noupdate -group fabric_interface /testbench/fi_inst/o_readys_in
add wave -noupdate -group fabric_interface /testbench/fi_inst/clk
add wave -noupdate -group fabric_interface /testbench/fi_inst/i
add wave -noupdate -group fabric_interface /testbench/fi_inst/cycle_count
add wave -noupdate -group fabric_interface /testbench/fi_inst/flits_in
add wave -noupdate -group fabric_interface /testbench/fi_inst/flits_out
add wave -noupdate -group fabric_interface /testbench/fi_inst/credits_in
add wave -noupdate -group fabric_interface /testbench/fi_inst/credits_out
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/AVL_ADDR_WIDTH
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/AVL_DATA_WIDTH
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/AVL_BYTE_EN_WIDTH
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/FRAME_ID_WIDTH
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/BIN_ADDR_WIDTH
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/FRAME_OFFSET_WIDTH
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/WIDTH_PKT
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/WRITE_POS
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/READ_POS
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/ID_POS
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/DATA_POS
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/clk
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/rst
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/noc_data_in
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/noc_valid_in
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/noc_ready_out
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/noc_sop_in
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/noc_eop_in
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/frame_valid
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/frame_data
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/frame_write
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/frame_read
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/frame_id
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/port_id
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/frame_count
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/frame_count_rev
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/frame_sop
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/frame_eop
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/noc_ready_reg
add wave -noupdate -group {pkt gen} /testbench/pkt_gen/i
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/ADDRESS_WIDTH
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/VC_ADDRESS_WIDTH
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/WIDTH_IN
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/WIDTH_OUT
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/ASSIGNED_VC
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_1_WIDTH_IDL
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_2_WIDTH_IDL
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_3_WIDTH_IDL
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_4_WIDTH_IDL
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_1_VALID
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_1_WIDTH_ACT
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_1_PADDING
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/REM_FROM_1
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_2_VALID
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_2_WIDTH_ACT
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_2_PADDING
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/REM_FROM_2
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_3_VALID
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_3_WIDTH_ACT
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_3_PADDING
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/REM_FROM_3
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_4_VALID
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_4_WIDTH_ACT
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_4_PADDING
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_2_START
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_3_START
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/FLIT_4_START
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/i_data_in
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/i_valid_in
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/i_dest_in
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/i_ready_out
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/i_sop_in
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/i_eop_in
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/o_packet_out
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/o_valid_out
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/o_ready_in
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/flit_1_data
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/flit_2_data
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/flit_3_data
add wave -noupdate -group {_pkt pkt gen} /testbench/pgen_pktizer/flit_4_data
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/AVL_ADDR_WIDTH
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/AVL_DATA_WIDTH
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/AVL_BYTE_EN_WIDTH
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/FRAME_ID_WIDTH
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/BIN_ADDR_WIDTH
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/FRAME_OFFSET_WIDTH
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/NOC_ADDR_WIDTH
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/WIDTH_PKT
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/clk
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/rst
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/top_noc_data_in
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/top_noc_valid_in
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/top_noc_ready_out
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/top_noc_sop_in
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/top_noc_eop_in
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/top_noc_data_out
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/top_noc_dest_out
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/top_noc_valid_out
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/top_noc_ready_in
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/top_noc_sop_out
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/top_noc_eop_out
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/noc_data_out
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/noc_valid_out
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/noc_ready_in
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/noc_sop_out
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/noc_eop_out
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/avl_writedata
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/avl_address
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/avl_write
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/avl_read
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/avl_readdata
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/avl_byteenable
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/avl_readdatavalid
add wave -noupdate -group {ethernet frame buffer} /testbench/fb_inst/avl_waitrequest
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/WIDTH_PKT
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/clk
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/rst
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/noc_data_in
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/noc_valid_in
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/noc_ready_out
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/noc_sop_in
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/noc_eop_in
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/noc_data_out
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/noc_valid_out
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/noc_ready_in
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/noc_sop_out
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/noc_eop_out
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/noc_data_reg
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/noc_valid_reg
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/noc_sop_reg
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/noc_eop_reg
add wave -noupdate -group avl_shim /testbench/fb_inst/noc_to_avl/waitrequest_delay_reg
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/AVL_ADDR_WIDTH
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/AVL_DATA_WIDTH
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/AVL_BYTE_EN_WIDTH
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/FRAME_ID_WIDTH
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/BIN_ADDR_WIDTH
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/FRAME_OFFSET_WIDTH
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/NOC_ADDR_WIDTH
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/WIDTH_PKT
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/WRITE_POS
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/READ_POS
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/ID_POS
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/DATA_POS
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/ADDR_PADDING
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/FIFO_WIDTH
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/FIFO_DEPTH
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/FIFO_SOP_POS
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/FIFO_EOP_POS
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/FIFO_FID_POS
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/FIFO_DATA_POS
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/FIFO_DEST_POS
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/RCNT_WAIT
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/RCNT_PRG
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/WAIT
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/READ
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/READ_WAIT
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/WRITE
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/WRITE_WAIT
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/READ_END_WAIT
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/READ_WAIT_FIFO
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/clk
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/rst
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/noc_data_in
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/noc_valid_in
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/noc_ready_out
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/noc_sop_in
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/noc_eop_in
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/noc_data_out
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/noc_valid_out
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/noc_ready_in
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/noc_sop_out
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/noc_eop_out
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/noc_dest_out
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/avl_writedata
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/avl_address
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/avl_write
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/avl_read
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/avl_readdata
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/avl_byteenable
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/avl_readdatavalid
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/avl_waitrequest
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/frame_offset
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/noc_ready_out_reg
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/frame_valid_in
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/frame_data_in
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/frame_write_in
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/frame_read_in
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/frame_id_in
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/frame_sop_in
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/frame_eop_in
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/frame_dest_in
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/avl_writedata_reg
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/avl_writedata_bak
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/avl_writedata_frt
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/avl_address_reg
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/avl_write_reg
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/avl_read_reg
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/avl_byteenable_reg
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/fifo_data_in
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/fifo_write_en
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/fifo_full
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/fifo_data_out
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/fifo_read_en
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/fifo_empty
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/sop_fifo
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/eop_fifo
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/frame_id_fifo
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/read_start
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/noc_ready_in_reg
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/noc_ready_in_delay
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/fifo_empty_delay
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/dest_fifo
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/frame_id_reg
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/frame_dest_reg
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/rcnt_state
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/rcnt_count
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/wait_for_read
add wave -noupdate -group {frame buffer} /testbench/fb_inst/dut/state
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/DATA_WIDTH
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/ADDR_WIDTH
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/RAM_DEPTH
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/BYTE_EN_WIDTH
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/clk
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/rst
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/waitrequest
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/address
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/burstcount
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/writedata
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/readdata
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/write
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/read
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/readdatavalid
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/byteenable
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/readdata_reg
add wave -noupdate -group ddr3 /testbench/fb_inst/ddr3_inst/readdatavalid_reg
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/ADDRESS_WIDTH
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/VC_ADDRESS_WIDTH
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/WIDTH_IN
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/WIDTH_OUT
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/ASSIGNED_VC
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_1_WIDTH_IDL
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_2_WIDTH_IDL
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_3_WIDTH_IDL
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_4_WIDTH_IDL
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_1_VALID
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_1_WIDTH_ACT
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_1_PADDING
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/REM_FROM_1
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_2_VALID
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_2_WIDTH_ACT
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_2_PADDING
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/REM_FROM_2
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_3_VALID
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_3_WIDTH_ACT
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_3_PADDING
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/REM_FROM_3
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_4_VALID
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_4_WIDTH_ACT
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_4_PADDING
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_2_START
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_3_START
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/FLIT_4_START
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/i_data_in
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/i_valid_in
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/i_dest_in
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/i_ready_out
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/i_sop_in
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/i_eop_in
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/o_packet_out
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/o_valid_out
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/o_ready_in
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/flit_1_data
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/flit_2_data
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/flit_3_data
add wave -noupdate -group {_pkt ddr3} /testbench/ddr_pktizer/flit_4_data
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/WIDTH_PKT
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/WIDTH_DATA
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/VC_ADDRESS_WIDTH
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/ADDRESS_WIDTH
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/WIDTH_FLIT
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/DATA_POS_HEAD
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/DATA_POS_B1
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/DATA_POS_B2
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/DATA_POS_TAIL
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/WIDTH_DATA_IDL
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/EXTRA_BITS
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/VALID1_POS
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/VALID2_POS
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/VALID3_POS
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/VALID4_POS
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/SOP1_POS
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/SOP2_POS
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/SOP3_POS
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/SOP4_POS
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/EOP1_POS
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/EOP2_POS
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/EOP3_POS
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/EOP4_POS
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/i_packet_in
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/i_valid_in
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/i_ready_out
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/o_data_out
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/o_valid_out
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/o_ready_in
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/o_sop_out
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/o_eop_out
add wave -noupdate -group {_depkt ddr3} /testbench/ddr_depktizer/full_data
add wave -noupdate -expand -group tb /testbench/WIDTH_NOC
add wave -noupdate -expand -group tb /testbench/WIDTH_RTL
add wave -noupdate -expand -group tb /testbench/NUM_VC
add wave -noupdate -expand -group tb /testbench/DEPTH_PER_VC
add wave -noupdate -expand -group tb /testbench/N
add wave -noupdate -expand -group tb /testbench/ADDRESS_WIDTH
add wave -noupdate -expand -group tb /testbench/VC_ADDRESS_WIDTH
add wave -noupdate -expand -group tb /testbench/AVL_ADDR_WIDTH
add wave -noupdate -expand -group tb /testbench/AVL_DATA_WIDTH
add wave -noupdate -expand -group tb /testbench/AVL_BYTE_EN_WIDTH
add wave -noupdate -expand -group tb /testbench/FRAME_ID_WIDTH
add wave -noupdate -expand -group tb /testbench/BIN_ADDR_WIDTH
add wave -noupdate -expand -group tb /testbench/FRAME_OFFSET_WIDTH
add wave -noupdate -expand -group tb /testbench/NOC_ADDR_WIDTH
add wave -noupdate -expand -group tb /testbench/WIDTH_PKT
add wave -noupdate -expand -group tb /testbench/PGEN_NODE
add wave -noupdate -expand -group tb /testbench/DDR_NODE
add wave -noupdate -expand -group tb /testbench/clk
add wave -noupdate -expand -group tb /testbench/rst
add wave -noupdate -expand -group tb /testbench/clk_noc
add wave -noupdate -expand -group tb /testbench/clk_rtls
add wave -noupdate -expand -group tb /testbench/clk_rtl
add wave -noupdate -expand -group tb /testbench/clk_ints
add wave -noupdate -expand -group tb /testbench/clk_int
add wave -noupdate -expand -group tb /testbench/i_packets_in
add wave -noupdate -expand -group tb /testbench/i_valids_in
add wave -noupdate -expand -group tb /testbench/i_readys_out
add wave -noupdate -expand -group tb /testbench/o_packets_out
add wave -noupdate -expand -group tb /testbench/o_valids_out
add wave -noupdate -expand -group tb /testbench/o_readys_in
add wave -noupdate -expand -group tb /testbench/pgen_noc_data_out
add wave -noupdate -expand -group tb /testbench/pgen_noc_valid_out
add wave -noupdate -expand -group tb /testbench/pgen_noc_ready_in
add wave -noupdate -expand -group tb /testbench/pgen_noc_sop_out
add wave -noupdate -expand -group tb /testbench/pgen_noc_eop_out
add wave -noupdate -expand -group tb /testbench/ddr_noc_data_in
add wave -noupdate -expand -group tb /testbench/ddr_noc_valid_in
add wave -noupdate -expand -group tb /testbench/ddr_noc_ready_out
add wave -noupdate -expand -group tb /testbench/ddr_noc_sop_in
add wave -noupdate -expand -group tb /testbench/ddr_noc_eop_in
add wave -noupdate -expand -group tb /testbench/ddr_noc_data_out
add wave -noupdate -expand -group tb /testbench/ddr_noc_dest_out
add wave -noupdate -expand -group tb /testbench/ddr_noc_valid_out
add wave -noupdate -expand -group tb /testbench/ddr_noc_ready_in
add wave -noupdate -expand -group tb /testbench/ddr_noc_sop_out
add wave -noupdate -expand -group tb /testbench/ddr_noc_eop_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {107766856 ps} 0} {{Cursor 2} {107827352 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 208
configure wave -valuecolwidth 98
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {107533465 ps} {107925896 ps}
