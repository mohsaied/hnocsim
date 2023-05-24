/*
 * function : read flits from noc and buffer in VCs
 *            then forward to asynchronous fifo and
 *            send back credits as soon as we send
 * author   : Mohamed S. Abdelfattah
 * date     : 29-AUG-2014
 */

module noc_reader
#(
	parameter DEPTH_PER_VC = 8,
	parameter WIDTH = 8,
	parameter NUM_VC = 2,
	parameter N = 16
)
(
	input wire clk,
	input wire rst,

	//read from noc
	input  reg [WIDTH-1:0]  i_flit_in,
	output reg [NUM_VC-1:0] i_credits_out,

	//write port to afifo
	output reg [WIDTH-1:0] o_data_out,
	output reg             o_write_en,
	input  wire            o_ready_in
);

localparam ADDRESS_WIDTH = $clog2(N);
localparam VC_ADDRESS_WIDTH = $clog2(NUM_VC);
localparam VALID_POS = WIDTH-1;
localparam HEAD_POS = WIDTH-2;
localparam TAIL_POS = WIDTH-3;
localparam VC_POS = WIDTH-4;
localparam COUNT_WIDTH = $clog2(DEPTH_PER_VC+1);


//register to hold indicate head/tail/vc on the input
reg valid;
reg [VC_ADDRESS_WIDTH-1:0] fifo_write_vc;

//fifo signals
reg [WIDTH-1:0]  fifo_data_in;
reg [NUM_VC-1:0] fifo_write_en;

wire [WIDTH-1:0]  fifo_data_out    [0:NUM_VC-1];
reg  [0:NUM_VC-1] fifo_read_en;
wire [0:NUM_VC-1] fifo_empty;
wire [0:NUM_VC-1] fifo_almost_empty;
wire [0:NUM_VC-1] fifo_next_is_tail;

int i;

//----------------------------------------------------------------------------
// Implementation
//----------------------------------------------------------------------------


//generate one fifo per vc
generate
	genvar ivc;
	for(ivc = 0; ivc < NUM_VC; ivc = ivc + 1)
	begin:ivcs

		fifo
		#(
			.WIDTH(WIDTH),
			.DEPTH(DEPTH_PER_VC)
		)
		fifo_buffer
		(
			.clk(clk),
			.clear(rst),

			.i_data_in(fifo_data_in),
			.i_write_en(fifo_write_en[ivc]),
			.i_full_out(), //leave unconnected: backpressure is done through credits

			.o_data_out(fifo_data_out[ivc]),
			.o_read_en(fifo_read_en[ivc]),
			.o_empty_out(fifo_empty[ivc]),
			.o_almost_empty_out(fifo_almost_empty[ivc]),
			.o_next_is_tail(fifo_next_is_tail[ivc])
		);
	
	end
endgenerate

//set the proper write enable on packet granularity
//must store it so we have an extra cycle of latency
//but it's the fast clock so should be okay
always @ (posedge clk)
begin
	
	if (rst)
	begin
		fifo_write_en <= 0;
		fifo_write_vc <= 0;
	end
	
	else
	begin

		valid = i_flit_in[VALID_POS];
		fifo_write_vc = i_flit_in[VC_POS -: VC_ADDRESS_WIDTH];	
		
		//if the incoming flit is valid we'll enter it into our buffers
		if (valid)
		begin
			fifo_data_in <= i_flit_in;
			fifo_write_en = 0;
			fifo_write_en[fifo_write_vc] = 1'b1;
		end
		else
			fifo_write_en <= 0;
		
		//send back credit when we forward a flit
		for	(i = 0; i < NUM_VC; i++)
			if (fifo_read_en[i])
				i_credits_out[i] = 1'b1;
			else
				i_credits_out[i] = 1'b0;
	end

end

reg [VC_ADDRESS_WIDTH-1:0] fifo_read_vc;
reg [VC_ADDRESS_WIDTH-1:0] past_fifo_read_vc;
reg vc_changed;

reg [2:0] state;
parameter FIND_NEXT_VC = 3'b000,
		  READ_FLIT = 3'b001,
		  WAIT_MID_PACKET = 3'b010;

