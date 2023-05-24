/*
 * function : testbench for single-port RAM
 * author   : Mohamed S. Abdelfattah
 * date     : 14-SEPT-2015
 */

module tb_ram ();

parameter WIDTH = 8;
parameter ADDR_WIDTH = 7; 
parameter N = 16;
parameter N_ADDR_WIDTH = $clog2(N);

parameter PACKED_IN = WIDTH+ADDR_WIDTH+N_ADDR_WIDTH+1+1;
parameter PACKED_OUT = WIDTH+N_ADDR_WIDTH;

logic clk;
logic rst;

logic [PACKED_IN-1:0]    i_packed_in;
logic [WIDTH-1:0]        i_data_in;
logic [ADDR_WIDTH-1:0]   i_addr_in;
logic                    i_write_en;
logic                    i_read_en;
logic [N_ADDR_WIDTH-1:0] i_src_in;
logic                    i_valid_in;
logic                    i_ready_out;

logic [PACKED_OUT-1:0]   o_packed_out;
logic [WIDTH-1:0]        o_data_out;
logic                    o_valid_out;
logic [N_ADDR_WIDTH-1:0] o_dest_out;
logic [N_ADDR_WIDTH-1:0] o_src_out;
logic                    o_ready_in;


assign i_valid_in = i_read_en | i_write_en;
assign i_packed_in = {i_data_in,i_addr_in,i_write_en,i_read_en,i_src_in};

assign o_data_out = o_packed_out[PACKED_OUT-1 -: WIDTH];
assign o_src_out = o_packed_out[PACKED_OUT-1-WIDTH -: N_ADDR_WIDTH];

//device under test
ram dut ( .* );

//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

//clocks
initial clk = 1'b1;
//toggle forever
always #1 clk = ~clk;

//reset
initial rst = 1'b1;

//inputs
initial i_data_in  = 8'bZ;
initial i_addr_in  = 4'bZ;
initial i_src_in  = 4'bZ;
initial i_write_en = 1'b0;
initial i_read_en = 1'b0;
initial o_ready_in = 1'b1;


int i;

initial
begin

	@ (posedge clk)
	@ (posedge clk)
	@ (posedge clk)

	rst = 1'b0;
	
	//write
	for(i = 0; i <2**ADDR_WIDTH;i++)
	begin
		@ (posedge clk)
		i_data_in  = i;
		i_src_in  = i;
		i_addr_in  = i;
		i_write_en = 1'b1;
		i_read_en = 1'b0;
		o_ready_in = 1'b1;
	end
	
	//read
	for(i = 0; i <2**ADDR_WIDTH;i++)
	begin
		@ (posedge clk)
		i_data_in  = 2**ADDR_WIDTH-i-1;
		i_src_in  = 2**ADDR_WIDTH-i-1;
		i_addr_in  = i;
		i_write_en = 1'b0;
		i_read_en = 1'b1;
		o_ready_in = 1'b1;
	end
	
	//lower ready but we have a read req
	@ (posedge clk)
	i_data_in  = 5;
	i_src_in  = 4;
	i_addr_in  = 6;
	i_write_en = 1'b0;
	i_read_en = 1'b1;
	o_ready_in = 1'b0;

	//not ready so cant have a read en
	@ (posedge clk)
	i_data_in  = 5;
	i_src_in  = 4;
	i_addr_in  = 6;
	i_write_en = 1'b0;
	i_read_en = 1'b0;
	o_ready_in = 1'b0;

	//ready now so we will read the buffered data word
	@ (posedge clk)
	i_data_in  = 5;
	i_src_in  = 4;
	i_addr_in  = 6;
	i_write_en = 1'b0;
	i_read_en = 1'b0;
	o_ready_in = 1'b1;

	//not reading or writing
	@ (posedge clk)
	i_write_en = 1'b0;
	i_read_en = 1'b0;
	o_ready_in = 1'b1;


end



endmodule
