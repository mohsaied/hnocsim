/*
 * function : connect to booksim through SW fabricports
 * authors  : Mohamed S. Abdelfattah
 * date     : 04-JUL-2015
 */


module fabric_interface_sw #
(
	parameter WIDTH_NOC = 128, 
	parameter WIDTH_RTL = 512, 
	parameter N = 16,
	parameter NUM_VC = 2,
    parameter DEPTH_PER_VC = 8, //currently unused
	parameter VERBOSE = 1
)
(
    //this clock should be one quarter of the NoC clock
	input clk,
	input rst,
	
    //each module can have its own clock
    input [N-1:0] clk_rtl,
	
	//data
	input        [WIDTH_RTL-1:0] i_packets_in  [0:N-1],
	output logic [WIDTH_RTL-1:0] o_packets_out [0:N-1],
	
	//ready signals
    output logic i_readys_out [0:N-1],
	input        o_readys_in  [0:N-1],

    //valid signals
    input        i_valids_in  [0:N-1],
	output logic o_valids_out [0:N-1]


);

import "DPI-C" function void connectFabricSocket();
import "DPI-C" function void exitFabricSocket();
import "DPI-C" function void nextFabricCycle(input int speedup);
import "DPI-C" function void queueFabricFlit(input int pid, input int fid, input int source, input int destination, input int vc, input int head, input int tail);
import "DPI-C" function void ejectFourFabric(input int node, output int id0, output int id1, output int id2, output int id3, output int valid);
import "DPI-C" function int checkNocReady(input int node, input int vc);
import "DPI-C" function void sendModuleReady(input int node, input int vc, input int ready);

//local parameters
localparam STORAGE = 16;
localparam NUM_CYCLES = 100000;
localparam CLOCK_SPEEDUP = 1;

localparam VC_ADDRESS_WIDTH = $clog2(NUM_VC);
localparam ADDRESS_WIDTH = $clog2(N);
localparam VALID_POS = WIDTH_NOC-1;
localparam HEAD_POS = WIDTH_NOC-2;
localparam TAIL_POS = WIDTH_NOC-3;
localparam VC_POS = WIDTH_NOC-4;
localparam DEST_POS = WIDTH_NOC-4-VC_ADDRESS_WIDTH;

longint unsigned p_id [0:N-1];
longint unsigned next_p_id;
longint unsigned f_id;
int     unsigned head;
int     unsigned tail;
int     unsigned valid;
int     unsigned src;
int     unsigned dest;
int              assigned_vc;
int     unsigned i;
int     unsigned j;
int     unsigned k;
int     unsigned l;
int     unsigned m;
longint unsigned cycle_count;

int received_id0;
int received_id1;
int received_id2;
int received_id3;
int valid_from_noc;
int unsigned out_port; 

typedef struct    {
	bit 	         	 valid; 
	longint unsigned      p_id;
	longint unsigned      f_id;
	int	unsigned          dest;
	int	unsigned          vc;
	logic [WIDTH_NOC-1:0] data;
} data_entry;

data_entry data_set [0:2**STORAGE-1];

logic [4:0] dest_table [0:N-1];

logic [WIDTH_NOC-1:0] flit;

//for afifos
logic [WIDTH_RTL-1:0] fifoin_packets    [0:N-1];
logic                    fifoin_read_en    [0:N-1];
logic                    fifoin_valids     [0:N-1];
logic                    fifoin_readys_out [0:N-1];

logic [WIDTH_RTL-1:0] fifoout_packets        [0:N-1];
logic                    fifoout_valids         [0:N-1];
logic                    fifoout_in_readys_out  [0:N-1];
logic                    fifoout_out_readys_out [0:N-1];

logic [N-1:0] all_vcs_ready;

//connect socket at the begining
initial begin
	next_p_id = 0;
	for(i=0;i<N;i++)
		p_id[i] = 0;
	f_id = 0;
	cycle_count = 0;
	connectFabricSocket();
end

//exit socket at the end
final begin
	exitFabricSocket();
end


