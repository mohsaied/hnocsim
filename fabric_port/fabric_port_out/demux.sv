/*
 * function : de-multiplex flits into packets
 * author   : Mohamed S. Abdelfattah
 * date     : 27-AUG-2014
 */

module demux
#(
	parameter WIDTH_IN = 4,
	parameter WIDTH_OUT = WIDTH_IN*4
)
(
	//clocks
	input wire clk_slow,
	input wire clk_fast,
	input wire rst,

	//input side
	input  reg [WIDTH_IN-1:0] i_data_in,
	input  reg                i_empty_in,
	output reg                i_read_en,

	//output side
	output reg [WIDTH_OUT-1:0] o_data_out,
	output reg                 o_valid_out,
	input  reg                 o_ready_in
);

localparam TAIL_POS = WIDTH_IN-3;
reg tail;

//count from 0 to 3
reg [1:0] count;

//buffer output data
reg [WIDTH_OUT-1:0] output_buffer;

//buffers to hold the output while data is being demultiplexed
reg [WIDTH_OUT-1:0] packet_buffer;
reg                 packet_full;
reg                 packet_busy;
reg [WIDTH_OUT-1:0] overflow_buffer;
reg                 overflow_full;
reg                 overflow_busy;
reg valid_out_packet, valid_out_overflow;
reg tail_stall;
reg output_full;

//-------------------------------------------------------------------------------
// Implementation
//-------------------------------------------------------------------------------

//synchronization system
reg [1:0] synchronizer;
reg       sync_start;
reg       synchronized;

//assign sync_start signal if ever we are not synchronized
always @ (posedge clk_slow)
begin

	if (rst)
		sync_start <= 1'b0;
	
	else if (~synchronized)
		sync_start <= 1'b1;

	else
		sync_start <= 1'b0;

end

//synchronizer
always @ (posedge clk_fast)
begin
	
	if (rst) 
		synchronized <= 1'b0;	

	else if (sync_start)
	begin
		synchronizer <= 2'b00;
		synchronized <= 1'b1;
	end

	else if (synchronized)
		synchronizer <= synchronizer + 1;

end


//we can take in one new flit each cycle unless
// 1- something is stalling downstream (o_ready_in)
// 2- buffer is empty upstream (i_empty_in) 
assign i_read_en = ~output_full & ~i_empty_in & (~packet_full | ~overflow_full) & ~(tail_stall & (count != 0) ) & ~(tail & (count != 0) ) & synchronized;
assign o_valid_out = valid_out_packet | valid_out_overflow;



reg valid_i_data;

//valid_input occurs one cycle after a read_en
always @ (posedge clk_fast)
begin
	if (rst) 
		valid_i_data <= 0;
	else
		valid_i_data <= i_read_en;
end

assign tail = valid_i_data ? i_data_in[TAIL_POS] : 0;

