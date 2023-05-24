onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/cycle_count
add wave -noupdate /testbench/clk_noc
add wave -noupdate /testbench/clk_ints
add wave -noupdate /testbench/clk_rtls
add wave -noupdate -radix unsigned /testbench/pkt_data_in
add wave -noupdate /testbench/pkt_valid_in
add wave -noupdate /testbench/pkt_dest_in
add wave -noupdate /testbench/pkt_ready_out
add wave -noupdate /testbench/fail
add wave -noupdate -radix unsigned /testbench/good_y
add wave -noupdate -radix unsigned /testbench/pkt_data_out
add wave -noupdate /testbench/dut/clk
add wave -noupdate /testbench/pkt_valid_out
add wave -noupdate /testbench/pkt_ready_in
add wave -noupdate /testbench/dut/rst
add wave -noupdate -radix binary /testbench/dut/clk_rtl
add wave -noupdate -radix hexadecimal /testbench/dut/i_packets_in
add wave -noupdate -radix hexadecimal /testbench/dut/o_packets_out
add wave -noupdate /testbench/dut/i_readys_out
add wave -noupdate /testbench/dut/o_readys_in
add wave -noupdate /testbench/dut/i_valids_in
add wave -noupdate /testbench/dut/o_valids_out
add wave -noupdate /testbench/dut/p_id
add wave -noupdate /testbench/dut/next_p_id
add wave -noupdate /testbench/dut/f_id
add wave -noupdate /testbench/dut/head
add wave -noupdate /testbench/dut/tail
add wave -noupdate /testbench/dut/valid
add wave -noupdate /testbench/dut/src
add wave -noupdate /testbench/dut/dest
add wave -noupdate /testbench/dut/assigned_vc
add wave -noupdate /testbench/dut/cycle_count
add wave -noupdate /testbench/dut/valid_from_noc
add wave -noupdate -radix hexadecimal /testbench/dut/fifoin_packets
add wave -noupdate /testbench/dut/fifoin_read_en
add wave -noupdate /testbench/dut/fifoin_readys_out
add wave -noupdate /testbench/dut/fifoout_valids
add wave -noupdate /testbench/dut/mm
add wave -noupdate -expand -group afifo {/testbench/dut/ibufs[0]/fifo_in/WIDTH}
add wave -noupdate -expand -group afifo {/testbench/dut/ibufs[0]/fifo_in/DEPTH}
add wave -noupdate -expand -group afifo {/testbench/dut/ibufs[0]/fifo_in/write_clk}
add wave -noupdate -expand -group afifo {/testbench/dut/ibufs[0]/fifo_in/read_clk}
add wave -noupdate -expand -group afifo {/testbench/dut/ibufs[0]/fifo_in/rst}
add wave -noupdate -expand -group afifo -radix hexadecimal {/testbench/dut/ibufs[0]/fifo_in/i_data_in}
add wave -noupdate -expand -group afifo {/testbench/dut/ibufs[0]/fifo_in/i_write_en}
add wave -noupdate -expand -group afifo {/testbench/dut/ibufs[0]/fifo_in/i_ready_out}
add wave -noupdate -expand -group afifo -radix hexadecimal {/testbench/dut/ibufs[0]/fifo_in/o_data_out}
add wave -noupdate -expand -group afifo {/testbench/dut/ibufs[0]/fifo_in/o_read_en}
add wave -noupdate -expand -group afifo {/testbench/dut/ibufs[0]/fifo_in/o_ready_out}
add wave -noupdate -expand -group afifo -radix hexadecimal {/testbench/dut/ibufs[0]/fifo_in/overflow_buffer}
add wave -noupdate -expand -group afifo {/testbench/dut/ibufs[0]/fifo_in/overflow_buffer_valid}
add wave -noupdate -expand -group afifo {/testbench/dut/ibufs[0]/fifo_in/read_overflow}
add wave -noupdate -expand -group afifo -radix hexadecimal {/testbench/dut/ibufs[0]/fifo_in/fifo_data_in}
add wave -noupdate -expand -group afifo {/testbench/dut/ibufs[0]/fifo_in/fifo_full}
add wave -noupdate -expand -group afifo {/testbench/dut/ibufs[0]/fifo_in/fifo_empty}
add wave -noupdate -expand -group afifo {/testbench/dut/ibufs[0]/fifo_in/afifo_inst/memory}
add wave -noupdate -expand -group afifo_out {/testbench/dut/ibufs[1]/fifo_out/WIDTH}
add wave -noupdate -expand -group afifo_out {/testbench/dut/ibufs[1]/fifo_out/DEPTH}
add wave -noupdate -expand -group afifo_out {/testbench/dut/ibufs[1]/fifo_out/write_clk}
add wave -noupdate -expand -group afifo_out {/testbench/dut/ibufs[1]/fifo_out/read_clk}
add wave -noupdate -expand -group afifo_out {/testbench/dut/ibufs[1]/fifo_out/rst}
add wave -noupdate -expand -group afifo_out -radix hexadecimal {/testbench/dut/ibufs[1]/fifo_out/i_data_in}
add wave -noupdate -expand -group afifo_out {/testbench/dut/ibufs[1]/fifo_out/i_write_en}
add wave -noupdate -expand -group afifo_out {/testbench/dut/fifoout_valids[1]}
add wave -noupdate -expand -group afifo_out {/testbench/dut/ibufs[1]/fifo_out/i_ready_out}
add wave -noupdate -expand -group afifo_out -radix hexadecimal {/testbench/dut/ibufs[1]/fifo_out/o_data_out}
add wave -noupdate -expand -group afifo_out {/testbench/dut/o_valids_out[1]}
add wave -noupdate -expand -group afifo_out {/testbench/dut/ibufs[1]/fifo_out/o_read_en}
add wave -noupdate -expand -group afifo_out {/testbench/dut/ibufs[1]/fifo_out/o_ready_out}
add wave -noupdate -expand -group afifo_out -radix hexadecimal {/testbench/dut/ibufs[1]/fifo_out/overflow_buffer}
add wave -noupdate -expand -group afifo_out {/testbench/dut/ibufs[1]/fifo_out/overflow_buffer_valid}
add wave -noupdate -expand -group afifo_out {/testbench/dut/ibufs[1]/fifo_out/read_overflow}
add wave -noupdate -expand -group afifo_out -radix hexadecimal {/testbench/dut/ibufs[1]/fifo_out/fifo_data_in}
add wave -noupdate -expand -group afifo_out {/testbench/dut/ibufs[1]/fifo_out/fifo_full}
add wave -noupdate -expand -group afifo_out {/testbench/dut/ibufs[1]/fifo_out/fifo_empty}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {87961 ps} 0} {{Cursor 2} {112124 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 211
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
configure wave -timelineunits ns
update
WaveRestoreZoom {79906 ps} {120701 ps}
