rm -rf work
vlib work
vlog *.sv
vsim -do wave.do
vsim testbench
run -all
