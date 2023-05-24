/*
 * function : single-port RAM
 * author   : Mohamed S. Abdelfattah
 * date     : 14-SEPT-2015
 */

module ram
#(
	parameter WIDTH = 8,
	parameter ADDR_WIDTH = 4, //4k words
	parameter N = 16,
	
	parameter N_ADDR_WIDTH = $clog2(N),
	
	parameter [N_ADDR_WIDTH-1:0] NODE = 15,
	
	parameter PACKED_IN = WIDTH+ADDR_WIDTH+N_ADDR_WIDTH+1+1,
	parameter PACKED_OUT = WIDTH+N_ADDR_WIDTH
)
(
	input clk,
	input rst,
	
	input [PACKED_IN-1:0] i_packed_in,
	input                 i_valid_in,
	output reg            i_ready_out,

	output reg [PACKED_OUT-1:0]   o_packed_out,
	output reg [N_ADDR_WIDTH-1:0] o_dest_out,
	output reg                    o_valid_out,
	input                         o_ready_in
);

reg [WIDTH-1:0]        i_data_in;
reg [ADDR_WIDTH-1:0]   i_addr_in;
reg                    i_write_en;
reg                    i_read_en;
reg [N_ADDR_WIDTH-1:0] i_src_in;

reg [WIDTH-1:0]        o_data_out;

//unpack
assign i_data_in  = i_packed_in[PACKED_IN-1 -: WIDTH];
assign i_addr_in  = i_packed_in[PACKED_IN-1-WIDTH -: ADDR_WIDTH];
assign i_write_en = i_packed_in[PACKED_IN-1-WIDTH-ADDR_WIDTH -: 1];
assign i_read_en  = i_packed_in[PACKED_IN-1-WIDTH-ADDR_WIDTH-1 -: 1];
assign i_src_in   = i_packed_in[PACKED_IN-1-WIDTH-ADDR_WIDTH-1-1 -: N_ADDR_WIDTH];

//pack
assign o_packed_out = {o_data_out,NODE};

//depth
localparam DEPTH = 2**ADDR_WIDTH;

//the memory
reg [WIDTH-1:0] memory [DEPTH-1:0];


//output buffer
reg [WIDTH-1:0]        output_buffer;
reg [N_ADDR_WIDTH-1:0] dest_buffer;
reg             	   output_buffer_valid;

//-------------------------------------------------------
// Implementation
//-------------------------------------------------------

//synopsys translate off
int curr_time,curr_time_2;
//open a file for this module
integer fmain;
integer f;
int nodenumber = NODE;
string nodenum = $sformatf("%0d",nodenumber);
string fname = "reports/ram.txt";
initial fmain = $fopen("reports/output.txt");
initial f = $fopen(fname);
reg [3:0] rec_node;
final $fclose(f);
final $fclose(fmain);
//synopsys translate on


//relay the ready
assign i_ready_out = o_ready_in;

//write process
always @ (posedge clk)	
	if (i_write_en & i_valid_in)
	begin
		memory[i_addr_in] <= i_data_in;

		//synopsys translate off
		curr_time = $time;	
		if (i_addr_in < 8)
			rec_node = 0;
		else if (i_addr_in < 16)
			rec_node = 1;
		else if (i_addr_in < 24)
			rec_node = 2;
		else if (i_addr_in < 32)
			rec_node = 3;
		else if (i_addr_in < 40)
			rec_node = 4;
		else if (i_addr_in < 48)
			rec_node = 5;
		else if (i_addr_in < 56)
			rec_node = 6;
		else if (i_addr_in < 64)
			rec_node = 7;
		else if (i_addr_in < 72)
			rec_node = 8;
		else if (i_addr_in < 80)
			rec_node = 9;
		else if (i_addr_in < 88)
			rec_node = 10;
		else if (i_addr_in < 96)
			rec_node = 11;
		else if (i_addr_in < 104)
			rec_node = 12;
		else if (i_addr_in < 112)
			rec_node = 13;
		else 
			rec_node = 14;

		$fdisplay(fmain,"%d >>RECEIVED write request r= %d , w= %d , data=%d, addr= %d, time= %d",rec_node,i_read_en,i_write_en,i_data_in,i_addr_in,curr_time);
		$fdisplay(f,"%d >>RECEIVED write request r= %d , w= %d , data=%d, addr= %d, time= %d",rec_node,i_read_en,i_write_en,i_data_in,i_addr_in,curr_time);
		//synopsys translate on 

	end

//read data
always @ (posedge clk)
begin
	
	if (rst)
	begin
		output_buffer = 0;
		output_buffer_valid = 0;
		dest_buffer = 0;
	end
	
	else
	begin
	
		//if we are stalling but also reading: store in buffer
		if (~o_ready_in & i_read_en & i_valid_in)
		begin
			output_buffer <= memory[i_addr_in];
			dest_buffer <= i_src_in;
			output_buffer_valid <= 1'b1;
			o_valid_out <= 1'b0;
		end
		
		else if (o_ready_in)
		begin
			
			if (output_buffer_valid)
			begin
				o_data_out <= output_buffer;
				o_dest_out <= dest_buffer;
				output_buffer_valid <= 1'b0;
				o_valid_out <= 1'b1;
			end
			
			else 
			begin
				o_data_out <= memory[i_addr_in];
				o_dest_out <= i_src_in;
				o_valid_out <= i_read_en & i_valid_in;
			end
		end

	end 
		

end

endmodule















