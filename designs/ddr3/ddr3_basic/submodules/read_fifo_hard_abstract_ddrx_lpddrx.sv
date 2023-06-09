// (C) 2001-2014 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// ******************************************************************************************************************************** 

// File name: read_fifo_hard.sv

// Abstract version of read_fifo_hard.v

// ******************************************************************************************************************************** 



`timescale 1 ps / 1 ps






module read_fifo_hard_abstract_ddrx_lpddrx (

	write_clk,





	read_clk,

	read_enable,

	reset_n,

	datain,

	dataout

);



// ******************************************************************************************************************************** 

// BEGIN PARAMETER SECTION

// All parameters default to "" will have their values passed in from higher level wrapper with the controller and driver 



parameter DQ_GROUP_WIDTH = 0;	








localparam RATE_MULT = 2;








// END PARAMETER SECTION

// ******************************************************************************************************************************** 



input	write_clk;



input	read_clk;

input	read_enable;

input	reset_n;

input	[DQ_GROUP_WIDTH*2-1:0] datain;

output	[RATE_MULT*DQ_GROUP_WIDTH*2-1:0] dataout;





// ******************************************************************************************************************************** 

// Instantiate write-enable circuitry inside the DQS logic block

// ******************************************************************************************************************************** 




// The read_clk is expected to be a strobe that only toggles when there

// is valid data, so wren is tied to 1

wire wren = 1'b1;

	









localparam DEPTH_LOG = 4;	

localparam DEPTH = 1 << DEPTH_LOG;





reg [(2*DQ_GROUP_WIDTH)-1:0] read_fifo[0:DEPTH-1];

reg [DEPTH_LOG-1:0] fifo_read_addr = 0;

reg [DEPTH_LOG-1:0] fifo_write_addr = 0;



reg [(RATE_MULT*DQ_GROUP_WIDTH*2)-1:0] fifo_data_out = 0;



assign dataout = fifo_data_out;




wire #10 write_clk_delayed = write_clk;




always @(negedge write_clk_delayed or negedge reset_n)

begin

   	if (~reset_n == 1'b1)

   	begin 

   		fifo_write_addr <= 0;

		for (int i = 0; i < DEPTH; i++) begin

			read_fifo[i] <= '1;

		end

   	end

   	else

	begin

   		if (wren == 1'b1) 

		begin

			read_fifo[fifo_write_addr] <= datain;

   			fifo_write_addr <= fifo_write_addr + 1'b1;

		end

   	end

end



always @(posedge read_clk or negedge reset_n)

begin

   	if (~reset_n == 1'b1)

   	begin 

   		fifo_read_addr <= 0;

   	end

   	else

	begin

		if (read_enable == 1'b1)

		begin

			fifo_read_addr <= fifo_read_addr + RATE_MULT;

		end

		fifo_data_out[2*DQ_GROUP_WIDTH-1:0] <= read_fifo[fifo_read_addr];

		if (RATE_MULT == 2)

		begin

			fifo_data_out[4*DQ_GROUP_WIDTH-1:2*DQ_GROUP_WIDTH] <= read_fifo[fifo_read_addr+1];

		end

	end

end





endmodule

