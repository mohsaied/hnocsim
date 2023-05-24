onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/AVL_ADDR_WIDTH
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/AVL_DATA_WIDTH
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/AVL_BYTE_EN_WIDTH
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/FRAME_ID_WIDTH
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/BIN_ADDR_WIDTH
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/FRAME_OFFSET_WIDTH
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/WIDTH_PKT
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/WRITE_POS
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/READ_POS
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/ID_POS
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/DATA_POS
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/clk
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/rst
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/noc_data_in
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/noc_valid_in
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/noc_ready_out
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/noc_sop_in
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/noc_eop_in
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/frame_valid
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/frame_data
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/frame_write
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/frame_read
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/frame_id
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/port_id
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/frame_count
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/frame_count_rev
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/frame_sop
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/frame_eop
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/noc_ready_reg
add wave -noupdate -group {PKT Gen} /tb_pkts_to_ddr/pkt_gen/i
add wave -noupdate -group avl_shim /tb_pkts_to_ddr/avl_shim_inst/WIDTH_PKT
add wave -noupdate -group avl_shim /tb_pkts_to_ddr/avl_shim_inst/clk
add wave -noupdate -group avl_shim /tb_pkts_to_ddr/avl_shim_inst/rst
add wave -noupdate -group avl_shim -radix hexadecimal /tb_pkts_to_ddr/avl_shim_inst/noc_data_in
add wave -noupdate -group avl_shim /tb_pkts_to_ddr/avl_shim_inst/noc_valid_in
add wave -noupdate -group avl_shim /tb_pkts_to_ddr/avl_shim_inst/noc_ready_out
add wave -noupdate -group avl_shim /tb_pkts_to_ddr/avl_shim_inst/noc_sop_in
add wave -noupdate -group avl_shim /tb_pkts_to_ddr/avl_shim_inst/noc_eop_in
add wave -noupdate -group avl_shim -radix hexadecimal /tb_pkts_to_ddr/avl_shim_inst/noc_data_out
add wave -noupdate -group avl_shim /tb_pkts_to_ddr/avl_shim_inst/noc_valid_out
add wave -noupdate -group avl_shim /tb_pkts_to_ddr/avl_shim_inst/noc_ready_in
add wave -noupdate -group avl_shim /tb_pkts_to_ddr/avl_shim_inst/noc_sop_out
add wave -noupdate -group avl_shim /tb_pkts_to_ddr/avl_shim_inst/noc_eop_out
add wave -noupdate -group avl_shim -radix hexadecimal /tb_pkts_to_ddr/avl_shim_inst/noc_data_reg
add wave -noupdate -group avl_shim /tb_pkts_to_ddr/avl_shim_inst/noc_valid_reg
add wave -noupdate -group avl_shim /tb_pkts_to_ddr/avl_shim_inst/noc_sop_reg
add wave -noupdate -group avl_shim /tb_pkts_to_ddr/avl_shim_inst/noc_eop_reg
add wave -noupdate -group avl_shim /tb_pkts_to_ddr/avl_shim_inst/waitrequest_delay_reg
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/WIDTH
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/DEPTH
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/ADDRESS_WIDTH
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/clk
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/rst
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/i_data_in
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/i_write_en
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/i_full_out
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/o_data_out
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/o_read_en
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/o_empty_out
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/memory
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/next_read_addr
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/next_write_addr
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/next_read_en
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/next_write_en
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/equal_address
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/set_status
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/rst_status
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/preset_full
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/preset_empty
add wave -noupdate -group {READ FIFO} /tb_pkts_to_ddr/dut/scfifo_inst/status
add wave -noupdate -group Constants /tb_pkts_to_ddr/dut/AVL_ADDR_WIDTH
add wave -noupdate -group Constants /tb_pkts_to_ddr/dut/AVL_DATA_WIDTH
add wave -noupdate -group Constants /tb_pkts_to_ddr/dut/AVL_BYTE_EN_WIDTH
add wave -noupdate -group Constants /tb_pkts_to_ddr/dut/FRAME_ID_WIDTH
add wave -noupdate -group Constants /tb_pkts_to_ddr/dut/BIN_ADDR_WIDTH
add wave -noupdate -group Constants /tb_pkts_to_ddr/dut/FRAME_OFFSET_WIDTH
add wave -noupdate -group Constants /tb_pkts_to_ddr/dut/WIDTH_PKT
add wave -noupdate -group Constants /tb_pkts_to_ddr/dut/WRITE_POS
add wave -noupdate -group Constants /tb_pkts_to_ddr/dut/READ_POS
add wave -noupdate -group Constants /tb_pkts_to_ddr/dut/ID_POS
add wave -noupdate -group Constants /tb_pkts_to_ddr/dut/DATA_POS
add wave -noupdate -group Constants /tb_pkts_to_ddr/dut/ADDR_PADDING
add wave -noupdate -group States /tb_pkts_to_ddr/dut/WAIT
add wave -noupdate -group States /tb_pkts_to_ddr/dut/READ
add wave -noupdate -group States /tb_pkts_to_ddr/dut/READ_WAIT
add wave -noupdate -group States /tb_pkts_to_ddr/dut/WRITE
add wave -noupdate -group States /tb_pkts_to_ddr/dut/WRITE_WAIT
add wave -noupdate /tb_pkts_to_ddr/dut/clk
add wave -noupdate /tb_pkts_to_ddr/dut/rst
add wave -noupdate /tb_pkts_to_ddr/dut/noc_data_in
add wave -noupdate /tb_pkts_to_ddr/dut/noc_valid_in
add wave -noupdate /tb_pkts_to_ddr/dut/noc_ready_out
add wave -noupdate /tb_pkts_to_ddr/dut/noc_sop_in
add wave -noupdate /tb_pkts_to_ddr/dut/noc_eop_in
add wave -noupdate -radix hexadecimal /tb_pkts_to_ddr/dut/avl_writedata
add wave -noupdate /tb_pkts_to_ddr/dut/avl_address
add wave -noupdate /tb_pkts_to_ddr/dut/avl_write
add wave -noupdate /tb_pkts_to_ddr/dut/avl_read
add wave -noupdate /tb_pkts_to_ddr/dut/avl_readdata
add wave -noupdate /tb_pkts_to_ddr/dut/avl_byteenable
add wave -noupdate /tb_pkts_to_ddr/dut/avl_readdatavalid
add wave -noupdate /tb_pkts_to_ddr/dut/avl_waitrequest
add wave -noupdate /tb_pkts_to_ddr/dut/frame_offset
add wave -noupdate /tb_pkts_to_ddr/dut/avl_writedata_reg
add wave -noupdate /tb_pkts_to_ddr/dut/avl_address_reg
add wave -noupdate /tb_pkts_to_ddr/dut/avl_write_reg
add wave -noupdate /tb_pkts_to_ddr/dut/avl_read_reg
add wave -noupdate /tb_pkts_to_ddr/dut/noc_ready_out_reg
add wave -noupdate /tb_pkts_to_ddr/dut/frame_valid_in
add wave -noupdate -radix hexadecimal /tb_pkts_to_ddr/dut/frame_data_in
add wave -noupdate /tb_pkts_to_ddr/dut/frame_write_in
add wave -noupdate /tb_pkts_to_ddr/dut/frame_read_in
add wave -noupdate /tb_pkts_to_ddr/dut/frame_id_in
add wave -noupdate /tb_pkts_to_ddr/dut/frame_sop_in
add wave -noupdate /tb_pkts_to_ddr/dut/frame_eop_in
add wave -noupdate /tb_pkts_to_ddr/dut/state
add wave -noupdate /tb_pkts_to_ddr/dut/read_start
add wave -noupdate /tb_pkts_to_ddr/dut/rcnt_state
add wave -noupdate /tb_pkts_to_ddr/dut/rcnt_count
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {17 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 281
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
configure wave -timelineunits ps
update
WaveRestoreZoom {41 ps} {325 ps}
