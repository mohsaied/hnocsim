/*
 * funcion : noc writer takes packets from afifo writes them to the noc input port
 *           handles credits but does not select VC: will leave that for
 *           upstream module
 * author  : Mohamed S. Abdelfattah
 * date    : 5-SEPT-2014
 */

module noc_writer
#(
	parameter WIDTH  = 16,
	parameter N      = 16,
	parameter NUM_VC = 2,
	parameter DEPTH_PER_VC = 10,
	parameter ASSIGNED_VC = 0
)
(
	input wire clk,
	input wire rst,

	//read port
	input  wire [WIDTH-1:0] i_data_in,
	input  wire             i_ready_in,
	output reg              i_read_en,

	//write port
	output reg [WIDTH-1:0]  o_flit_out,
	input      [NUM_VC-1:0] o_credits_in
);


//local parameters
//localparam CREDIT_COUNT_WIDTH = $clog2(DEPTH_PER_VC);
localparam CREDIT_COUNT_WIDTH = $clog2(10);
localparam ADDRESS_WIDTH = $clog2(N);
localparam VC_ADDRESS_WIDTH = $clog2(NUM_VC);
localparam VALID_POS = WIDTH-1;
localparam HEAD_POS = WIDTH-2;
localparam TAIL_POS = WIDTH-3;
localparam VC_POS = WIDTH-4;
localparam DEST_POS = WIDTH-4-VC_ADDRESS_WIDTH;
localparam DATA_POS = WIDTH-4-ADDRESS_WIDTH-VC_ADDRESS_WIDTH;


//credit tracking
reg [CREDIT_COUNT_WIDTH:0] credit_count [0:NUM_VC-1];

//output valid and vc
reg [VC_ADDRESS_WIDTH-1:0] current_vc;
reg valid_out, vc_available, possible_data_received;

//loop variable
int i;

//-------------------------------------------------------------------------------
// Implementation
//-------------------------------------------------------------------------------

//counters that keep track of downstream buffer space availability
always @ (posedge clk)
begin

	//init to # of buffer spaces
	if(rst)
		for(i=0;i<NUM_VC;i++)
		  	credit_count[i] <= 10;
//			credit_count[i] <= DEPTH_PER_VC;
	
	else
	begin

		//increment whenever we get a credit and we aren't sending on that VC
		for(i=0;i<NUM_VC;i++)
			if(o_credits_in[i] & ~(valid_out & (i==current_vc) ) )
				credit_count[i] <= credit_count[i] + 1;

		//decrement whenever we send a flit and we aren't receiving a credit on that VC
		for(i=0;i<NUM_VC;i++)
			if(~o_credits_in[i] & valid_out & (i==current_vc))
				credit_count[i] <= credit_count[i] - 1;
	end
	
end

//delay the i_ready_in signal for 1 cycle
//to reflect when we actually get the data 
//from the afifo
reg vc_available_reg;
always @ (posedge clk)
begin
	possible_data_received <= i_ready_in; 
	vc_available_reg <= vc_available; 
end

//we read when our vc is available and the fifo isn't empty
assign current_vc = ASSIGNED_VC;
//assign current_vc = i_data_in[VALID_POS]==1 ? i_data_in[VC_POS -: VC_ADDRESS_WIDTH] : 1;
assign vc_available = ~(credit_count[current_vc] <= 1);
assign i_read_en = vc_available & i_ready_in;
//assign valid_out = possible_data_received & vc_available;
assign valid_out = possible_data_received & vc_available_reg;


//combinationally set the output
assign o_flit_out = {valid_out, i_data_in[HEAD_POS:0]};


endmodule
