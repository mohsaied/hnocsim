/*
 * function : testbench for single-port RAM
 * author   : Mohamed S. Abdelfattah
 * date     : 14-SEPT-2015
 */

`timescale 1ns/1ps

module testbench_simple ();

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


parameter WIDTH_NOC    = 128;
parameter WIDTH_RTL    = 512;
parameter NUM_VC       = 2;
parameter DEPTH_PER_VC = 16;

//clocks and reset
logic         clk_noc;
logic [N-1:0] clk_rtl;
logic [N-1:0] clk_int;
	
//from rtl modules to noc
logic [WIDTH_RTL-1:0] i_packets_in [0:N-1];
logic                 i_valids_in  [0:N-1];
logic                 i_readys_out [0:N-1];

//from noc to rtl modules
logic [WIDTH_RTL-1:0] o_packets_out [0:N-1];	
logic                 o_valids_out  [0:N-1];	
logic                 o_readys_in   [0:N-1];


//local parameters
localparam ADDRESS_WIDTH = $clog2(N);
localparam VC_ADDRESS_WIDTH = $clog2(NUM_VC);

//the width of this data is equal to all the signals input to a RAM
parameter WIDTH_DATA_IN = PACKED_IN;
parameter WIDTH_DATA_OUT = PACKED_OUT;

//tb stuff
localparam N_INPUTS = 100;
localparam DEST_NODE = 1;
localparam SEED = 32'hBAADF00D;


//vars
int i;

//dut
fabric_interface 
#(.DEPTH_PER_VC(DEPTH_PER_VC))
dut ( .* );

//1 pkt input interface
logic [WIDTH_DATA_IN-1:0] pkt_data_in;
logic                     pkt_valid_in;
logic [ADDRESS_WIDTH-1:0] pkt_dest_in;
logic                     pkt_ready_out;

initial pkt_dest_in = DEST_NODE;

//instantiate a de/packetizer on the noc side
packetizer
#(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
	.WIDTH_IN(WIDTH_DATA_IN),
	.WIDTH_OUT(WIDTH_RTL)
)
pkt_inst_tin
(
	.i_data_in(pkt_data_in),
	.i_valid_in(pkt_valid_in),
	.i_dest_in(pkt_dest_in),
	.i_ready_out(pkt_ready_out),

	.o_data_out(i_packets_in[0]),
	.o_valid_out(i_valids_in[0]),
	.o_ready_in(i_readys_out[0])
);


//1 pkt output interface
logic [WIDTH_DATA_OUT-1:0] pkt_data_out;
logic                  pkt_valid_out;
logic                  pkt_ready_in;

depacketizer
#(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
	.WIDTH_PKT(WIDTH_RTL),
	.WIDTH_DATA(WIDTH_DATA_OUT)
)
depkt_inst_tin
(
	.i_packet_in(o_packets_out[0]),
	.i_valid_in(o_valids_out[0]),
	.i_ready_out(o_readys_in[0]),

	.o_data_out(pkt_data_out),
	.o_valid_out(pkt_valid_out),
	.o_ready_in(pkt_ready_in)
);


//1 pkt input interface
logic [WIDTH_DATA_OUT-1:0] ram_data_out;
logic                     ram_valid_out;
logic [ADDRESS_WIDTH-1:0] ram_dest_out;
logic                     ram_ready_in;


//instantiate a de/packetizer on the ram side
packetizer
#(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
	.WIDTH_IN(WIDTH_DATA_OUT),
	.WIDTH_OUT(WIDTH_RTL)
)
pkt_inst_rin
(
	.i_data_in(ram_data_out),
	.i_valid_in(ram_valid_out),
	.i_dest_in(ram_dest_out),
	.i_ready_out(ram_ready_in),

	.o_data_out(i_packets_in[DEST_NODE]),
	.o_valid_out(i_valids_in[DEST_NODE]),
	.o_ready_in(i_readys_out[DEST_NODE])
);


//1 pkt output interface
logic [WIDTH_DATA_IN-1:0] ram_data_in;
logic                  ram_valid_in;
logic                  ram_ready_out;

depacketizer
#(
	.ADDRESS_WIDTH(ADDRESS_WIDTH),
	.VC_ADDRESS_WIDTH(VC_ADDRESS_WIDTH),
	.WIDTH_PKT(WIDTH_RTL),
	.WIDTH_DATA(WIDTH_DATA_IN)
)
depkt_inst_rout
(
	.i_packet_in(o_packets_out[DEST_NODE]),
	.i_valid_in(o_valids_out[DEST_NODE]),
	.i_ready_out(o_readys_in[DEST_NODE]),

	.o_data_out(ram_data_in),
	.o_valid_out(ram_valid_in),
	.o_ready_in(ram_ready_out)
);


assign pkt_valid_in = i_read_en | i_write_en;
assign pkt_data_in = {i_data_in,i_addr_in,i_write_en,i_read_en,i_src_in};
assign pkt_dst_in = DEST_NODE;

assign o_data_out = pkt_data_out[PACKED_OUT-1 -: WIDTH];
assign o_src_out = pkt_data_out[PACKED_OUT-1-WIDTH -: N_ADDR_WIDTH];


//one module clk is connected to all the nodes
logic clk_rtls;
logic clk_ints;

generate
genvar iclk;
for(iclk=0;iclk<N;iclk++)
begin:clocks
assign clk_rtl[iclk] = clk_rtls;
assign clk_int[iclk] = clk_ints;
end
endgenerate


// generate clocks
initial clk_noc = 1'b1;
initial clk_ints = 1'b1;
initial clk_rtls = 1'b1;
always #1    clk_noc = ~clk_noc;
always #1.25 clk_ints = ~clk_ints; 
always #5    clk_rtls = ~clk_rtls; 

initial rst = 1;



//a memory device
ram 
#(
	.WIDTH(WIDTH),
	.ADDR_WIDTH(ADDR_WIDTH),
	.N(N),
	.NODE(DEST_NODE)
)
ram_inst
( 
	.clk(clk_rtls),
	.rst(rst),

	.i_packed_in(ram_data_in), //this should be connected to a NoC output
	.i_valid_in(ram_valid_in),
	.i_ready_out(ram_ready_out),

	.o_packed_out(ram_data_out), //and this connected to an input port
	.o_dest_out(ram_dest_out),
	.o_valid_out(ram_valid_out),
	.o_ready_in(ram_ready_in)
);


//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------


//inputs
initial i_data_in  = 8'bZ;
initial i_addr_in  = 4'bZ;
initial i_src_in  = 4'bZ;
initial i_write_en = 1'b0;
initial i_read_en = 1'b0;
initial o_ready_in = 1'b1;
initial pkt_ready_in = 1'b1;

int cycle_count = 0;
int data_cycle_count [0:15];

always @ (posedge clk_rtls)
	cycle_count = cycle_count + 1;


initial
begin

	@ (posedge clk_rtls)
	@ (posedge clk_rtls)
	@ (posedge clk_rtls)

	rst = 1'b0;
	
	@ (posedge clk_rtls)
	
	//write
	for(i = 0; i <2**ADDR_WIDTH;i++)
	begin
		@ (posedge clk_rtls)
		i_data_in  = i;
		i_src_in  = 0;
		i_addr_in  = i;
		i_write_en = 1'b1;
		i_read_en = 1'b0;
		o_ready_in = 1'b1;
	end
	
	//read
	for(i = 0; i <2**ADDR_WIDTH;i++)
	begin
		@ (posedge clk_rtls)
		i_data_in  = 2**ADDR_WIDTH-i-1;
		i_src_in  = 0;
		i_addr_in  = i;
		i_write_en = 1'b0;
		i_read_en = 1'b1;
		o_ready_in = 1'b1;
		data_cycle_count[i] = cycle_count; 
	end
	
	@ (posedge clk_rtls)
	//enough testing
	i_read_en = 0;
	i_write_en = 0;
	
	
end

int res=0;

//checker
always @ (posedge clk_rtls)
begin
	if (pkt_valid_out)
	begin
		if (o_data_out == res)
		begin
			$display("SUCCESS: Expected %d and received %d with latency %d (injected at %d and ejected at %d)",res,o_data_out,cycle_count - data_cycle_count[res],data_cycle_count[res],cycle_count);
			if (o_data_out == 15)
				$finish(0);
			res = res + 1;
		end

		else
		begin
			$display("FAILED: Expected %d and received %d",res,o_data_out);
			$stop(0);
		end

	end
end


endmodule
