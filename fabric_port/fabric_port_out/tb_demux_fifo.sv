/*
 * function: testbench to verify basic tdm ops
 * author  : Mohamed S. Abdelfattah
 * date    : 25-AUG-2014
 */

`timescale 1ns/1ps

module tb_demux_afifo ();

//params
parameter WIDTH = 4;
parameter DEPTH = 32;

//clocks
logic write_clk;
logic read_clk;
logic rtl_clk;
logic rst;
	
//input side
logic [WIDTH-1:0] i_data_in;
logic             i_write_en;
logic             i_full_out;

//output
logic [WIDTH-1:0] o_data_out;
logic             o_read_en;
logic             o_ready_out;

//output of demux
logic [WIDTH*4-1:0] tdm_data_out;
logic               tdm_valid_out;
logic               tdm_ready_in;

//dut
demux
#(
	.WIDTH_IN(WIDTH),
	.WIDTH_OUT(4*WIDTH)
)
dut 
(
	.clk_slow(rtl_clk),
	.clk_fast(read_clk),
	.rst(rst),

	.i_data_in(o_data_out),
	.i_empty_in(~o_ready_out),
	.i_read_en(o_read_en),

	.o_data_out(tdm_data_out),
	.o_valid_out(tdm_valid_out),
	.o_ready_in(tdm_ready_in)
);


afifo_elastic
#(
	.WIDTH(WIDTH),
	.DEPTH(DEPTH)
) 
afifo_inst 
(
	.write_clk(write_clk),
	.read_clk(read_clk),
	.rst(rst),

	.i_data_in(i_data_in),
	.i_write_en(i_write_en),
	.i_ready_out(i_ready_out),

	.o_data_out(o_data_out),
	.o_read_en(o_read_en),
	.o_ready_out(o_ready_out)
);

//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------
int i;
//clocks
initial write_clk = 1'b1;
initial read_clk = 1'b1;
initial rtl_clk = 1'b1;
//toggle forever
always #1 write_clk = ~write_clk;
always #1.25 read_clk = ~read_clk;
always #5 rtl_clk = ~rtl_clk;

//reset
initial rst = 1'b1;

//inputs
initial i_data_in  = 4'bZ;
initial i_write_en = 1'b0;
initial tdm_ready_in = 1'b0;


//some test cases
initial begin

	@(posedge write_clk);
	@(posedge write_clk);
	
	rst = 1'b0;
	tdm_ready_in = 1;
/*
//keep writing through the fifo
for (i = 0; i < 100; )
begin
	if (~rst)
	begin
		
		@ (posedge write_clk)
		
		if (i_ready_out)
		begin
			i_data_in = i;
			i_write_en = 1;
			i=i+1;

			if (i > 50 & i < 56)
			begin
				tdm_ready_in = 0;
			end
			else
				tdm_ready_in = 1;
		end
		else
		begin
			i_write_en = 0;
		end

	end
end
*/

//write 2 packets in the fifo

@ (posedge write_clk)
@ (posedge write_clk)
@ (posedge write_clk)
@ (posedge write_clk)
@ (posedge write_clk)
i_write_en = 1;
i_data_in = 4'b1101;

@ (posedge write_clk)
i_data_in = 4'b1001;

@ (posedge write_clk)
i_data_in = 4'b1001;

@ (posedge write_clk)
i_data_in = 4'b1011;


@ (posedge write_clk)
i_write_en = 0;

@ (posedge write_clk)
i_write_en = 1;
i_data_in = 4'b1100;

@ (posedge write_clk)
i_data_in = 4'b1000;

@ (posedge write_clk)
i_data_in = 4'b1000;

@ (posedge write_clk)
i_data_in = 4'b1010;


@ (posedge write_clk)
i_write_en = 0;


end

endmodule
