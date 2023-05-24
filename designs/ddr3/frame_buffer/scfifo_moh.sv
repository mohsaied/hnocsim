/*
 * function : single clock fifo -- just tie the two clocks of the afifo together
 * author   : Mohamed S. Abdelfattah
 * date     : 18-MAR-2015
 * source   : asicworld.com
 */

module scfifo_moh
#(
	parameter WIDTH = 512,
	parameter DEPTH = 8
)
(
	//clocks and reset
	input wire clk,
	input wire rst,
	
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
always @ (posedge clk)
	if (i_write_en & ~i_full_out)
		memory[next_write_addr] <= i_data_in;

//data out
always @ (posedge clk)
	if (o_read_en & ~o_empty_out)
		o_data_out <= memory[next_read_addr];


//read/write address enables
assign next_write_en  = i_write_en & ~i_full_out;
assign next_read_en = o_read_en & ~o_empty_out;

//read address
gray_counter_moh
	#(.COUNTER_WIDTH(ADDRESS_WIDTH))
read_address_counter
(
	.gray_count_out(next_read_addr),
	.enable_in(next_read_en),
	.rst_in(rst),
	.clk(clk)
);

//write address
gray_counter_moh
	#(.COUNTER_WIDTH(ADDRESS_WIDTH))
write_address_counter
(
	.gray_count_out(next_write_addr),
	.enable_in(next_write_en),
	.rst_in(rst),
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
	if(rst_status | rst)
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

module gray_counter_moh
#(parameter   COUNTER_WIDTH = 4) 
(
	output reg  [COUNTER_WIDTH-1:0]    gray_count_out,  //'Gray' code count output.
	
	input wire                         enable_in,  //Count enable.
	input wire                         rst_in,   //Count reset.
					    
	input wire                         clk
);

//Internal connections  variables
reg    [COUNTER_WIDTH-1:0]  binary_count;

//-------------------------------------------------------
// Implementation
//-------------------------------------------------------
				            
always @ (posedge clk or posedge rst_in)
	
	if (rst_in)
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

