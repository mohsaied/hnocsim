onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /testbench/i_data_in
add wave -noupdate -radix unsigned /testbench/i_addr_in
add wave -noupdate /testbench/i_write_en
add wave -noupdate /testbench/i_read_en
add wave -noupdate /testbench/pkt_valid_in
add wave -noupdate -radix unsigned /testbench/o_data_out
add wave -noupdate -radix unsigned /testbench/o_src_out
add wave -noupdate /testbench/pkt_valid_out
add wave -noupdate -expand -group pkt_in -radix hexadecimal /testbench/pkt_inst_tin/i_data_in
add wave -noupdate -expand -group pkt_in /testbench/pkt_inst_tin/i_valid_in
add wave -noupdate -expand -group pkt_in /testbench/pkt_inst_tin/i_dest_in
add wave -noupdate -expand -group pkt_in /testbench/pkt_inst_tin/i_ready_out
add wave -noupdate -expand -group pkt_in /testbench/pkt_inst_tin/o_data_out
add wave -noupdate -expand -group pkt_in /testbench/pkt_inst_tin/o_valid_out
add wave -noupdate -expand -group pkt_in /testbench/pkt_inst_tin/o_ready_in
add wave -noupdate -expand -group pkt_in /testbench/pkt_inst_tin/flit_1_data
add wave -noupdate -expand -group pkt_in /testbench/pkt_inst_tin/flit_2_data
add wave -noupdate -expand -group pkt_in /testbench/pkt_inst_tin/flit_3_data
add wave -noupdate -expand -group pkt_in /testbench/pkt_inst_tin/flit_4_data
add wave -noupdate -expand -group pkt_out /testbench/depkt_inst_tin/i_packet_in
add wave -noupdate -expand -group pkt_out /testbench/depkt_inst_tin/i_valid_in
add wave -noupdate -expand -group pkt_out /testbench/depkt_inst_tin/i_ready_out
add wave -noupdate -expand -group pkt_out /testbench/depkt_inst_tin/o_data_out
add wave -noupdate -expand -group pkt_out /testbench/depkt_inst_tin/o_valid_out
add wave -noupdate -expand -group pkt_out /testbench/depkt_inst_tin/o_ready_in
add wave -noupdate -expand -group pkt_out /testbench/depkt_inst_tin/full_data
add wave -noupdate -expand -group ram_in -radix hexadecimal /testbench/pkt_inst_rin/i_data_in
add wave -noupdate -expand -group ram_in /testbench/pkt_inst_rin/i_valid_in
add wave -noupdate -expand -group ram_in /testbench/pkt_inst_rin/i_dest_in
add wave -noupdate -expand -group ram_in /testbench/pkt_inst_rin/i_ready_out
add wave -noupdate -expand -group ram_in /testbench/pkt_inst_rin/o_data_out
add wave -noupdate -expand -group ram_in /testbench/pkt_inst_rin/o_valid_out
add wave -noupdate -expand -group ram_in /testbench/pkt_inst_rin/o_ready_in
add wave -noupdate -expand -group ram_out -radix hexadecimal /testbench/depkt_inst_rout/i_packet_in
add wave -noupdate -expand -group ram_out /testbench/depkt_inst_rout/i_valid_in
add wave -noupdate -expand -group ram_out /testbench/depkt_inst_rout/i_ready_out
add wave -noupdate -expand -group ram_out -radix hexadecimal /testbench/depkt_inst_rout/o_data_out
add wave -noupdate -expand -group ram_out /testbench/depkt_inst_rout/o_valid_out
add wave -noupdate -expand -group ram_out /testbench/depkt_inst_rout/o_ready_in
add wave -noupdate -expand -group RAM /testbench/ram_inst/clk
add wave -noupdate -expand -group RAM /testbench/ram_inst/rst
add wave -noupdate -expand -group RAM /testbench/ram_inst/i_packed_in
add wave -noupdate -expand -group RAM /testbench/ram_inst/i_valid_in
add wave -noupdate -expand -group RAM /testbench/ram_inst/i_ready_out
add wave -noupdate -expand -group RAM -radix hexadecimal /testbench/ram_inst/o_packed_out
add wave -noupdate -expand -group RAM -radix unsigned /testbench/ram_inst/o_dest_out
add wave -noupdate -expand -group RAM /testbench/ram_inst/o_valid_out
add wave -noupdate -expand -group RAM /testbench/ram_inst/o_ready_in
add wave -noupdate -expand -group RAM -radix unsigned /testbench/ram_inst/i_data_in
add wave -noupdate -expand -group RAM -radix unsigned /testbench/ram_inst/i_addr_in
add wave -noupdate -expand -group RAM /testbench/ram_inst/i_write_en
add wave -noupdate -expand -group RAM /testbench/ram_inst/i_read_en
add wave -noupdate -expand -group RAM /testbench/ram_inst/i_src_in
add wave -noupdate -expand -group RAM -radix unsigned /testbench/ram_inst/o_data_out
add wave -noupdate -expand -group RAM -radix unsigned -childformat {{{/testbench/ram_inst/memory[15]} -radix unsigned} {{/testbench/ram_inst/memory[14]} -radix unsigned} {{/testbench/ram_inst/memory[13]} -radix unsigned} {{/testbench/ram_inst/memory[12]} -radix unsigned} {{/testbench/ram_inst/memory[11]} -radix unsigned} {{/testbench/ram_inst/memory[10]} -radix unsigned} {{/testbench/ram_inst/memory[9]} -radix unsigned} {{/testbench/ram_inst/memory[8]} -radix unsigned} {{/testbench/ram_inst/memory[7]} -radix unsigned} {{/testbench/ram_inst/memory[6]} -radix unsigned} {{/testbench/ram_inst/memory[5]} -radix unsigned} {{/testbench/ram_inst/memory[4]} -radix unsigned} {{/testbench/ram_inst/memory[3]} -radix unsigned} {{/testbench/ram_inst/memory[2]} -radix unsigned} {{/testbench/ram_inst/memory[1]} -radix unsigned} {{/testbench/ram_inst/memory[0]} -radix unsigned}} -subitemconfig {{/testbench/ram_inst/memory[15]} {-radix unsigned} {/testbench/ram_inst/memory[14]} {-radix unsigned} {/testbench/ram_inst/memory[13]} {-radix unsigned} {/testbench/ram_inst/memory[12]} {-radix unsigned} {/testbench/ram_inst/memory[11]} {-radix unsigned} {/testbench/ram_inst/memory[10]} {-radix unsigned} {/testbench/ram_inst/memory[9]} {-radix unsigned} {/testbench/ram_inst/memory[8]} {-radix unsigned} {/testbench/ram_inst/memory[7]} {-radix unsigned} {/testbench/ram_inst/memory[6]} {-radix unsigned} {/testbench/ram_inst/memory[5]} {-height 13 -radix unsigned} {/testbench/ram_inst/memory[4]} {-height 13 -radix unsigned} {/testbench/ram_inst/memory[3]} {-height 13 -radix unsigned} {/testbench/ram_inst/memory[2]} {-height 13 -radix unsigned} {/testbench/ram_inst/memory[1]} {-height 13 -radix unsigned} {/testbench/ram_inst/memory[0]} {-height 13 -radix unsigned}} /testbench/ram_inst/memory
add wave -noupdate -expand -group RAM /testbench/ram_inst/output_buffer
add wave -noupdate -expand -group RAM /testbench/ram_inst/dest_buffer
add wave -noupdate -expand -group RAM /testbench/ram_inst/output_buffer_valid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {547805 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 196
configure wave -valuecolwidth 100
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
WaveRestoreZoom {295036 ps} {352232 ps}
