/*
 * function : connect to booksim through SW fabricports
 * authors  : Mohamed S. Abdelfattah
 * date     : 04-JUL-2015, updated 06-OCT-2015
 */


module fabric_interface_sw #
(
	parameter WIDTH_NOC = 128, 
	parameter WIDTH_RTL = 512, 
	parameter N = 16,
	parameter NUM_VC = 2,
    parameter DEPTH_PER_VC = 8, //currently unused here, must change in cpp and noc_config
	parameter VERBOSE = 1,
    parameter VC_ADDRESS_WIDTH = $clog2(NUM_VC),
    parameter [VC_ADDRESS_WIDTH-1:0] COMBINE_DATA [0:N-1] = '{N{0}}
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
	input [3:0]  o_readys_in  [0:N-1],

    //valid signals
    input        i_valids_in  [0:N-1]

);

localparam SPECIAL_DEBUG = 0;

import "DPI-C" function void connectFabricSocket();
import "DPI-C" function void exitFabricSocket();
import "DPI-C" function void nextFabricCycle(input int speedup);
import "DPI-C" function void queueFabricFlit(input int pid, input int fid, input int source, input int destination, input int vc, input int head, input int tail);
import "DPI-C" function void ejectFourFabric_cd(input int node, input int combine_data, output int id0, output int id1, output int id2, output int id3, output int valid);
import "DPI-C" function int checkNocReady(input int node, input int vc);
import "DPI-C" function void sendModuleReady(input int node, input int vc, input int ready);

//local parameters
localparam STORAGE = 16;
localparam NUM_CYCLES = 100000;
localparam CLOCK_SPEEDUP = 1;

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
int     unsigned n;
longint unsigned cycle_count;

int received_ids [0:3];
int valid_from_noc;
int unsigned out_port; 

typedef struct    {
	bit 	         	 valid; 
	longint unsigned      p_id;
	longint unsigned      f_id;
	int	unsigned          dest;
	int	unsigned          src;
	int	unsigned          vc;
	logic [WIDTH_NOC-1:0] data;
} data_entry;

data_entry data_set [0:2**STORAGE-1];

logic [4:0] dest_table [0:N-1];

logic [WIDTH_NOC-1:0] flit;

//for afifos
logic [WIDTH_RTL-1:0] fifoin_packets    [0:N-1];
logic                 fifoin_read_en    [0:N-1];
logic                 fifoin_valids     [0:N-1];
logic                 fifoin_readys_out [0:N-1];

logic [WIDTH_RTL-1:0] fifoout_packets        [0:N-1];
logic    [3:0]        fifoout_valids         [0:N-1];
logic    [3:0]        fifoout_in_readys_out  [0:N-1];
logic    [3:0]        fifoout_out_readys_out [0:N-1];

logic [N-1:0] all_vcs_ready;

logic fifo_for_vc_is_ready;

