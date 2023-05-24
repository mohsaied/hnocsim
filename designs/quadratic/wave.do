onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/clk_ints
add wave -noupdate /testbench/clk_nocs
add wave -noupdate /testbench/rst
add wave -noupdate -radix unsigned /testbench/i_x
add wave -noupdate /testbench/i_valid
add wave -noupdate /testbench/o_ready
add wave -noupdate /testbench/o_valid
add wave -noupdate -radix unsigned /testbench/o_y
add wave -noupdate -radix unsigned /testbench/good_y
add wave -noupdate /testbench/i
add wave -noupdate /testbench/cycle_count
add wave -noupdate -radix unsigned /testbench/prod_rand
add wave -noupdate /testbench/prod_i
add wave -noupdate -radix unsigned /testbench/cns_rand
add wave -noupdate -radix unsigned /testbench/cns_x
add wave -noupdate /testbench/fail
add wave -noupdate /testbench/cns_i
add wave -noupdate -expand -group multx /testbench/dut/multx_inst/clk
add wave -noupdate -expand -group multx /testbench/dut/multx_inst/rst
add wave -noupdate -expand -group multx -radix unsigned /testbench/dut/multx_inst/i_x
add wave -noupdate -expand -group multx /testbench/dut/multx_inst/i_valid_in
add wave -noupdate -expand -group multx /testbench/dut/multx_inst/i_ready_out
add wave -noupdate -expand -group multx -radix unsigned /testbench/dut/multx_inst/o_y
add wave -noupdate -expand -group multx /testbench/dut/multx_inst/o_valid_out
add wave -noupdate -expand -group multx /testbench/dut/multx_inst/o_ready_in
add wave -noupdate -group multa /testbench/dut/multa_inst/clk
add wave -noupdate -group multa /testbench/dut/multa_inst/rst
add wave -noupdate -group multa -radix unsigned /testbench/dut/multa_inst/i_x
add wave -noupdate -group multa /testbench/dut/multa_inst/i_valid_in
add wave -noupdate -group multa /testbench/dut/multa_inst/i_ready_out
add wave -noupdate -group multa -radix unsigned /testbench/dut/multa_inst/o_y
add wave -noupdate -group multa /testbench/dut/multa_inst/o_valid_out
add wave -noupdate -group multa /testbench/dut/multa_inst/o_ready_in
add wave -noupdate -group addc /testbench/dut/addc_inst/clk
add wave -noupdate -group addc /testbench/dut/addc_inst/rst
add wave -noupdate -group addc -radix unsigned /testbench/dut/addc_inst/i_x
add wave -noupdate -group addc /testbench/dut/addc_inst/i_valid_in
add wave -noupdate -group addc /testbench/dut/addc_inst/i_ready_out
add wave -noupdate -group addc -radix unsigned /testbench/dut/addc_inst/o_y
add wave -noupdate -group addc /testbench/dut/addc_inst/o_valid_out
add wave -noupdate -group addc /testbench/dut/addc_inst/o_ready_in
add wave -noupdate -group fpin_multx {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/clk_rtl}
add wave -noupdate -group fpin_multx {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/clk_int}
add wave -noupdate -group fpin_multx {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/clk_noc}
add wave -noupdate -group fpin_multx {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/rst}
add wave -noupdate -group fpin_multx -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/rtl_packet_in}
add wave -noupdate -group fpin_multx {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/rtl_valid_in}
add wave -noupdate -group fpin_multx {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/rtl_ready_out}
add wave -noupdate -group fpin_multx -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/noc_flit_out}
add wave -noupdate -group fpin_multx {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/noc_credits_in}
add wave -noupdate -group fpin_multx -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/t_a_data}
add wave -noupdate -group fpin_multx {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/t_a_valid}
add wave -noupdate -group fpin_multx {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/t_a_ready}
add wave -noupdate -group fpin_multx -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/a_n_data}
add wave -noupdate -group fpin_multx {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/a_n_read_en}
add wave -noupdate -group fpin_multx {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/a_n_ready}
add wave -noupdate -expand -group fpin_multx_tdm {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/clk_slow}
add wave -noupdate -expand -group fpin_multx_tdm {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/clk_fast}
add wave -noupdate -expand -group fpin_multx_tdm {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/rst}
add wave -noupdate -expand -group fpin_multx_tdm -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/i_data_in}
add wave -noupdate -expand -group fpin_multx_tdm {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/i_valid_in}
add wave -noupdate -expand -group fpin_multx_tdm {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/i_ready_out}
add wave -noupdate -expand -group fpin_multx_tdm -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/o_data_out}
add wave -noupdate -expand -group fpin_multx_tdm {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/o_valid_out}
add wave -noupdate -expand -group fpin_multx_tdm {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/o_ready_in}
add wave -noupdate -expand -group fpin_multx_tdm {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/count}
add wave -noupdate -expand -group fpin_multx_tdm -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/data_buffer}
add wave -noupdate -expand -group fpin_multx_tdm {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/data_buffer_valid}
add wave -noupdate -expand -group fpin_multx_tdm -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/overflow_buffer}
add wave -noupdate -expand -group fpin_multx_tdm {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/overflow_buffer_valid}
add wave -noupdate -expand -group fpin_multx_tdm {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/synchronizer}
add wave -noupdate -expand -group fpin_multx_tdm {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/sync_start}
add wave -noupdate -expand -group fpin_multx_tdm {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/synchronized}
add wave -noupdate -expand -group fpin_multx_tdm -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/tdm_inst/mux_data}
add wave -noupdate -group fpin_multx_afifo {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/afifo_elastic_inst/write_clk}
add wave -noupdate -group fpin_multx_afifo {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/afifo_elastic_inst/read_clk}
add wave -noupdate -group fpin_multx_afifo {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/afifo_elastic_inst/rst}
add wave -noupdate -group fpin_multx_afifo -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/afifo_elastic_inst/i_data_in}
add wave -noupdate -group fpin_multx_afifo {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/afifo_elastic_inst/i_write_en}
add wave -noupdate -group fpin_multx_afifo {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/afifo_elastic_inst/i_ready_out}
add wave -noupdate -group fpin_multx_afifo -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/afifo_elastic_inst/o_data_out}
add wave -noupdate -group fpin_multx_afifo {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/afifo_elastic_inst/o_read_en}
add wave -noupdate -group fpin_multx_afifo {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/afifo_elastic_inst/o_ready_out}
add wave -noupdate -group fpin_multx_afifo -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/afifo_elastic_inst/overflow_buffer}
add wave -noupdate -group fpin_multx_afifo {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/afifo_elastic_inst/overflow_buffer_valid}
add wave -noupdate -group fpin_multx_afifo {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/afifo_elastic_inst/read_overflow}
add wave -noupdate -group fpin_multx_afifo -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/afifo_elastic_inst/fifo_data_in}
add wave -noupdate -group fpin_multx_afifo {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/afifo_elastic_inst/fifo_full}
add wave -noupdate -group fpin_multx_afifo {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/afifo_elastic_inst/fifo_empty}
add wave -noupdate -group fpin_multx_noc_writer {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/noc_writer_inst/clk}
add wave -noupdate -group fpin_multx_noc_writer {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/noc_writer_inst/rst}
add wave -noupdate -group fpin_multx_noc_writer -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/noc_writer_inst/i_data_in}
add wave -noupdate -group fpin_multx_noc_writer {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/noc_writer_inst/i_ready_in}
add wave -noupdate -group fpin_multx_noc_writer {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/noc_writer_inst/i_read_en}
add wave -noupdate -group fpin_multx_noc_writer -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/noc_writer_inst/o_flit_out}
add wave -noupdate -group fpin_multx_noc_writer {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/noc_writer_inst/o_credits_in}
add wave -noupdate -group fpin_multx_noc_writer {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/noc_writer_inst/current_vc}
add wave -noupdate -group fpin_multx_noc_writer {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/noc_writer_inst/valid_out}
add wave -noupdate -group fpin_multx_noc_writer -radix unsigned {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/noc_writer_inst/credit_count}
add wave -noupdate -group fpin_multx_noc_writer {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/noc_writer_inst/vc_available}
add wave -noupdate -group fpin_multx_noc_writer {/testbench/dut/fabric_interface_inst/fps[0]/fpin_inst/noc_writer_inst/possible_data_received}
add wave -noupdate -group fpout_multa {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/clk_noc}
add wave -noupdate -group fpout_multa {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/clk_rtl}
add wave -noupdate -group fpout_multa {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/clk_int}
add wave -noupdate -group fpout_multa {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/rst}
add wave -noupdate -group fpout_multa -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_flit_in}
add wave -noupdate -group fpout_multa {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_credits_out}
add wave -noupdate -group fpout_multa -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/rtl_packet_out}
add wave -noupdate -group fpout_multa {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/rtl_valid_out}
add wave -noupdate -group fpout_multa {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/rtl_ready_in}
add wave -noupdate -group fpout_multa {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/n_a_data}
add wave -noupdate -group fpout_multa {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/n_a_write}
add wave -noupdate -group fpout_multa {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/n_a_ready}
add wave -noupdate -group fpout_multa {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/a_d_data}
add wave -noupdate -group fpout_multa {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/a_d_read}
add wave -noupdate -group fpout_multa {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/a_d_ready}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/clk_slow}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/clk_fast}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/rst}
add wave -noupdate -group fpout_multa_demux -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/i_data_in}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/i_empty_in}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/i_read_en}
add wave -noupdate -group fpout_multa_demux -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/o_data_out}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/o_valid_out}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/o_ready_in}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/tail}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/count}
add wave -noupdate -group fpout_multa_demux -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/output_buffer}
add wave -noupdate -group fpout_multa_demux -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/packet_buffer}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/packet_full}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/packet_busy}
add wave -noupdate -group fpout_multa_demux -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/overflow_buffer}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/overflow_full}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/overflow_busy}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/valid_out_packet}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/valid_out_overflow}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/tail_stall}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/valid_i_data}
add wave -noupdate -group fpout_multa_demux {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/demux_inst/state}
add wave -noupdate -group fpout_multa_afifo {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/afifo_inst/write_clk}
add wave -noupdate -group fpout_multa_afifo {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/afifo_inst/read_clk}
add wave -noupdate -group fpout_multa_afifo {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/afifo_inst/rst}
add wave -noupdate -group fpout_multa_afifo -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/afifo_inst/i_data_in}
add wave -noupdate -group fpout_multa_afifo {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/afifo_inst/i_write_en}
add wave -noupdate -group fpout_multa_afifo {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/afifo_inst/i_ready_out}
add wave -noupdate -group fpout_multa_afifo -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/afifo_inst/o_data_out}
add wave -noupdate -group fpout_multa_afifo {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/afifo_inst/o_read_en}
add wave -noupdate -group fpout_multa_afifo {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/afifo_inst/o_ready_out}
add wave -noupdate -group fpout_multa_afifo -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/afifo_inst/overflow_buffer}
add wave -noupdate -group fpout_multa_afifo {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/afifo_inst/overflow_buffer_valid}
add wave -noupdate -group fpout_multa_afifo {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/afifo_inst/read_overflow}
add wave -noupdate -group fpout_multa_afifo {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/afifo_inst/fifo_data_in}
add wave -noupdate -group fpout_multa_afifo {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/afifo_inst/fifo_full}
add wave -noupdate -group fpout_multa_afifo {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/afifo_inst/fifo_empty}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/clk}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/rst}
add wave -noupdate -group fpout_multa_noc_reader -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/i_flit_in}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/i_credits_out}
add wave -noupdate -group fpout_multa_noc_reader -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/o_data_out}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/o_write_en}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/o_ready_in}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/valid}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/fifo_write_vc}
add wave -noupdate -group fpout_multa_noc_reader -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/fifo_data_in}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/fifo_write_en}
add wave -noupdate -group fpout_multa_noc_reader -radix hexadecimal {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/fifo_data_out}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/fifo_read_en}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/fifo_empty}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/fifo_almost_empty}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/fifo_next_is_tail}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/i}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/fifo_read_vc}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/past_fifo_read_vc}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/vc_changed}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/state}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/fifo_read_vc_reg}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/fifo_read_vc_reg2}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/fifo_read_en_reg}
add wave -noupdate -group fpout_multa_noc_reader {/testbench/dut/fabric_interface_inst/fps[1]/fpout_inst/noc_reader_inst/fifo_read_en_reg2}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 7} {149937 ps} 0} {{Cursor 8} {139942 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 244
configure wave -valuecolwidth 240
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
WaveRestoreZoom {111795 ps} {195687 ps}