//main routine: inject packets, receive flits and check
always @(posedge clk or posedge rst) begin

	if (rst) begin
		f_id = 0;
		cycle_count = 0;
        for(i=0; i<N; i++)
            fifoout_valids[i] = 0;
	end else begin
		
		//--------------------------------------
		// generate flits to inject this cycle   
		//--------------------------------------
	
        //go over all nodes
		for (i=0; i<N; i=i+1) begin    
        if(fifoin_valids[i]) begin 
            //and four flits per node
            for(j=0; j<4; j=j+1) begin
               
                //extract this flit
                flit = fifoin_packets[i][WIDTH_RTL-1-WIDTH_NOC*j -: WIDTH_NOC];

                //extract valid, head and tail bits
                valid = flit[VALID_POS];
                
                if (valid) begin
                    src  = i;
                    head = flit[HEAD_POS];
                    tail = flit[TAIL_POS];
                    assigned_vc = flit[VC_POS -: VC_ADDRESS_WIDTH];
                    
                    //extract destination if we are the head
                    //and store it in a table
                    //otherwise lookup that table for body/tail
                    if (head) begin
                        dest = flit[DEST_POS -: ADDRESS_WIDTH];
                        dest_table[i] = dest;
                    end else begin
                        dest = dest_table[i];
                    end
                    
                    //need find next packet id
                    if(head)
                    begin
                        p_id[i] = next_p_id;
                        next_p_id = next_p_id+1;
                    end

                    //insert this flit into the network
                    queueFabricFlit(p_id[i],f_id,src,dest,assigned_vc,head,tail);

                    if (VERBOSE == 1)
                        $display("Sending flit %d (%d) head = %d, tail = %d, from node %d on VC %d to node %d, (cycle = %d)",f_id,p_id[i],head,tail,i,assigned_vc,dest,cycle_count);
                    
                    // Store data
                    for (k=0; k<2**STORAGE; k=k+1) begin
                        if (data_set[k].valid == 1'b0) begin
                            data_set[k].p_id = p_id[i];
                            data_set[k].f_id = f_id;
                            data_set[k].valid = 1'b1;
                            data_set[k].dest = dest;
                            data_set[k].vc = assigned_vc;
                            data_set[k].data = flit;
                            break;
                        end
                    end

                    //increment flit counter
                    f_id = f_id + 1;
                end //if valid
            end //four flits
        end
		end //N nodes

        //--------------------------------------
		// update module readys in and out
		//--------------------------------------

        for(l=0; l<N; l++)begin
            //TODO understand separate VC readys
            all_vcs_ready[l] = 1;
            for(m=0; m<NUM_VC; m++)begin
                sendModuleReady(l,m,fifoout_in_readys_out[l]);  
                //the ready signal is an AND of all VC readys
                all_vcs_ready[l] = all_vcs_ready[l] & checkNocReady(l,m);
            end
            //fifoin_read_en[l] = all_vcs_ready & fifoin_readys_out[l];  
        end
	
		//--------------------------------------
		// eject received flits
		//--------------------------------------
	
		//rst output valids to invalid (0)
		for (k=0; k<N; k=k+1) begin
			fifoout_packets[k] = 0;
            fifoout_valids[k] = 0;

            received_id0 = -1;
            received_id1 = -1;
            received_id2 = -1;
            received_id3 = -1;

            ejectFourFabric(k,received_id0,received_id1,received_id2,received_id3,valid_from_noc);

            fifoout_valids[k] = valid_from_noc;
            
            //$display("received(%d) [valid=%d] %d %d %d %d",k,fifoout_valids[k],received_id0,received_id1,received_id2,received_id3);
			
            if (received_id0 >= 0) begin

				// find data in data_set
				for (j=0; j<2**STORAGE; j=j+1) begin
					if (data_set[j].valid == 1'b1) begin
						if (data_set[j].f_id == received_id0) begin
						    
                            fifoout_valids[k] = 1;
						    if (VERBOSE == 1)
							     $display("Received flit %d at node %d, vc %d (cycle = %d)",received_id0,out_port,data_set[j].vc,cycle_count);

							// remove data from data_set
							data_set[j].valid = 1'b0;

							// send flit data to destination port
							fifoout_packets[k][WIDTH_RTL-1-WIDTH_NOC*0 -: WIDTH_NOC] = data_set[j].data;

							break;

						end
					end
				end
			end
            
			if (received_id1 >= 0) begin

				// find data in data_set
				for (j=0; j<2**STORAGE; j=j+1) begin
					if (data_set[j].valid == 1'b1) begin
						if (data_set[j].f_id == received_id1) begin
							
                            fifoout_valids[k] = 1;
						    if (VERBOSE == 1)
							     $display("Received flit %d at node %d, vc %d (cycle = %d)",received_id0,out_port,data_set[j].vc,cycle_count);

							// remove data from data_set
							data_set[j].valid = 1'b0;

							// send flit data to destination port
							fifoout_packets[k][WIDTH_RTL-1-WIDTH_NOC*1 -: WIDTH_NOC] = data_set[j].data;

							break;

						end
					end
				end
			end
            
			if (received_id2 >= 0) begin

				// find data in data_set
				for (j=0; j<2**STORAGE; j=j+1) begin
					if (data_set[j].valid == 1'b1) begin
						if (data_set[j].f_id == received_id2) begin
							
                            fifoout_valids[k] = 1;
						    if (VERBOSE == 1)
							     $display("Received flit %d at node %d, vc %d (cycle = %d)",received_id0,out_port,data_set[j].vc,cycle_count);

							// remove data from data_set
							data_set[j].valid = 1'b0;

							// send flit data to destination port
							fifoout_packets[k][WIDTH_RTL-1-WIDTH_NOC*2 -: WIDTH_NOC] = data_set[j].data;

							break;

						end
					end
				end
			end
            
			if (received_id3 >= 0) begin

				// find data in data_set
				for (j=0; j<2**STORAGE; j=j+1) begin
					if (data_set[j].valid == 1'b1) begin
						if (data_set[j].f_id == received_id3) begin
							
                            fifoout_valids[k] = 1;
						    if (VERBOSE == 1)
							     $display("Received flit %d at node %d, vc %d (cycle = %d)",received_id0,out_port,data_set[j].vc,cycle_count);

							// remove data from data_set
							data_set[j].valid = 1'b0;

							// send flit data to destination port
							fifoout_packets[k][WIDTH_RTL-1-WIDTH_NOC*3 -: WIDTH_NOC] = data_set[j].data;

							break;

						end
					end
				end
			end
            
		end //N nodes


		// proceed to next cycle
		nextFabricCycle(CLOCK_SPEEDUP);

		// increment cycle count
		cycle_count = cycle_count + 1;
    end

end //of always block


//generate aFifos so that we have independant clocks for each module
generate
genvar ibuf;
for(ibuf = 0; ibuf < N; ibuf = ibuf + 1)
begin:ibufs

assign fifoin_read_en[ibuf] = all_vcs_ready[ibuf] & fifoin_readys_out[ibuf];  

afifo_elastic
#(
    .WIDTH(WIDTH_RTL),
    .DEPTH(4)
)
fifo_in
(
   .write_clk(clk_rtl[ibuf]),
   .read_clk(clk),
   .rst(rst),
   .i_data_in  (     i_packets_in[ibuf]),
   .i_write_en (      i_valids_in[ibuf]),
   .i_ready_out(     i_readys_out[ibuf]),
   .o_data_out (   fifoin_packets[ibuf]),
   .o_read_en  (   fifoin_read_en[ibuf]),
   .o_ready_out(fifoin_readys_out[ibuf])
);

afifo_elastic
#(
    .WIDTH(WIDTH_RTL),
    .DEPTH(4)
)
fifo_out
(
   .write_clk(clk),
   .read_clk(clk_rtl[ibuf]),
   .rst(rst),
   .i_data_in  (       fifoout_packets[ibuf]),
   .i_write_en (        fifoout_valids[ibuf]),
   .i_ready_out( fifoout_in_readys_out[ibuf]),
   .o_data_out (         o_packets_out[ibuf]),
   .o_read_en  (           o_readys_in[ibuf] & fifoout_out_readys_out[ibuf]),
   .o_ready_out(fifoout_out_readys_out[ibuf])
);

end
endgenerate


//set fifo readdata valid: delayed readen signal
integer mm;
always @ (posedge clk_rtl[0])
if(rst)
    for(mm=0;mm<N;mm++)
    begin
        o_valids_out[mm]  <= 0;
    end
else
begin
    for(mm=0;mm<N;mm++)
        o_valids_out[mm] <= o_readys_in[mm] & fifoout_out_readys_out[mm];
end

always @ (posedge clk)
if(rst)
    for(mm=0;mm<N;mm++)
    begin
        fifoin_valids[mm] <= 0;
    end
else
begin
    fifoin_valids <= fifoin_read_en;
end



endmodule
