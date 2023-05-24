onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/clk_rtl
add wave -noupdate -radix hexadecimal /testbench/i_packets_in
add wave -noupdate /testbench/i_valids_in
add wave -noupdate -radix hexadecimal /testbench/pkt_data_in
add wave -noupdate /testbench/pkt_valid_in
add wave -noupdate -radix hexadecimal /testbench/pkt_dest_in
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/WIDTH_NOC}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/N}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/NUM_VC}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/DEPTH_PER_VC}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/WIDTH_RTL}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/ADDRESS_WIDTH}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/VC_ADDRESS_WIDTH}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/clk_rtl}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/clk_int}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/clk_noc}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/rst}
add wave -noupdate -expand -group fp0 -radix hexadecimal {/testbench/dut/fps[0]/fpin_inst/rtl_packet_in}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/rtl_valid_in}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/rtl_ready_out}
add wave -noupdate -expand -group fp0 -radix hexadecimal {/testbench/dut/fps[0]/fpin_inst/noc_flit_out}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/noc_credits_in}
add wave -noupdate -expand -group fp0 -radix hexadecimal {/testbench/dut/fps[0]/fpin_inst/t_a_data}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/t_a_valid}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/t_a_ready}
add wave -noupdate -expand -group fp0 -radix hexadecimal {/testbench/dut/fps[0]/fpin_inst/a_n_data}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/a_n_read_en}
add wave -noupdate -expand -group fp0 {/testbench/dut/fps[0]/fpin_inst/a_n_ready}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/WIDTH_NOC}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/N}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/NUM_VC}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/DEPTH_PER_VC}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/WIDTH_RTL}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/ADDRESS_WIDTH}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/VC_ADDRESS_WIDTH}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/clk_noc}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/clk_rtl}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/clk_int}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/rst}
add wave -noupdate -expand -group fpout15 -radix hexadecimal {/testbench/dut/fps[15]/fpout_inst/noc_flit_in}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/noc_credits_out}
add wave -noupdate -expand -group fpout15 -radix hexadecimal {/testbench/dut/fps[15]/fpout_inst/rtl_packet_out}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/rtl_valid_out}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/rtl_ready_in}
add wave -noupdate -expand -group fpout15 -radix hexadecimal {/testbench/dut/fps[15]/fpout_inst/n_a_data}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/n_a_write}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/n_a_ready}
add wave -noupdate -expand -group fpout15 -radix hexadecimal {/testbench/dut/fps[15]/fpout_inst/a_d_data}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/a_d_read}
add wave -noupdate -expand -group fpout15 {/testbench/dut/fps[15]/fpout_inst/a_d_ready}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/WIDTH_IN}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/WIDTH_OUT}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/TAIL_POS}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/READ_PACKET}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/READ_OVERFLOW}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/clk_slow}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/clk_fast}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/rst}
add wave -noupdate -expand -group fpout15demux -radix hexadecimal {/testbench/dut/fps[15]/fpout_inst/demux_inst/i_data_in}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/i_empty_in}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/i_read_en}
add wave -noupdate -expand -group fpout15demux -radix hexadecimal {/testbench/dut/fps[15]/fpout_inst/demux_inst/o_data_out}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/o_valid_out}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/o_ready_in}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/tail}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/count}
add wave -noupdate -expand -group fpout15demux -radix hexadecimal {/testbench/dut/fps[15]/fpout_inst/demux_inst/output_buffer}
add wave -noupdate -expand -group fpout15demux -radix hexadecimal {/testbench/dut/fps[15]/fpout_inst/demux_inst/packet_buffer}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/packet_full}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/packet_busy}
add wave -noupdate -expand -group fpout15demux -radix hexadecimal {/testbench/dut/fps[15]/fpout_inst/demux_inst/overflow_buffer}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/overflow_full}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/overflow_busy}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/valid_out_packet}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/valid_out_overflow}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/tail_stall}
add wave -noupdate -expand -group fpout15demux {/testbench/dut/fps[15]/fpout_inst/demux_inst/valid_i_data}
add wave -noupdate -expand -group fpout15demux -radix hexadecimal {/testbench/dut/fps[15]/fpout_inst/demux_inst/state}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {136000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 190
configure wave -valuecolwidth 260
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
WaveRestoreZoom {50234 ps} {218409 ps}
