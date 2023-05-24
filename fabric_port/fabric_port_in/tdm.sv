/*
 * fuction: 4:1 time-domain multiplexing
 * author : Mohamed S. Abdelfattah
 * date   : 25-AUG-2014
 */

module tdm 
#(
	parameter WIDTH_IN = 16, 
	parameter WIDTH_OUT = WIDTH_IN/4
)
(
	//clocks
	input wire clk_slow,
	input wire clk_fast,
	input wire rst,
	
	//input side
	input  reg [WIDTH_IN-1:0] i_data_in,
	input  reg                i_valid_in,
	output reg                i_ready_out,

	//output
	output reg [WIDTH_OUT-1:0] o_data_out,
	output reg                 o_valid_out,
	input  reg                 o_ready_in
);

localparam VALID_POS = WIDTH_OUT-1;

//count from 0 to 3
reg [1:0] count;

//buffers to hold data waiting to be multiplexed
reg [WIDTH_IN-1:0] data_buffer;
reg                data_buffer_valid;

reg [WIDTH_IN-1:0] overflow_buffer;
reg                overflow_buffer_valid;

//synchronization system
reg [1:0] synchronizer;
reg       sync_start;
reg       synchronized;

//mux input data
reg [WIDTH_IN-1:0] mux_data;

//reg to indicate if we have space for data
reg ready;

//------------------------------------------------------------------------
// Implementation
//------------------------------------------------------------------------

//assign upstream ready signal
assign i_ready_out = ~rst & synchronized & ready;

/*
//synopsys translate off

integer dbg;
int cycle_count;
initial 
begin
	cycle_count = 0;
	dbg = $fopen("tdm.dbg","a");
end

always @ (posedge clk_slow)
begin
	cycle_count = cycle_count + 1;
	if (i_ready_out == 0)
		$fwrite(dbg,"%d | tdm is stalling. ready = %d, data_buffer_valid = %d, overflow_buffer_valid = %d\n",cycle_count,ready,data_buffer_valid,overflow_buffer_valid);
end

//synopsys translate on
*/

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
		synchronizer <= 2'b10;
		synchronized <= 1'b1;
	end

	else if (synchronized)
		synchronizer <= synchronizer + 1;

end

//data input --> buffer
always @ (posedge clk_fast)
begin
	
	if(rst)
	begin
		data_buffer_valid <= 1'b0;
		overflow_buffer_valid <= 1'b0;		
		count <= 2'b00;
		o_valid_out <= 1'b0;
		ready = 1'b1;
	end
	
	else
	begin
		
		//this is when we read data in
		if (synchronizer == 2'b00)
		begin
			
			//transfer from overflow buffer to main buffer
			if (overflow_buffer_valid & ~data_buffer_valid)
			begin
				data_buffer <= overflow_buffer;
				data_buffer_valid <= 1'b1;
				overflow_buffer_valid <= 1'b0;
				ready <= 1'b1;
				// do we have data to write from input during the switch?
				if (i_valid_in)
				begin
					overflow_buffer <= i_data_in;
					overflow_buffer_valid <= 1'b1;
					ready <= 1'b0;
				end
			end
	
			//read data into the main buffer
			else if (i_valid_in & ~data_buffer_valid)
			begin
				data_buffer <= i_data_in;
				data_buffer_valid <= 1'b1;
				ready <= ~overflow_buffer_valid;
			end
			
			//read data into the overflow buffer
			else if (i_valid_in & data_buffer_valid)
			begin
				overflow_buffer <= i_data_in;
				overflow_buffer_valid <= 1'b1;
				ready <= 1'b0;
			end

		end 		

		if (o_ready_in)
		begin
	
			if (count == 2'b00)
			begin
			
				o_valid_out = 1'b0;
				
				if (data_buffer_valid)
				begin
					mux_data = data_buffer;
					data_buffer_valid <= 1'b0;
					o_data_out = mux_data[4*WIDTH_OUT-1 -: WIDTH_OUT];
					o_valid_out = 1'b1 & o_data_out[VALID_POS];
					count <= count + 1;
				end

			end

			else if (count == 2'b01)
			begin
				o_data_out = mux_data[3*WIDTH_OUT-1 -: WIDTH_OUT];
				count <= count + 1;
				o_valid_out = 1'b1 & o_data_out[VALID_POS];
			end
	
			else if (count == 2'b10)
			begin
				o_data_out = mux_data[2*WIDTH_OUT-1 -: WIDTH_OUT];
				count <= count + 1;
				o_valid_out = 1'b1 & o_data_out[VALID_POS];
			end
		
			else if (count == 2'b11)
			begin
				o_data_out = mux_data[WIDTH_OUT-1 -: WIDTH_OUT];
				count <= count + 1;
				o_valid_out = 1'b1 & o_data_out[VALID_POS];
			end
	
		end

	end

end

endmodule
