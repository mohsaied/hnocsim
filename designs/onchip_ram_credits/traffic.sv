/*
 * function : simple traffic generator and checker for RAM
 * author   : Mohamed S. Abdelfattah
 * date     : 16-SEPT-2014
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
    parameter NUM_CREDITS = 1
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

reg[3:0] credits;

//-------------------------------------------------------
// Implementation
//-------------------------------------------------------

//synopsys translate off
int curr_time,curr_time_2,curr_time_3;
//open a file for this module
integer fmain;
integer f, fin, send_data, file_valid, dummy;
int nodenumber = NODE;
string nodenum = $sformatf("%0d",nodenumber);
string fname = {"reports/traffic_",nodenum,".txt"};
initial fmain = $fopen("reports/output.txt");
initial f = $fopen(fname);
string finname = {"traffic/node_",nodenum,".txt"};
initial fin = $fopen(finname,"r");
initial file_valid = 1;
//synopsys translate on

reg [8*10:1] str;

//credits logic
always @ (posedge clk)
begin

    if (rst)
        credits = NUM_CREDITS;

    else
    begin

        if (o_valid_out == 1)
        begin
            
            credits = credits - 1;
            
            //synopsys translate off
			curr_time_3 = $time;
			$fdisplay(fmain,"%d >>CREDITS %d decrement time= %d",NODE,credits,curr_time_3);
			$fdisplay(f,"%d >>CREDITS %d decrement time= %d",NODE,credits,curr_time_3);
			//synopsys translate on

        end

        if (i_valid_in == 1)
        begin
            
            credits = credits + 1;

            //synopsys translate off
			curr_time_3 = $time;
			$fdisplay(fmain,"%d >>CREDITS %d increment time= %d",NODE,credits,curr_time_3);
			$fdisplay(f,"%d >>CREDITS %d increment time= %d",NODE,credits,curr_time_3);
			//synopsys translate on
            
        end

    end

end

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
	end
	
	else
	begin
	
        //synopsys translate off
	    curr_time = $time;
        //if the file still has inputs
        if (file_valid)
        begin 
            file_valid = $fgets(str, fin);
	        dummy = $sscanf(str, "%d", send_data);
            $fdisplay(fmain,"%d >>INPUT send_data = %d , time= %d",NODE,send_data,curr_time);
            $fdisplay(f,"%d >>INPUT send_data = %d , time= %d",NODE,send_data,curr_time);
        end

        //in this case the file finished so we'll default to not sending
        else
        begin
            send_data = 0;
		     $fdisplay(fmain,"%d >>INPUT stimuli finished, defaulting to send_data = %d, time= %d",NODE,send_data,curr_time);
			$fdisplay(f,"%d >>INPUT stimuli finished, defaulting to send_data = %d, time= %d",NODE,send_data,curr_time);
        end
        //synopsys translate on
            	
		//send if NoC is ready
		if (o_ready_in && credits != 0 && send_data)
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
			if(i_data_in == 8'b10000000)
            begin
            	curr_time_2 = $time;
				$fdisplay(fmain,"%d >>REC_EIVED write ack at time = %d",NODE,curr_time_2);
				$fdisplay(f,"%d >>REC_EIVED write ack at time = %d",NODE,curr_time_2);
            end

            else if (i_data_in == expected_data)
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
			end
			//synopsys translate on

            if (i_data_in == expected_data)
            begin
			    expected_data_counter = expected_data_counter + 1;
			    expected_data <= expected_data_counter;
            end

		end

	end

end

//synopsys translate off
final $fclose(f);
final $fclose(fin);
final $fclose(fmain);
//synopsys translate on

endmodule















