/*
 * function : Traffic generator and checker for RAM with token passing scheme
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
	
    //tokens
    parameter TOKEN_WIDTH = 5, // a maximum of 31 tokens may be transferred at any given time

	//packed in comes from memory, while packed out goes to memory
	parameter PACKED_IN = WIDTH+N_ADDR_WIDTH, //data + memory node
	parameter PACKED_OUT = WIDTH+ADDR_WIDTH+N_ADDR_WIDTH+1+1, //data, addr, src node,read_en, write_en
    parameter FREQ = 15
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

//tokens
reg [TOKEN_WIDTH-1:0] tokens_in;
reg [TOKEN_WIDTH-1:0] current_tokens;
reg sending_tokens;
reg [N_ADDR_WIDTH-1:0] rand_num;

//unpack input
assign i_src_in   = i_packed_in[PACKED_IN-1-WIDTH -: N_ADDR_WIDTH];
assign i_data_in  = i_packed_in[PACKED_IN-1 -: WIDTH];

//parse in tokens if the src address points to my node number 
//(I'll never send data to myself)
assign tokens_in = i_data_in[WIDTH-1] ? i_data_in[WIDTH-2 -: TOKEN_WIDTH] : 0;

//pack output
assign o_packed_out = {o_data_out,o_addr_out,o_write_en,o_read_en,o_src_out};

reg [3:0] counter;
reg [3:0] stall_counter; //range 0--15


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
string finname = {"traffic/node_",nodenum,".txt"};
initial fmain = $fopen("reports/output.txt");
initial f = $fopen(fname);
initial fin = $fopen(finname,"r");
initial file_valid = 1;
//synopsys translate on

reg [8*10:1] str;

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
		sending_tokens <= 0;
		stall_counter <= NODE; //init stall counter to the current node to avoid simulataneous requests
	end
	
	else
	begin
		
        stall_counter <= stall_counter + 1;

		//send if NoC is ready and it's our turn or we have tokens
		if (o_ready_in && (stall_counter%FREQ == 1 || current_tokens != 0) )
		begin

            //we need to check if we have data to send this cycle (check in a text file)
            //if we do, we'll send it!
            //if not, we'll send "current_tokens+1" to someone (and set sending_tokens to 1)
            //will try passing tokens to nearest neighbour first (NODE+1)
            //but this won't work for the general case so will think about other schemes.
            
            //we're always valid in this condition
			o_valid_out = 1;
			
            //read a byte from our traffic vector to determine if we have
            //something to send or not (want to read next byte here)
            
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
            
            //we're sending data this cycle
            if(send_data)
            begin

                counter <= counter + 1;
			    o_data_out = counter;
			    o_addr_out = counter[2:0]+(NODE*8);
			    o_dest_out = DEST;
			    o_src_out = NODE;
			
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
                
                sending_tokens = 0;

    			//synopsys translate off
		    	$fdisplay(fmain,"%d >>SENDING Request r= %d , w= %d , data=%d, addr= %d, time= %d",NODE,o_read_en,o_write_en,o_data_out,o_addr_out,curr_time);
			    $fdisplay(f,"%d >>SENDING Request r= %d , w=%d , data=%d, addr= %d, time= %d",NODE,o_read_en,o_write_en,o_data_out,o_addr_out,curr_time);
			    //synopsys translate on

            end
            
            //we're going to send out our tokens here
            else
            begin 
			    o_data_out[WIDTH-1] = 1;
                o_data_out[WIDTH-2 -: TOKEN_WIDTH] = current_tokens+1;
			    //o_dest_out = NODE == 14 ? 4'd0 : NODE+1;
                rand_num = $urandom_range(0,14);
			    o_dest_out = rand_num == NODE ? (NODE==14?0:NODE+1) : rand_num;

                sending_tokens = 1;
			    
                //synopsys translate off
                $fdisplay(fmain,"%d >>TOKENS sending %d tokens to node %d , time= %d",NODE,current_tokens+1,o_dest_out,curr_time);
                $fdisplay(f,"%d >>TOKENS sending %d tokens to node %d , time= %d",NODE,current_tokens+1,o_dest_out,curr_time);
			    //synopsys translate on
            end
			

		end

		else
        begin
			o_valid_out = 0;
            sending_tokens = 0;
        end

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

		if (i_valid_in && !i_data_in[WIDTH-1])
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

//token counter
always @ (posedge clk)
begin
    
    if(rst)
        current_tokens = 0;
    
    else
    begin
 
	    //synopsys translate off
		curr_time_3 = $time;  
        //synopsys translate on

        //logic for incrementing token count
        if (i_valid_in)
        begin

            current_tokens = current_tokens + tokens_in; //tokens_in will only have a number if NODE is curr node, see assign statement up there

            //synopsys translate off
            if (tokens_in != 0)
            begin
                $fdisplay(fmain,"%d >>TOKENS: received %d , time = %d",NODE,tokens_in,curr_time_3);
                $fdisplay(f,"%d >>TOKENS: received %d , time = %d",NODE,tokens_in,curr_time_3);
            end
            //synopsys translate on

        end

        //logic for decrementing token count, we decrement in 2 cases:
        // a) we're using up our tokens, or
        // b) we're forwarding our tokens elsewhere
        
        //if we are sending out something by using our tokens
        //that means output is valid, it's not our turn to send, and we arent sending tokens (redundant)
        if (o_valid_out && (stall_counter%FREQ != 1) && !sending_tokens)
        begin

            current_tokens = current_tokens - 1;

            //synopsys translate off
            $fdisplay(fmain,"%d >>TOKENS: using up 1 token, %d left, time = %d",NODE,current_tokens,curr_time_3);
            $fdisplay(f,"%d >>TOKENS: using up 1 token, %d left, time = %d",NODE,current_tokens,curr_time_3);
            //synopsys translate on

        end

        if (sending_tokens && o_valid_out)
        begin

            current_tokens = 0;

        end

        //in the case when the NoC is not ready but it is our turn to send, we
        //increment our tokens by 1
        if (!o_ready_in && stall_counter%FREQ == 1)
        begin
            
            current_tokens = current_tokens + 1;

            //synopsys translate off
            $fdisplay(fmain,"%d >>TOKENS: incrementing tokens because noc is stalling in my slot, %d tokens, time = %d",NODE,current_tokens,curr_time_3);
            $fdisplay(f,"%d >>TOKENS: incrementing tokens because noc is stalling in my slot, %d tokens, time = %d",NODE,current_tokens,curr_time_3);
            //synopsys translate on

        end

    end

end

//synopsys translate off
final $fclose(f);
final $fclose(fin);
final $fclose(fmain);
//synopsys translate on

endmodule















