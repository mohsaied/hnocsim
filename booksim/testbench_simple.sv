`timescale 1ps/1ps

module testbench();

parameter WIDTH = 128; //bits
parameter N = 16;
parameter NUM_VC = 2;
parameter NUM_CYCLES = 100;
parameter SEED = 1;

//local parameters
localparam ADDRESS_WIDTH = $clog2(N);
localparam VC_ADDRESS_WIDTH = $clog2(NUM_VC);
localparam VALID_POS = WIDTH-1;
localparam HEAD_POS = WIDTH-2;
localparam TAIL_POS = WIDTH-3;
localparam VC_POS = WIDTH-4;
localparam DEST_POS = WIDTH-4-VC_ADDRESS_WIDTH;


logic clk;

int i;
int cycle_count;

logic [WIDTH-1:0] data_in     [0:N-1];

logic [WIDTH-1:0] data_out  [0:N-1];

logic [NUM_VC-1:0] credits_downstream [0:N-1];

logic [NUM_VC-1:0] credits_upstream [0:N-1];

rtl_interface #(.WIDTH(WIDTH),
				.N(N),
				.NUM_VC(NUM_VC),
				.NUM_CYCLES(NUM_CYCLES)
				) rtl_interface (
					.clk(clk),
					.reset(1'b0),
					.i_flit_in(data_in),
					.o_flit_out(data_out),
					.credits_to_noc(credits_downstream),
					.credits_to_rtl(credits_upstream)
				);  

// generate clock
initial clk = 1'b1;
always #2500 clk = ~clk; // 200 MHz clock

//simple testbench sends one packet
initial begin

	cycle_count = 0;

	for (i=0; i<N; i=i+1) begin
		data_in[i] = 512'd0;
		credits_downstream[i] = 0;
	end
	
	//three clock cycles later
	@(posedge clk)
	@(posedge clk)
	@(posedge clk)
	
	//send a packet from node 0 to node 15
	data_in[0] = 128'd999;
	data_in[0][WIDTH-1] = 1'b1; //valid
	data_in[0][WIDTH-2] = 1'b1; //head
	data_in[0][WIDTH-3] = 1'b0; //tail
	data_in[0][DEST_POS -: ADDRESS_WIDTH] = 4'd4; //dest
	data_in[0][VC_POS -: VC_ADDRESS_WIDTH] = 1'b1; //start VC
	$display("VC pos = %d",VC_POS);
	$display("Injecting at node 0, to node %p. (Cycle=%d)",data_in[0][DEST_POS-:ADDRESS_WIDTH],cycle_count);
	
	@(posedge clk)

	data_in[0] = 128'd999;
	data_in[0][WIDTH-1] = 1'b1; //valid
	data_in[0][WIDTH-2] = 1'b0; //head
	data_in[0][WIDTH-3] = 1'b0; //tail
	data_in[0][VC_POS -: VC_ADDRESS_WIDTH] = 1'b1; //start VC
	//$display("Injecting at node 0. (Cycle=%d)",cycle_count);
	
	@(posedge clk)
	
	data_in[0] = 128'd999;
	data_in[0][WIDTH-1] = 1'b1; //valid
	data_in[0][WIDTH-2] = 1'b0; //head
	data_in[0][WIDTH-3] = 1'b0; //tail
	data_in[0][VC_POS -: VC_ADDRESS_WIDTH] = 1'b1; //start VC
	//$display("Injecting at node 0. (Cycle=%d)",cycle_count);
	
	@(posedge clk)

	data_in[0] = 128'd999;
	data_in[0][WIDTH-1] = 1'b1; //valid
	data_in[0][WIDTH-2] = 1'b0; //head
	data_in[0][WIDTH-3] = 1'b1; //tail
	data_in[0][VC_POS -: VC_ADDRESS_WIDTH] = 1'b1; //start VC
	//$display("Injecting at node 0. (Cycle=%d)",cycle_count);
	
	@(posedge clk)
	
	//valid
	data_in[0][WIDTH-1] = 1'b0;
	
end

//listen for received packets
always_ff @(posedge clk) begin
	cycle_count = cycle_count + 1;
	for (i=0; i<N; i=i+1)
		if(data_out[i][WIDTH-1] == 1'b1)
			$display("Confirm received flit at node %d, data = %h. (Cycle=%d)",i,data_out[i],cycle_count);
end


endmodule





