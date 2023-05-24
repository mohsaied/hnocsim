onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group tb /testbench/WIDTH_NOC
add wave -noupdate -group tb /testbench/WIDTH_RTL
add wave -noupdate -group tb /testbench/NUM_VC
add wave -noupdate -group tb /testbench/DEPTH_PER_VC
add wave -noupdate -group tb /testbench/N
add wave -noupdate -group tb /testbench/ADDRESS_WIDTH
add wave -noupdate -group tb /testbench/VC_ADDRESS_WIDTH
add wave -noupdate -group tb /testbench/AVL_ADDR_WIDTH
add wave -noupdate -group tb /testbench/AVL_DATA_WIDTH
add wave -noupdate -group tb /testbench/AVL_BYTE_EN_WIDTH
add wave -noupdate -group tb /testbench/FRAME_ID_WIDTH
add wave -noupdate -group tb /testbench/BIN_ADDR_WIDTH
add wave -noupdate -group tb /testbench/FRAME_OFFSET_WIDTH
add wave -noupdate -group tb /testbench/NOC_ADDR_WIDTH
add wave -noupdate -group tb /testbench/WIDTH_PKT
add wave -noupdate -group tb /testbench/PGEN_NODE
add wave -noupdate -group tb /testbench/DDR_NODE
add wave -noupdate -group tb /testbench/clk
add wave -noupdate -group tb /testbench/rst
add wave -noupdate -group tb /testbench/clk_noc
add wave -noupdate -group tb /testbench/clk_rtls
add wave -noupdate -group tb /testbench/clk_rtl
add wave -noupdate -group tb /testbench/clk_ints
add wave -noupdate -group tb /testbench/clk_int
add wave -noupdate -group tb /testbench/clk_shift
add wave -noupdate -group tb /testbench/clk_2x
add wave -noupdate -group tb /testbench/clk_2x_shift
add wave -noupdate -group tb /testbench/i_packets_in
add wave -noupdate -group tb /testbench/i_valids_in
add wave -noupdate -group tb /testbench/i_readys_out
add wave -noupdate -group tb /testbench/o_packets_out
add wave -noupdate -group tb /testbench/o_valids_out
add wave -noupdate -group tb /testbench/o_readys_in
add wave -noupdate -group tb /testbench/pgen_noc_data_out
add wave -noupdate -group tb /testbench/pgen_noc_valid_out
add wave -noupdate -group tb /testbench/pgen_noc_ready_in
add wave -noupdate -group tb /testbench/pgen_noc_sop_out
add wave -noupdate -group tb /testbench/pgen_noc_eop_out
add wave -noupdate -group tb /testbench/ddr_noc_data_in
add wave -noupdate -group tb /testbench/ddr_noc_valid_in
add wave -noupdate -group tb /testbench/ddr_noc_ready_out
add wave -noupdate -group tb /testbench/ddr_noc_sop_in
add wave -noupdate -group tb /testbench/ddr_noc_eop_in
add wave -noupdate -group tb /testbench/ddr_noc_data_out
add wave -noupdate -group tb /testbench/ddr_noc_dest_out
add wave -noupdate -group tb /testbench/ddr_noc_valid_out
add wave -noupdate -group tb /testbench/ddr_noc_ready_in
add wave -noupdate -group tb /testbench/ddr_noc_sop_out
add wave -noupdate -group tb /testbench/ddr_noc_eop_out
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/AVL_ADDR_WIDTH
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/AVL_DATA_WIDTH
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/AVL_BYTE_EN_WIDTH
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/FRAME_ID_WIDTH
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/BIN_ADDR_WIDTH
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/FRAME_OFFSET_WIDTH
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/WIDTH_PKT
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/WRITE_POS
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/READ_POS
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/ID_POS
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/DATA_POS
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/clk
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/rst
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/noc_data_in
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/noc_valid_in
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/noc_ready_out
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/noc_sop_in
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/noc_eop_in
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/frame_valid
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/frame_data
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/frame_write
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/frame_read
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/frame_id
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/port_id
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/frame_count
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/frame_count_rev
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/frame_sop
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/frame_eop
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/noc_ready_reg
add wave -noupdate -group {PKT gen} /testbench/pkt_gen/i
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/ADDRESS_WIDTH
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/VC_ADDRESS_WIDTH
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/WIDTH_IN
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/WIDTH_OUT
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/ASSIGNED_VC
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_1_WIDTH_IDL
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_2_WIDTH_IDL
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_3_WIDTH_IDL
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_4_WIDTH_IDL
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_1_VALID
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_1_WIDTH_ACT
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_1_PADDING
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/REM_FROM_1
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_2_VALID
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_2_WIDTH_ACT
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_2_PADDING
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/REM_FROM_2
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_3_VALID
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_3_WIDTH_ACT
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_3_PADDING
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/REM_FROM_3
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_4_VALID
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_4_WIDTH_ACT
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_4_PADDING
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_2_START
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_3_START
add wave -noupdate -expand -group {_pkt PKT gen} -group {_pkt PKT gen} /testbench/pgen_pktizer/FLIT_4_START
add wave -noupdate -expand -group {_pkt PKT gen} /testbench/pgen_pktizer/i_data_in
add wave -noupdate -expand -group {_pkt PKT gen} /testbench/pgen_pktizer/i_valid_in
add wave -noupdate -expand -group {_pkt PKT gen} /testbench/pgen_pktizer/i_dest_in
add wave -noupdate -expand -group {_pkt PKT gen} /testbench/pgen_pktizer/i_ready_out
add wave -noupdate -expand -group {_pkt PKT gen} /testbench/pgen_pktizer/i_sop_in
add wave -noupdate -expand -group {_pkt PKT gen} /testbench/pgen_pktizer/i_eop_in
add wave -noupdate -expand -group {_pkt PKT gen} /testbench/pgen_pktizer/o_packet_out
add wave -noupdate -expand -group {_pkt PKT gen} /testbench/pgen_pktizer/o_valid_out
add wave -noupdate -expand -group {_pkt PKT gen} /testbench/pgen_pktizer/o_ready_in
add wave -noupdate -expand -group {_pkt PKT gen} /testbench/pgen_pktizer/flit_1_data
add wave -noupdate -expand -group {_pkt PKT gen} /testbench/pgen_pktizer/flit_2_data
add wave -noupdate -expand -group {_pkt PKT gen} /testbench/pgen_pktizer/flit_3_data
add wave -noupdate -expand -group {_pkt PKT gen} /testbench/pgen_pktizer/flit_4_data
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
