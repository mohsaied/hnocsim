/* 
 * function : elastic asynchronous fifo
 * author   : Mohamed S. Abdelfattah
 * date     : 26-AUG-2014
 * notes    : this wrapper adds elasticity to the write port of the fifo
 *            so that we can write one more word after full signal
 */

module afifo_elastic
#(
	parameter WIDTH = 4,
	parameter DEPTH = 4
)
(
	//clocks and reset
	input wire write_clk,
	input wire read_clk,
	input wire rst,
	
	//write port
	input  wire [WIDTH-1:0] i_data_in,
	input  wire             i_write_en,
	output reg              i_ready_out,

	//read port
	output reg  [WIDTH-1:0] o_data_out,
	input  wire             o_read_en,
	output reg              o_ready_out

);

//overflow buffer
reg [WIDTH-1:0] overflow_buffer;
reg overflow_buffer_valid;
wire read_overflow;

//misc
wire [WIDTH-1:0] fifo_data_in;
wire fifo_full, fifo_empty;


//----------------------------------------------------------------------------
// Implementation
//----------------------------------------------------------------------------


//fifo reads from input or overflow buffer
assign fifo_data_in = read_overflow ? overflow_buffer : i_data_in;

//assign ready signals
assign i_ready_out = ~fifo_full;
assign o_ready_out = ~fifo_empty;

//afifo componenet
afifo
#(
	.WIDTH(WIDTH),
	.DEPTH(DEPTH)
)
afifo_inst
(
	.write_clk(write_clk),
	.read_clk(read_clk),
	.clear(rst),
	
	.i_data_in(fifo_data_in),
	.i_write_en( (i_write_en & ~fifo_full) | read_overflow),
	.i_full_out(fifo_full),

	.o_data_out(o_data_out),
	.o_read_en(o_read_en),
	.o_empty_out(fifo_empty)
);


//write in overflow buffer if fifo is full
always @ (posedge write_clk)
begin
	
	if(rst)
	begin
		overflow_buffer_valid <= 1'b0;
	end

	else 
	begin		
		
		//write in overflow when fifo is full
		if (fifo_full & i_write_en)
		begin
			overflow_buffer <= i_data_in;
			overflow_buffer_valid <= 1'b1;
		end
		
		//invalid if we read it
		else if (read_overflow)
			overflow_buffer_valid <= 1'b0;
			
	end

end

//we'll read the overflow buffer when it's valid and we have space
assign read_overflow = ~fifo_full & overflow_buffer_valid;

endmodule

/*
 * function : asynchronous fifo
 * author   : Mohamed S. Abdelfattah
 * date     : 26-AUG-2014
 * source   : asicworld.com
 */

module afifo
#(
	parameter WIDTH = 4,
	parameter DEPTH = 4
)
(
	//clocks and reset
	input wire write_clk,
	input wire read_clk,
	input wire clear,
	
	//write port
	input  wire [WIDTH-1:0] i_data_in,
	input  wire             i_write_en,
	output reg              i_full_out,

	//read port
	output reg  [WIDTH-1:0] o_data_out,
	input  wire             o_read_en,
	output reg              o_empty_out
);

//address width
localparam ADDRESS_WIDTH = $clog2(DEPTH);

//storage
reg [WIDTH-1:0] memory [DEPTH-1:0];

//pointers to head/tail and enables
wire [ADDRESS_WIDTH-1:0] next_read_addr, next_write_addr;
wire                     next_read_en, next_write_en;

//misc
wire equal_address, set_status, rst_status, preset_full, preset_empty;
reg status;

//--------------------------------------------------------------------------------------
// Implementation
//--------------------------------------------------------------------------------------

//data in
always @ (posedge write_clk)
	if (i_write_en & ~i_full_out)
		memory[next_write_addr] <= i_data_in;

//data out
always @ (posedge read_clk)
	if (o_read_en & ~o_empty_out)
		o_data_out <= memory[next_read_addr];
    else
        o_data_out <= 0;

//read/write address enables
assign next_write_en  = i_write_en & ~i_full_out;
assign next_read_en = o_read_en & ~o_empty_out;

//read address
gray_counter
	#(.COUNTER_WIDTH(ADDRESS_WIDTH))
read_address_counter
(
	.gray_count_out(next_read_addr),
	.enable_in(next_read_en),
	.clear_in(clear),
	.clk(read_clk)
);

//write address
gray_counter
	#(.COUNTER_WIDTH(ADDRESS_WIDTH))
write_address_counter
(
	.gray_count_out(next_write_addr),
	.enable_in(next_write_en),
	.clear_in(clear),
	.clk(write_clk)
);

//equal address check
assign equal_address = (next_read_addr == next_write_addr);

//quadrant select
assign set_status = (next_write_addr[ADDRESS_WIDTH-2] ~^ next_read_addr[ADDRESS_WIDTH-1]) &
                    (next_write_addr[ADDRESS_WIDTH-1] ^  next_read_addr[ADDRESS_WIDTH-2]);

assign rst_status = (next_write_addr[ADDRESS_WIDTH-2] ^  next_read_addr[ADDRESS_WIDTH-1]) &
                    (next_write_addr[ADDRESS_WIDTH-1] ~^ next_read_addr[ADDRESS_WIDTH-2]);

//status logic: are we going full (status = 1) or going empty (status = 0)
always @ *
	if(rst_status | clear)
		status = 1'b0;
	else if (set_status)
		status = 1'b1;

//full_out logic
assign preset_full = status & equal_address;

always @ (posedge write_clk, posedge preset_full)
	if(preset_full)
		i_full_out <= 1'b1;
	else
		i_full_out <= 1'b0;

//empty_out logic 
assign preset_empty = ~status & equal_address;

always @ (posedge read_clk, posedge preset_empty)
	if(preset_empty)
		o_empty_out <= 1'b1;
	else
		o_empty_out <= 1'b0;

endmodule



/*
 * function : gray counter
 * author   : Mohamed S. Abdelfattah
 * date     : 26-AUG-2014
 * source   : asicworld.com
 */	

module gray_counter
#(parameter   COUNTER_WIDTH = 4) 
(
	output reg  [COUNTER_WIDTH-1:0]    gray_count_out,  //'Gray' code count output.
	
	input wire                         enable_in,  //Count enable.
	input wire                         clear_in,   //Count reset.
					    
	input wire                         clk
);

//Internal connections  variables
reg    [COUNTER_WIDTH-1:0]  binary_count;

//-------------------------------------------------------
// Implementation
//-------------------------------------------------------
				            
always @ (posedge clk or posedge clear_in)
	
	if (clear_in)
	begin
		binary_count <= {COUNTER_WIDTH{1'b0}} + 1; //gray count begins @ '1' with first enable_in
		gray_count_out <= {COUNTER_WIDTH{1'b0}};
	end
	
	else if (enable_in)
	begin
		binary_count <= binary_count + 1;
		gray_count_out <= {binary_count[COUNTER_WIDTH-1], binary_count[COUNTER_WIDTH-2:0] ^ binary_count[COUNTER_WIDTH-1:1]};
	end
	                                                                                                     
endmodule

