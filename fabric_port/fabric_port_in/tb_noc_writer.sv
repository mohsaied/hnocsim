/*
 * function: testbench to verify basic ops
 * author  : Mohamed S. Abdelfattah
 * date    : 25-AUG-2014
 */


module tb_noc_writer ();

//params
parameter DEPTH  = 4;
parameter WIDTH  = 16;
parameter N      = 16;
parameter NUM_VC = 2;
parameter DEPTH_PER_VC = 10;

//clocks
logic clk;
logic rst;
	
//input side
logic [WIDTH-1:0] i_data_in;
logic             i_ready_in;
logic             i_read_en;

//output
logic [WIDTH-1:0]  o_flit_out;
logic [NUM_VC-1:0] o_credits_in;

//using same signal names
noc_writer dut ( .* );

//for the fifo
logic [WIDTH-1:0] fifo_data_in;
logic write_clk;
logic fifo_write_en;
logic fifo_ready_out;

//produce stimuli using a fifo
afifo_elastic
#(
	.WIDTH(WIDTH),
	.DEPTH(DEPTH)
)
producer
(
	.write_clk(write_clk),
	.read_clk(clk),
	.rst(rst),

	.i_data_in(fifo_data_in),
	.i_write_en(fifo_write_en),
	.i_ready_out(fifo_ready_out),

	.o_data_out(i_data_in),
	.o_read_en(i_read_en),
	.o_ready_out(i_ready_in)
);

//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

//clocks
initial write_clk = 1'b1;
initial clk = 1'b1;
//toggle forever
always #5 write_clk = ~write_clk;
always #4 clk = ~clk;

//reset
initial rst = 1'b1;

//inputs
initial fifo_data_in  = 16'bZ;
initial fifo_write_en = 1'b0;
initial o_credits_in = 0;


//some test cases
initial begin

	@(posedge write_clk);
	@(posedge write_clk);
	
	rst = 1'b0;
	fifo_data_in = 16'h8000;
	

	@(posedge write_clk);
	
end

//we'll keep writing to the fifo
always @ (posedge write_clk)
begin
if(~rst)
begin

	if(fifo_ready_out)
	begin
		fifo_write_en <= 1'b1;
		fifo_data_in = fifo_data_in + 1;
	end

	else
		fifo_write_en <= 1'b0;

end
end

//send a credit back at 20ns to VC 1
//always #199 o_credits_in <= 2'b10;
//always #207 o_credits_in <= 2'b00;

endmodule