//read state machine
always @ (posedge clk)
begin

	if (rst)
	begin
		fifo_read_vc <= 0;
		//fifo_read_en <= 0;
		
		//state transition
		state <= FIND_NEXT_VC;
	end

	else if (state == READ_FLIT)
	begin
		//-----------------
		//state transition
		//-----------------

		//if output is stalling remove read en and go to wait state
		if (~o_ready_in)
		begin
			//fifo_read_en = 0;
			state <= WAIT_MID_PACKET;
		end
		
		//if fifo runs empty mid-packet, remove read en and go to wait state
		else if (fifo_empty[fifo_read_vc] & ~fifo_next_is_tail[fifo_read_vc])
		begin
			//fifo_read_en = 0;
			state <= WAIT_MID_PACKET;
		end

		//if the next flit is tail we'll go to find the next available VC 
		else if (fifo_next_is_tail[fifo_read_vc])
		begin
			//now we need to go and select a new vc right away
			//the current vc we're at before arbitration
			past_fifo_read_vc = fifo_read_vc;
		
			//here we need to find the next VC that isn't empty (fair arbiter)
			fifo_read_vc = fifo_read_vc + 1;
			for(i = 1; i < NUM_VC; i++)
				if (fifo_empty[fifo_read_vc])
					fifo_read_vc = fifo_read_vc + 1;	
		
			//did the arbiter select a new vc?
			if (fifo_read_vc == past_fifo_read_vc)
				vc_changed = 0;
			else 
				vc_changed = 1;
			
			//-----------------
			//state transition
			//-----------------
		
			//fifo_read_en = 0;

			//if we didn't find a VC that isn't empty just keep searching
			if (fifo_empty[fifo_read_vc] | (~vc_changed & fifo_almost_empty[fifo_read_vc]))
			begin
				state <= FIND_NEXT_VC;
			end
			
			//if we found a vc that has something in it and we can read
			//first case: we changed the VC
			else if (o_ready_in & vc_changed & ~fifo_empty[fifo_read_vc])
			begin
				//fifo_read_en[fifo_read_vc] = 1'b1;
				state <= READ_FLIT;
			end
			
			//if we found a vc that has something in it and we can read
			//second case: we're sticking to the same VC
			else if (o_ready_in & ~vc_changed & ~fifo_almost_empty[fifo_read_vc])
			begin
				//fifo_read_en[fifo_read_vc] = 1'b1;
				state <= READ_FLIT;
			end

			//if we found a vc that has something in it but we can't read yet
			else if (~o_ready_in)
			begin
				state <= WAIT_MID_PACKET;
			end

		end
	end

	else if (state == WAIT_MID_PACKET)
	begin
		if (o_ready_in & ~fifo_empty[fifo_read_vc])
		begin
			
			//we will read a word here so we need to check if it's a tail flit
			if (fifo_next_is_tail[fifo_read_vc])
			begin
				//now we need to go and select a new vc right away
				//the current vc we're at before arbitration
				past_fifo_read_vc = fifo_read_vc;
		
				//here we need to find the next VC that isn't empty (fair arbiter)
				fifo_read_vc = fifo_read_vc + 1;
				for(i = 1; i < NUM_VC; i++)
					if (fifo_empty[fifo_read_vc])
						fifo_read_vc = fifo_read_vc + 1;	
		
				//did the arbiter select a new vc?
				if (fifo_read_vc == past_fifo_read_vc)
					vc_changed = 0;
				else 
					vc_changed = 1;
			
				//-----------------
				//state transition
				//-----------------
		
				//fifo_read_en = 0;

				//if we didn't find a VC that isn't empty just keep searching
				if (fifo_empty[fifo_read_vc])
				begin
					state <= FIND_NEXT_VC;
				end
			
				//if we found a vc that has something in it and we can read
				//first case: we changed the VC
				else if (o_ready_in & vc_changed & ~fifo_empty[fifo_read_vc])
				begin
					//fifo_read_en[fifo_read_vc] = 1'b1;
					state <= READ_FLIT;
				end
			
				//if we found a vc that has something in it and we can read
				//second case: we're sticking to the same VC
				else if (o_ready_in & ~vc_changed & ~fifo_almost_empty[fifo_read_vc])
				begin
					//fifo_read_en[fifo_read_vc] = 1'b1;
					state <= READ_FLIT;
				end
				//if we found a vc that has something in it but we can't read yet
				else if (~o_ready_in)
				begin
					state <= WAIT_MID_PACKET;
				end

			end

			else
			begin
				//fifo_read_en[fifo_read_vc] = 1'b1;
				state <= READ_FLIT;
			end

		end
	end

	else if (state == FIND_NEXT_VC)
	begin
		//the current vc we're at before arbitration
		past_fifo_read_vc = fifo_read_vc;
		
		//here we need to find the next VC that isn't empty (fair arbiter)
		fifo_read_vc = fifo_read_vc + 1;
		for(i = 1; i < NUM_VC; i++)
			if (fifo_empty[fifo_read_vc])
				fifo_read_vc = fifo_read_vc + 1;	
		
		//did the arbiter select a new vc?
		if (fifo_read_vc == past_fifo_read_vc)
			vc_changed = 0;
		else 
			vc_changed = 1;
			
		//-----------------
		//state transition
		//-----------------
		
		//fifo_read_en = 0;

		//if we didn't find a VC that isn't empty just keep searching
		if (fifo_empty[fifo_read_vc])
		begin
			state <= FIND_NEXT_VC;
		end
			
		//if we found a vc that has something in it and we can read
		//first case: we changed the VC
		else if (o_ready_in & vc_changed & ~fifo_empty[fifo_read_vc])
		begin
			//fifo_read_en[fifo_read_vc] = 1'b1;
			state <= READ_FLIT;
		end
			
		//if we found a vc that has something in it and we can read
		//second case: we're sticking to the same VC
		else if (o_ready_in & ~vc_changed & ~fifo_almost_empty[fifo_read_vc])
		begin
			//fifo_read_en[fifo_read_vc] = 1'b1;
			state <= READ_FLIT;
		end
		
		//HACK
		//third case: 
		else if (o_ready_in & fifo_almost_empty[fifo_read_vc])
		begin
			//fifo_read_en[fifo_read_vc] = 1'b1;
			state <= WAIT_MID_PACKET;
		end


		//if we found a vc that has something in it but we can't read yet
		else if (~o_ready_in)
		begin
			state <= WAIT_MID_PACKET;
		end
	end