//demultiplexer
always @ (posedge clk_fast)
begin

	if (rst)
	begin
		count <= 2'b11;
		packet_full <= 1'b0;
		overflow_full <= 1'b0;
		output_full <= 1'b0;
		tail_stall <= 1'b0;
	end

	
	else 
	begin	
		
		if (valid_i_data | tail_stall | output_full)
		begin
	
			//put data in the right part of output buffer 
			//and increment counter when we are valid
			// or put zeroes if we saw tail

			//tail management
			if (tail & ~tail_stall)
			begin
				output_buffer[(count+1)*WIDTH_IN-1 -: WIDTH_IN] = i_data_in;
				tail_stall = 1;
			end
	
			//we haven't already seen a tail
			if (~tail_stall & ~output_full)
			begin
				output_buffer[(count+1)*WIDTH_IN-1 -: WIDTH_IN] = i_data_in;
			end
			
			//we saw a tail and want to zero out the rest
			else if (~tail & tail_stall)
			begin
				output_buffer[(count+1)*WIDTH_IN-1 -: WIDTH_IN] = 0;
			end

			//decrement count
			if (~output_full)
				count <= count - 1;
	
			//once we have all of our flits signal one of 
			//the ready signal to tell the other clock domain
			//to get to read the data out of output buffer
			if (count == 2'b00)
			begin
				tail_stall = 0;
	
				if (~packet_full)
				begin
					packet_buffer <= output_buffer;
					packet_full <= 1'b1;
					if (output_full)
					begin
						output_full <= 1'b0;
						count <= count - 1;
					end
				end
				
				else if (~overflow_full)
				begin
					overflow_buffer <= output_buffer;
					overflow_full <= 1'b1;
					if (output_full)	
					begin
						output_full <= 1'b0;
						count <= count - 1;
					end
				end

				// we don't actually have any space but we arrogantly read something anyways
				// in this case we need to keep that data in output buffer or
				// some other buffer and only forward it to one of the
				// packet/overflow buffers whence they become available
				else
				begin
					//flag that we can't overwrite the output buffer
					output_full <= 1'b1;
					//stay in the transfer count stage
					count <= 2'b00;
				end

			end
	
		end

		if (synchronizer == 2'b10)
		begin

			//disable ready signals after ack signals are received 
			//to complete the handshake between the 2 clocks
			if (valid_out_packet)
				packet_full <= 1'b0;
	
			if (valid_out_overflow)
				overflow_full <= 1'b0;
		end
	
	end
end

reg [1:0] state;
parameter READ_PACKET   = 2'b00,
		  READ_OVERFLOW = 2'b01;

//read state machine
always @ (posedge clk_slow)
begin

	if (rst)
	begin
		o_data_out <= 0;
		packet_busy <= 0;
		overflow_busy <= 0;
		valid_out_packet <= 0;
		valid_out_overflow <= 0;
		state = READ_PACKET;
	end

	else if (state == READ_PACKET)
	begin
		
		//must wait for a "ready" to come along
		if (packet_full)
			packet_busy = 1; // this means we want to write out of this
		if (overflow_full)
			overflow_busy = 1; // this means we want to write out of this as well
		
		//if we have something to write and we arent stalling
		if (packet_busy & o_ready_in)
		begin
			o_data_out <= packet_buffer;
			valid_out_packet <= 1'b1;
			valid_out_overflow <= 1'b0;
			packet_busy = 0;
			if(overflow_busy)
				state = READ_OVERFLOW;
		end
		
		//packet not busy but overflow is busy
		else if (overflow_busy & o_ready_in)
		begin
			o_data_out <= overflow_buffer;
			valid_out_packet <= 1'b0;
			valid_out_overflow <= 1'b1;
			overflow_busy = 0;
		end

		else if (~packet_busy & overflow_busy & ~o_ready_in)
		begin
			valid_out_packet <= 1'b0;	
			valid_out_overflow <= 1'b0;
			state = READ_OVERFLOW;
		end

		else
		begin
			valid_out_packet <= 1'b0;	
			valid_out_overflow <= 1'b0;
		end

	end
	
	else if (state == READ_OVERFLOW)
	begin
		
		//must wait for a "ready" to come along
		if (packet_full)
			packet_busy = 1; // this means we want to write out of this
		if (overflow_full)
			overflow_busy = 1; // this means we want to write out of this as well
		
		//if we have something to write and we arent stalling
		if (overflow_busy & o_ready_in)
		begin
			o_data_out <= overflow_buffer;
			valid_out_packet <= 1'b0;
			valid_out_overflow <= 1'b1;
			overflow_busy = 0;
			state = READ_PACKET;
		end
		
		//this should be dead code!
		else if (packet_busy & o_ready_in)
		begin
			o_data_out <= packet_buffer;
			valid_out_packet <= 1'b1;
			valid_out_overflow <= 1'b0;
			packet_busy = 0;
		end

		else 
		begin
			valid_out_packet <= 1'b0;
			valid_out_overflow <= 1'b0;
		end

	end

end

endmodule

