/*
 * function : synchronous fifo with special flags to tell when there's a tail flit
 * author   : Mohamed S. Abdelfattah
 * date     : 28-AUG-2014
 * source   : asicworld.com
 */

module fifo
#(
	parameter WIDTH = 4,
	parameter DEPTH = 4
)
(
	//clocks and reset
	input wire clk,
	input wire clear,
	
	//write port
	input  wire [WIDTH-1:0] i_data_in,
	input  wire             i_write_en,
	output reg              i_full_out,

	//read port
	output reg  [WIDTH-1:0] o_data_out,
	input  wire             o_read_en,
	output reg              o_empty_out,
	output reg              o_almost_empty_out,
	output reg              o_next_is_tail
);

//address width
localparam ADDRESS_WIDTH = $clog2(DEPTH);
localparam COUNTER_WIDTH = $clog2(DEPTH+1);
localparam TAIL_POS = WIDTH-3;

//storage
reg [WIDTH-1:0] memory [DEPTH-1:0];

//pointers to head/tail and enables
wire [ADDRESS_WIDTH-1:0] next_read_addr, after_next_read_addr, next_write_addr;
wire                     next_read_en, next_write_en;

//misc
wire equal_address, set_status, rst_status, preset_full, preset_empty;
reg status;

//-----------------------------------------------------------------------------------
// Implementation
//-----------------------------------------------------------------------------------

//counter to keep track of the number of words
reg [COUNTER_WIDTH-1:0] number_of_words;

always@ (posedge clk)
	if (clear)
		number_of_words <= 0;
	else if (i_write_en & o_read_en)
		number_of_words <= number_of_words;
	else if (i_write_en)
		number_of_words <= number_of_words + 1;
	else if (o_read_en)
		number_of_words <= number_of_words - 1;

assign o_almost_empty_out = number_of_words <= 1;

//note that here we assumed that each read_en/write_en results in a valid read/write

//adding some extra logic to fetch the next word's tail bit
//with each of the read_en -- this way we can predict when 
//the next flit is the end of packet

always @ (posedge clk)
	if (o_read_en)
		//in this case the fifo was full then going empty
		if (number_of_words > 1)
			o_next_is_tail <= memory[after_next_read_addr][TAIL_POS];
		//in this case the fifo was empty and we check the next incoming flit
		else if (i_write_en)
			o_next_is_tail <= i_data_in[TAIL_POS];
		else
			o_next_is_tail <= 1'b0;
	else //we're not reading
		if (number_of_words > 0)
			o_next_is_tail <= memory[next_read_addr][TAIL_POS];
		else if (i_write_en)
			o_next_is_tail <= i_data_in[TAIL_POS];
		else
			o_next_is_tail <= 1'b0;


//data in
always @ (posedge clk)
	if (i_write_en & ~i_full_out)
		memory[next_write_addr] <= i_data_in;

//data out
always @ (posedge clk)
	//if (~o_empty_out)
	if (o_read_en & ~o_empty_out)
		o_data_out <= memory[next_read_addr];


//read/write address enables
assign next_write_en  = i_write_en & ~i_full_out;
assign next_read_en = o_read_en & ~o_empty_out;

//read address
gray_counter_plus
	#(.COUNTER_WIDTH(ADDRESS_WIDTH))
read_address_counter
(
	.gray_count_out(next_read_addr),
	.next_gray_count_out(after_next_read_addr),
	.enable_in(next_read_en),
	.clear_in(clear),
	.clk(clk)
);

//write address
gray_counter
	#(.COUNTER_WIDTH(ADDRESS_WIDTH))
write_address_counter
(
	.gray_count_out(next_write_addr),
	.enable_in(next_write_en),
	.clear_in(clear),
	.clk(clk)
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

always @ (posedge clk, posedge preset_full)
	if(preset_full)
		i_full_out <= 1'b1;
	else
		i_full_out <= 1'b0;

//empty_out logic 
assign preset_empty = ~status & equal_address;

always @ (posedge clk, posedge preset_empty)
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

module gray_counter_plus
#(parameter   COUNTER_WIDTH = 4) 
(
	output reg  [COUNTER_WIDTH-1:0]    gray_count_out,  //'Gray' code count output.
	output reg  [COUNTER_WIDTH-1:0]    next_gray_count_out,  //'Gray' code count output of next word.
	
	input wire                         enable_in,  //Count enable.
	input wire                         clear_in,   //Count reset.
					    
	input wire                         clk
);

//Internal connections  variables
reg    [COUNTER_WIDTH-1:0]  binary_count;
reg    [COUNTER_WIDTH-1:0]  next_binary_count;

//-------------------------------------------------------
// Implementation
//-------------------------------------------------------
				            
always @ (posedge clk or posedge clear_in)
	
	if (clear_in)
	begin
		binary_count <= {COUNTER_WIDTH{1'b0}} + 1; //gray count begins @ '1' with first enable_in
		next_binary_count <= {COUNTER_WIDTH{1'b0}} + 2; //gray count begins @ '1' with first enable_in
		gray_count_out <= {COUNTER_WIDTH{1'b0}};
		next_gray_count_out <= {COUNTER_WIDTH{1'b0}} + 1;
	end
	
	else if (enable_in)
	begin
		binary_count <= binary_count + 1;
		gray_count_out <= {binary_count[COUNTER_WIDTH-1], binary_count[COUNTER_WIDTH-2:0] ^ binary_count[COUNTER_WIDTH-1:1]};
		next_binary_count <= binary_count + 2;
		next_gray_count_out <= {next_binary_count[COUNTER_WIDTH-1], next_binary_count[COUNTER_WIDTH-2:0] ^ next_binary_count[COUNTER_WIDTH-1:1]};
	end
	                                                                                                     
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