end

//combinational output to avoid wasting any cycles especially with stalls

//generate one fifo per vc
generate

	for(ivc = 0; ivc < NUM_VC; ivc = ivc + 1)
	begin:read_ens
		assign fifo_read_en[ivc] = ((fifo_read_vc == ivc) & (o_ready_in) & ~fifo_empty[fifo_read_vc]) ? 1'b1 : 1'b0;
	end

endgenerate


//delay the vc/enable signals
reg [VC_ADDRESS_WIDTH-1:0] fifo_read_vc_reg;
reg [VC_ADDRESS_WIDTH-1:0] fifo_read_vc_reg2;
reg [NUM_VC-1:0] fifo_read_en_reg;
reg [NUM_VC-1:0] fifo_read_en_reg2;

always @ (posedge clk)
	if (rst)
	begin
		fifo_read_vc_reg <= 0;
		fifo_read_vc_reg2 <= 0;
		fifo_read_en_reg <= 0;
		fifo_read_en_reg2 <= 0;
	end
	
	else
	begin
		fifo_read_vc_reg2 <= fifo_read_vc;
		fifo_read_vc_reg <= fifo_read_vc_reg2;
		fifo_read_en_reg2 <= fifo_read_en;
		fifo_read_en_reg <= fifo_read_en_reg2;
	end

//assign output write enable
assign o_write_en = | fifo_read_en_reg2;

//comb mux for data output
assign o_data_out = o_write_en ? fifo_data_out[fifo_read_vc_reg] : 0;

endmodule
