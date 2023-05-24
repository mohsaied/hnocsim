/* 
 * function : quadratic equation solver Y = Ax^2 + Bx + C
 * author   : Mohamed S. Abdelfattah
 * date     : 4-SEPT-2014
 */

`timescale 1ns/1ps

module mult_a
#(
	parameter WIDTH = 16,
	parameter [WIDTH-1:0] A = 16'd101,
	parameter [WIDTH-1:0] B = 16'd59,
	parameter [WIDTH-1:0] C = 16'd76
)
(
	input clk,
	input rst,
				
	input [WIDTH-1:0] i_x,
	input             i_valid_in,
	output reg        i_ready_out,
	
	output reg [WIDTH-1:0] o_y,
	output reg             o_valid_out,
	input                  o_ready_in				
);

reg output_ready;

assign i_ready_out = o_ready_in;

always @ (posedge clk)
begin
	if(rst)
	begin
		o_y <= 0;
		o_valid_out <= 0;
		output_ready = 1'b0;
	end

	else
	begin
		if (i_valid_in)
		begin
			o_y <= A * i_x;
			output_ready = 1'b1;
		end
		
		if (o_ready_in & output_ready)
		begin
			o_valid_out <= 1'b1;
			output_ready = 1'b0;
		end
		else
			o_valid_out <= 1'b0;
	end

end

endmodule