logic [WIDTH_RTL-1:0] int_packets_out [0:N-1];
logic [3:0] o_valids_out [0:N-1];

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
            for(j=0;j<4;j++)
                fifoout_valids[i][j] = 0;
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
                    
                    //special debug
                    if(SPECIAL_DEBUG==1)
                    if(src==6 && dest==5 && assigned_vc==0 && (flit[100:14]==6 || flit[100:14]==5) )
                        $display("found flit in sv at queuefabric fcn. src=%d, dst=%d, vc=%d, data=%d",src,dest,assigned_vc,flit[100:14]);

                    if (VERBOSE == 1)
                        $display("Sending flit %d (%d) head = %d, tail = %d, from node %d on VC %d to node %d, (cycle = %d)",f_id,p_id[i],head,tail,i,assigned_vc,dest,cycle_count);
                    
                    // Store data
                    for (k=0; k<2**STORAGE; k=k+1) begin
                        if (data_set[k].valid == 1'b0) begin
                            data_set[k].p_id = p_id[i];
                            data_set[k].f_id = f_id;
                            data_set[k].valid = 1'b1;
                            data_set[k].src = src;
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
                //ok this is important: we have 4 valid signals for each slot in our noc, 
                //but logically we only need one valid per VC
                //so the first ready of a VC is indicative of its state
                //for example, if we have 2 VCs then ready[0] is for VC0 
                //and ready[1*4/2=2] is for VC1 while ready[1,3] are not checked
                //from the user perspective, the ready should be connected to all used slots to be safe
                //so ready[0,1] should be identical in this case

                //all fifos for a VC have to be ready, so that this VC is
                //considered ready -- we'll AND them
                fifo_for_vc_is_ready = 1;
                for(n= m*4/NUM_VC ;n<(m+1)*4/NUM_VC; n++)
                begin
                    fifo_for_vc_is_ready = fifo_for_vc_is_ready & fifoout_in_readys_out[l][n];
                end

                sendModuleReady(l,m,fifo_for_vc_is_ready);  
                //the ready signal is an AND of all VC readys
                all_vcs_ready[l] = all_vcs_ready[l] & checkNocReady(l,m);
            end
            
        end
        
		//--------------------------------------
		// eject received flits
		//--------------------------------------
	
		for (k=0; k<N; k=k+1) begin
		    //rst output valids to invalid (0)
            //init to "nothing received"
            for(l=0;l<4;l++) begin
                fifoout_valids[k][l] = 0;
                received_ids[l] = -1;
            end
			fifoout_packets[k] = 0;
           
            //check NOC for received packets
            ejectFourFabric_cd(k,COMBINE_DATA[k],received_ids[0],received_ids[1],received_ids[2],received_ids[3],valid_from_noc);
            
            //go over each flit slot
            for(l=0; l<4; l++) begin
                if (received_ids[l] >= 0) begin
                    // find data in data_set
                    for (j=0; j<2**STORAGE; j=j+1) begin
                        if (data_set[j].valid == 1'b1) begin
                            if (data_set[j].f_id == received_ids[l]) begin
                              
                                if (VERBOSE == 1)
                                     $display("Received flit %d at node %d, vc %d (cycle = %d)",received_ids[l],data_set[j].dest,data_set[j].vc,cycle_count);

                                // remove data from data_set
                                data_set[j].valid = 1'b0;

                                // send flit data to destination port
                                //rec_id0 goes in LSBs
                                fifoout_packets[k][WIDTH_RTL-1-WIDTH_NOC*(3-l) -: WIDTH_NOC] = data_set[j].data;
                                fifoout_valids[k][l] = 1;
                                 
                                //special debug
                                if(SPECIAL_DEBUG==1)
                                if(data_set[j].src==6 && k==5 && l==1 && (data_set[j].data[100:14]==6 || data_set[j].data[100:14]==5) )
                                    $display("found flit in sv at ejectfabric fcn. src=%d, dst=%d, vc=%d, data=%d, fullflit(at fifo %d)=%d",data_set[j].src,k,data_set[j].vc,data_set[j].data[100:14], 3-l, data_set[j].data);


                                break;
                            end
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
genvar ibuf, iflit;
for(ibuf = 0; ibuf < N; ibuf = ibuf + 1)
begin:ibufs

assign fifoin_read_en[ibuf] = all_vcs_ready[ibuf] & fifoin_readys_out[ibuf];  

afifo_elastic
#(
    .WIDTH(WIDTH_RTL),
    .DEPTH(8)
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


for(iflit = 0; iflit < 4; iflit = iflit + 1)
begin:iflits

afifo_elastic
#(
    .WIDTH(WIDTH_NOC),
    .DEPTH(8)
)
fifo_out
(
   .write_clk(clk),
   .read_clk(clk_rtl[ibuf]),
   .rst(rst),
   .i_data_in  (       fifoout_packets[ibuf][WIDTH_RTL-1-WIDTH_NOC*(3-iflit) -: WIDTH_NOC]),
   .i_write_en (        fifoout_valids[ibuf][iflit]),
   .i_ready_out( fifoout_in_readys_out[ibuf][iflit]),
   .o_data_out (       int_packets_out[ibuf][WIDTH_RTL-1-WIDTH_NOC*(3-iflit) -: WIDTH_NOC]),
   .o_read_en  (           o_readys_in[ibuf][iflit] & fifoout_out_readys_out[ibuf][iflit]),
   .o_ready_out(fifoout_out_readys_out[ibuf][iflit])
);


    always @ (posedge clk_rtl[ibuf])
    if(rst)
        o_valids_out[ibuf][iflit]  <= 0;
    else
    begin
        o_valids_out[ibuf][iflit] <= o_readys_in[ibuf][iflit] & fifoout_out_readys_out[ibuf][iflit];
    end

    //special debug
    always@(posedge clk)
    begin
        if(SPECIAL_DEBUG==1)
        if(fifoout_packets[ibuf][WIDTH_RTL-1-WIDTH_NOC*(3-iflit) -: WIDTH_NOC]==150'd1278877103820954420836469556694530119249772544 || fifoout_packets[ibuf][WIDTH_RTL-1-WIDTH_NOC*(3-iflit) -: WIDTH_NOC]==150'd1279051339026641907609089787723991666816794624)
        begin
            $display("found flit %d at fifo input. node=%d, slot=%d, valid=%d", fifoout_packets[ibuf][WIDTH_RTL-1-WIDTH_NOC*(3-iflit) -: WIDTH_NOC], ibuf, iflit, fifoout_valids[ibuf][iflit]);
            $display("current time = %d",$time);
        end
    end
    
    //special debug
    always@(posedge clk_rtl[ibuf])
    begin
        if(SPECIAL_DEBUG==1)
        if(o_packets_out[ibuf][WIDTH_RTL-1-WIDTH_NOC*(3-iflit) -: WIDTH_NOC]==150'd1278877103820954420836469556694530119249772544 || o_packets_out[ibuf][WIDTH_RTL-1-WIDTH_NOC*(3-iflit) -: WIDTH_NOC]==150'd1279051339026641907609089787723991666816794624)
            $display("found flit %d at fifo output. node=%d, slot=%d", o_packets_out[ibuf][WIDTH_RTL-1-WIDTH_NOC*(3-iflit) -: WIDTH_NOC], ibuf, iflit);
    end

end

//important! this makes sure the valid doesn't stay 1, we invalidate the
//packet as soon as it has been consumed at the module
assign o_packets_out[ibuf] = int_packets_out[ibuf] & {o_valids_out[ibuf][3], {(WIDTH_NOC-1){1'b1}}, o_valids_out[ibuf][2], {(WIDTH_NOC-1){1'b1}}, o_valids_out[ibuf][1], {(WIDTH_NOC-1){1'b1}}, o_valids_out[ibuf][0], {(WIDTH_NOC-1){1'b1}} };

end
endgenerate


//set fifo readdata valid: delayed readen signal
integer mm;
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
