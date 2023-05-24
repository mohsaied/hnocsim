/*
 * function : simple traffic generator and checker for RAM
 * author   : Mohamed S. Abdelfattah
 * date     : 16-SEPT-2015
 */

module traffic
#(
	parameter WIDTH = 8,
	parameter ADDR_WIDTH = 4,
	parameter DEPTH = 8,
	parameter N = 16,
	
	parameter N_ADDR_WIDTH = $clog2(N),
	
	parameter [N_ADDR_WIDTH-1:0] NODE = 15,
	parameter [N_ADDR_WIDTH-1:0] DEST = 15,
	
	//packed in comes from memory, while packed out goes to memory
	parameter PACKED_IN = WIDTH+N_ADDR_WIDTH, //data + memory node
	parameter PACKED_OUT = WIDTH+ADDR_WIDTH+N_ADDR_WIDTH+1+1, //data, addr, src node,read_en, write_en
    parameter FREQ = 8
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

reg [WIDTH-1:0]        o_data_out;
reg [ADDR_WIDTH-1:0]   o_addr_out;
reg                    o_write_en;
reg                    o_read_en;
reg [N_ADDR_WIDTH-1:0] o_src_out;

reg [WIDTH-1:0]        i_data_in;
reg [N_ADDR_WIDTH-1:0] i_src_in;

//unpack input
assign i_data_in  = i_packed_in[PACKED_IN-1 -: WIDTH];
assign i_src_in   = i_packed_in[PACKED_IN-1-WIDTH -: N_ADDR_WIDTH];

//pack output
assign o_packed_out = {o_data_out,o_addr_out,o_write_en,o_read_en,o_src_out};

reg [3:0] counter;
reg [3:0] stall_counter; //range 0--15

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
string fname = {"reports/traffic_",nodenum,".txt"};
initial fmain = $fopen("reports/output.txt");
initial f = $fopen(fname);
//synopsys translate on

//send read/write requests whenever you can
always @ (posedge clk)
begin
	if (rst)
	begin
		o_data_out <= 0;
		o_addr_out <= 0;
		o_write_en <= 0;
		o_read_en <= 0;
		o_src_out <= 0;
		o_dest_out <= 0;
		o_valid_out <= 0;
		counter <= 0;
		stall_counter <= NODE; //init stall counter to the current node to avoid simulataneous requests
	end
	
	else
	begin
		
        stall_counter <= stall_counter + 1;

		//send if NoC is ready
		if (o_ready_in && stall_counter%FREQ == 1)
		begin
			o_valid_out <= 1;
			counter <= counter + 1;
			o_data_out = counter;
			o_addr_out = counter[2:0]+(NODE*8);
			o_dest_out <= DEST;
			o_src_out <= NODE;
			
			if (counter < 8)
			begin
				o_write_en = 1;
				o_read_en = 0;
			end

			else
			begin
				o_write_en = 0;
				o_read_en = 1;
			end
			
			//synopsys translate off
			curr_time = $time;
			$fdisplay(fmain,"%d >>SENDING Request r= %d , w= %d , data=%d, addr= %d, time= %d",NODE,o_read_en,o_write_en,o_data_out,o_addr_out,curr_time);
			$fdisplay(f,"%d >>SENDING Request r= %d , w=%d , data=%d, addr= %d, time= %d",NODE,o_read_en,o_write_en,o_data_out,o_addr_out,curr_time);
			//synopsys translate on

		end

		else
			o_valid_out <= 0;

	end
end

reg [WIDTH-1:0] expected_data;
reg [2:0] expected_data_counter;


//simple checker
always @ (posedge clk)
begin
	
	if (rst)
	begin
		i_ready_out <= 0;
		expected_data <= 0;
		expected_data_counter <= 0;
	end
	
	else
	begin
		
		i_ready_out <= 1; //always ready

		if (i_valid_in)
		begin
			//synopsys translate off
			if (i_data_in == expected_data)
			begin
				curr_time_2 = $time;
				$fdisplay(fmain,"%d >>RECEIVED read response expected data %d at time = %d",NODE,i_data_in,curr_time_2);
				$fdisplay(f,"%d >>RECEIVED read response expected data %d at time = %d",NODE,i_data_in,curr_time_2);
			end
			
			else
			begin
				$fdisplay(fmain,"%d>>FAIL: received %d instead of %d",NODE,i_data_in,expected_data);
				$fdisplay(f,"%d>>FAIL: received %d instead of %d",NODE,i_data_in,expected_data);
				$stop(0);
			//synopsys translate on
			end

			expected_data_counter = expected_data_counter + 1;
			expected_data <= expected_data_counter;
		end

	end

end

//synopsys translate off
final $fclose(f);
final $fclose(fmain);
//synopsys translate on

endmodule















