/*
 * function: testbench to verify basic ops
 * author  : Mohamed S. Abdelfattah
 * date    : 25-AUG-2014
 */

module tb_noc_reader ();



parameter DEPTH_PER_VC = 8;
parameter WIDTH = 8;
parameter NUM_VC = 2;
parameter N = 16;


logic clk;
logic rst;

//read from noc
logic [WIDTH-1:0]  i_flit_in;
logic [NUM_VC-1:0] i_credits_out;

//write port to afifo
logic [WIDTH-1:0] o_data_out;
logic             o_write_en;
logic             o_ready_in;

//using same signal names
noc_reader dut ( .* );


localparam ADDRESS_WIDTH = $clog2(N);
localparam VC_ADDRESS_WIDTH = $clog2(NUM_VC);
localparam VALID_POS = WIDTH-1;
localparam HEAD_POS = WIDTH-2;
localparam TAIL_POS = WIDTH-3;
localparam VC_POS = WIDTH-4;
localparam DEST_POS = WIDTH-4-VC_ADDRESS_WIDTH;


//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

//clocks
initial clk = 1'b1;

//toggle forever
always #5 clk = ~clk;


//reset
initial rst = 1'b1;

//inputs
initial i_flit_in  = 4'bZ;
initial o_ready_in = 1'b0;


