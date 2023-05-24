onerror {resume}
quietly virtual signal -install /testbench/src0 { /testbench/src0/pkt_data_out[499:469]} id
quietly virtual signal -install /testbench/depkt1_inst { /testbench/depkt1_inst/o_data_out[499:469]} id
quietly virtual signal -install /testbench/src0 { /testbench/src0/pkt_data_out[499:468]} id001
quietly virtual signal -install /testbench/depkt1_inst { /testbench/depkt1_inst/o_data_out[499:468]} id001
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group {SRC
} /testbench/src0/clk
add wave -noupdate -expand -group {SRC
} /testbench/src0/reset
add wave -noupdate -expand -group {SRC
} -radix unsigned /testbench/src0/id001
add wave -noupdate -expand -group {SRC
} /testbench/src0/pkt_data_out
add wave -noupdate -expand -group {SRC
} /testbench/src0/pkt_dest_out
add wave -noupdate -expand -group {SRC
} /testbench/src0/pkt_valid_out
add wave -noupdate -expand -group {SRC
} /testbench/src0/pkt_ready_in
add wave -noupdate -expand -group {SRC
} /testbench/src0/data_r
add wave -noupdate -expand -group {SRC
} /testbench/src0/data_next
add wave -noupdate -expand -group {SRC
} /testbench/src0/dest_r
add wave -noupdate -expand -group {SRC
} /testbench/src0/dest_next
add wave -noupdate -expand -group {SRC
} /testbench/src0/valid_r
add wave -noupdate -expand -group {SRC
} /testbench/src0/valid_next
add wave -noupdate -expand -group {SRC
} /testbench/src0/id_r
add wave -noupdate -expand -group {SRC
} /testbench/src0/id_next
add wave -noupdate -expand -group {PKT
} /testbench/pkt0_inst/i_data_in
add wave -noupdate -expand -group {PKT
} /testbench/pkt0_inst/i_valid_in
add wave -noupdate -expand -group {PKT
} /testbench/pkt0_inst/i_dest_in
add wave -noupdate -expand -group {PKT
} /testbench/pkt0_inst/i_ready_out
add wave -noupdate -expand -group {PKT
} /testbench/pkt0_inst/o_data_out
add wave -noupdate -expand -group {PKT
} /testbench/pkt0_inst/o_valid_out
add wave -noupdate -expand -group {PKT
} /testbench/pkt0_inst/o_ready_in
add wave -noupdate -expand -group {DEPKT
} /testbench/depkt1_inst/i_packet_in
add wave -noupdate -expand -group {DEPKT
} /testbench/depkt1_inst/i_valid_in
add wave -noupdate -expand -group {DEPKT
} /testbench/depkt1_inst/i_ready_out
add wave -noupdate -expand -group {DEPKT
} -radix unsigned /testbench/depkt1_inst/id001
add wave -noupdate -expand -group {DEPKT
} {/testbench/depkt1_inst/o_data_out[468]}
add wave -noupdate -expand -group {DEPKT
} /testbench/depkt1_inst/o_data_out
add wave -noupdate -expand -group {DEPKT
} /testbench/depkt1_inst/o_valid_out
add wave -noupdate -expand -group {DEPKT
} /testbench/depkt1_inst/o_ready_in
add wave -noupdate -expand -group {FABRIC_INTERFACE
} /testbench/fabric_interface/i_packets_in
add wave -noupdate -expand -group {FABRIC_INTERFACE
} /testbench/fabric_interface/i_valids_in
add wave -noupdate -expand -group {FABRIC_INTERFACE
} /testbench/fabric_interface/i_readys_out
add wave -noupdate -expand -group {FABRIC_INTERFACE
} /testbench/fabric_interface/o_packets_out
add wave -noupdate -expand -group {FABRIC_INTERFACE
} /testbench/fabric_interface/o_valids_out
add wave -noupdate -expand -group {FABRIC_INTERFACE
} /testbench/fabric_interface/o_readys_in
add wave -noupdate -subitemconfig {{/testbench/pif_buffer[0]} {-height 17 -childformat {{{/testbench/pif_buffer[0].id} -radix unsigned} {{/testbench/pif_buffer[0].send_time} -radix unsigned}} -expand} {/testbench/pif_buffer[0].id} {-height 17 -radix unsigned} {/testbench/pif_buffer[0].send_time} {-height 17 -radix unsigned} {/testbench/pif_buffer[1]} {-height 17 -childformat {{{/testbench/pif_buffer[1].id} -radix unsigned} {{/testbench/pif_buffer[1].send_time} -radix unsigned}} -expand} {/testbench/pif_buffer[1].id} {-height 17 -radix unsigned} {/testbench/pif_buffer[1].send_time} {-height 17 -radix unsigned} {/testbench/pif_buffer[2]} {-height 17 -childformat {{{/testbench/pif_buffer[2].id} -radix unsigned}} -expand} {/testbench/pif_buffer[2].id} {-height 17 -radix unsigned} {/testbench/pif_buffer[3]} {-height 17 -childformat {{{/testbench/pif_buffer[3].id} -radix unsigned}} -expand} {/testbench/pif_buffer[3].id} {-height 17 -radix unsigned}} /testbench/pif_buffer
add wave -noupdate /testbench/cycle_count
add wave -noupdate /testbench/received_pkt_cnt_r
add wave -noupdate /testbench/cum_lat_r
add wave -noupdate /testbench/received_send_time
add wave -noupdate /testbench/received_id
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {57600 ps} 0} {{Cursor 2} {375692 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 299
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {0 ps} {479308 ps}