//some test cases
initial begin

	@(posedge clk);
	@(posedge clk);
	
	rst= 1'b0;

	
	o_ready_in = 0;	
	//write a 4 flit packet into vc 1
	@(posedge clk);
	i_flit_in = 0;
	i_flit_in[VALID_POS] = 1;
	i_flit_in[HEAD_POS] = 1;
	i_flit_in[TAIL_POS] = 0;
	i_flit_in[VC_POS -: VC_ADDRESS_WIDTH] = 1;
	i_flit_in[DEST_POS -: ADDRESS_WIDTH] = 1;
	@(posedge clk);
	i_flit_in = 0;
	i_flit_in[VALID_POS] = 1;
	i_flit_in[HEAD_POS] = 0;
	i_flit_in[TAIL_POS] = 0;
	i_flit_in[VC_POS -: VC_ADDRESS_WIDTH] = 1;
	i_flit_in[DEST_POS -: ADDRESS_WIDTH] = 1;
	@(posedge clk);
	i_flit_in = 0;
	i_flit_in[VALID_POS] = 1;
	i_flit_in[HEAD_POS] = 0;
	i_flit_in[TAIL_POS] = 0;
	i_flit_in[VC_POS -: VC_ADDRESS_WIDTH] = 1;
	i_flit_in[DEST_POS -: ADDRESS_WIDTH] = 1;
	@(posedge clk);
	i_flit_in = 0;
	i_flit_in[VALID_POS] = 1;
	i_flit_in[HEAD_POS] = 0;
	i_flit_in[TAIL_POS] = 1;
	i_flit_in[VC_POS -: VC_ADDRESS_WIDTH] = 1;
	i_flit_in[DEST_POS -: ADDRESS_WIDTH] = 1;

	@(posedge clk);
	i_flit_in = 0;
	i_flit_in[VALID_POS] = 0;

	@(posedge clk);
	@(posedge clk);
	
	
	//write a 4 flit packet into vc 0
	@(posedge clk);
	i_flit_in = 0;
	i_flit_in[VALID_POS] = 1;
	i_flit_in[HEAD_POS] = 1;
	i_flit_in[TAIL_POS] = 0;
	i_flit_in[VC_POS -: VC_ADDRESS_WIDTH] = 0;
	i_flit_in[DEST_POS -: ADDRESS_WIDTH] = 2;
	@(posedge clk);
	i_flit_in = 0;
	i_flit_in[VALID_POS] = 1;
	i_flit_in[HEAD_POS] = 0;
	i_flit_in[TAIL_POS] = 0;
	i_flit_in[VC_POS -: VC_ADDRESS_WIDTH] = 0;
	i_flit_in[DEST_POS -: ADDRESS_WIDTH] = 2;
	@(posedge clk);
	i_flit_in = 0;
	i_flit_in[VALID_POS] = 1;
	i_flit_in[HEAD_POS] = 0;
	i_flit_in[TAIL_POS] = 0;
	i_flit_in[VC_POS -: VC_ADDRESS_WIDTH] = 0;
	i_flit_in[DEST_POS -: ADDRESS_WIDTH] = 2;
	@(posedge clk);
	i_flit_in = 0;
	i_flit_in[VALID_POS] = 1;
	i_flit_in[HEAD_POS] = 0;
	i_flit_in[TAIL_POS] = 1;
	i_flit_in[VC_POS -: VC_ADDRESS_WIDTH] = 0;
	i_flit_in[DEST_POS -: ADDRESS_WIDTH] = 2;
	
	//and another packet right away in vc 1
	@(posedge clk);
	i_flit_in = 0;
	i_flit_in[VALID_POS] = 1;
	i_flit_in[HEAD_POS] = 1;
	i_flit_in[TAIL_POS] = 0;
	i_flit_in[VC_POS -: VC_ADDRESS_WIDTH] = 1;	
	i_flit_in[DEST_POS -: ADDRESS_WIDTH] = 3;
	@(posedge clk);
	i_flit_in = 0;
	i_flit_in[VALID_POS] = 1;
	i_flit_in[HEAD_POS] = 0;
	i_flit_in[TAIL_POS] = 0;
	i_flit_in[VC_POS -: VC_ADDRESS_WIDTH] = 1;	
	i_flit_in[DEST_POS -: ADDRESS_WIDTH] = 3;
	@(posedge clk);
	i_flit_in = 0;
	i_flit_in[VALID_POS] = 1;
	i_flit_in[HEAD_POS] = 0;
	i_flit_in[TAIL_POS] = 0;
	i_flit_in[VC_POS -: VC_ADDRESS_WIDTH] = 1;	
	i_flit_in[DEST_POS -: ADDRESS_WIDTH] = 3;
	@(posedge clk);
	i_flit_in = 0;
	i_flit_in[VALID_POS] = 1;
	i_flit_in[HEAD_POS] = 0;
	i_flit_in[TAIL_POS] = 1;
	i_flit_in[VC_POS -: VC_ADDRESS_WIDTH] = 1;	
	i_flit_in[DEST_POS -: ADDRESS_WIDTH] = 3;

	@(posedge clk);
	i_flit_in = 0;
	i_flit_in[VALID_POS] = 0;

	@(posedge clk);
	@(posedge clk);
	
	o_ready_in = 1;	
		
	//read 3 words
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	
	//then stall mid-packet or at the edge of a packet
	o_ready_in = 0;

	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	
	//then enable again
	o_ready_in = 1;

	@(posedge clk);
	@(posedge clk);

	//now we want to try corner cases

	//get the head flit
	@(posedge clk);
	i_flit_in = 0;
	i_flit_in[VALID_POS] = 1;
	i_flit_in[HEAD_POS] = 1;
	i_flit_in[TAIL_POS] = 0;
	i_flit_in[VC_POS -: VC_ADDRESS_WIDTH] = 1;	
	i_flit_in[DEST_POS -: ADDRESS_WIDTH] = 4;

	//stall
	@(posedge clk);


	//get the tail
	i_flit_in = 0;
	i_flit_in[VALID_POS] = 1;
	i_flit_in[HEAD_POS] = 0;
	i_flit_in[TAIL_POS] = 1;
	i_flit_in[VC_POS -: VC_ADDRESS_WIDTH] = 1;	
	i_flit_in[DEST_POS -: ADDRESS_WIDTH] = 4;

	//2 cycles pass when we're stalling
	@(posedge clk);
	i_flit_in = 0;
	@(posedge clk);
	
	//then finally we unstall
	@(posedge clk);
	o_ready_in = 1;

	@(posedge clk);
	@(posedge clk);
	@(posedge clk);

end

endmodule
