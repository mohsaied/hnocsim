/*
 * function : generate test packets 
 * author   : Mohamed S. Abdelfattah
 * date     : 13-MAR-2015
 */

module pkt_generator
#(
    // AVL SIDE ////////////
    parameter AVL_ADDR_WIDTH = 29,
    parameter AVL_DATA_WIDTH = 512,
    parameter AVL_BYTE_EN_WIDTH = AVL_DATA_WIDTH/8,
    parameter FRAME_ID_WIDTH = 4+28,
    parameter BIN_ADDR_WIDTH = 8,    // how many frame buffers will we have
    parameter FRAME_OFFSET_WIDTH = 5,  // what is the maximum frame length in (4-flit) cycles?
                                       // the frame offset is log2 that value

    // NOC SIDE ////////////
	parameter WIDTH_PKT = AVL_DATA_WIDTH+1+1+FRAME_ID_WIDTH //this is the data width after the translator strips away the flit headers
)
(
    input clk,
    input rst,

    // NOC SIDE ////////////////////////////

    //packets coming out of NoC (fp output)
    //use depacketizer_sop to allow variable-length packets
	output wire [WIDTH_PKT-1:0] noc_data_in,
	output wire           [3:0] noc_valid_in,
	input  wire                 noc_ready_out,
    output wire           [3:0] noc_sop_in,
    output wire           [3:0] noc_eop_in

    //need to be able to stop the ddr3 module with backpressure from noc
    //but it does not respond to backpressure!
    //this means that I have to do something smart
    //for example: buffer all read requests until the reply is accepted at the NoC

);

//-------------------------------------------------------------------------
// Implementation
//-------------------------------------------------------------------------

// at which bit does each piece of data start?
localparam WRITE_POS = WIDTH_PKT - 1;
localparam READ_POS  = WRITE_POS - 1;
localparam ID_POS    = READ_POS  - 1;
localparam DATA_POS  = ID_POS - FRAME_ID_WIDTH;


// signals to get data from NoC
reg                      frame_valid;
reg [AVL_DATA_WIDTH-1:0] frame_data;
reg                      frame_write;
reg                      frame_read;

reg [FRAME_ID_WIDTH-1:0] frame_id;
reg                [3:0] port_id;
reg [FRAME_ID_WIDTH-4:0] frame_count;
reg [FRAME_ID_WIDTH-4:0] frame_count_rev;

reg                      frame_sop;
reg                      frame_eop;

reg noc_ready_reg;


integer i;

///////////////////////////////////////////////////////////////////////
//try a single write and read
initial 
begin

frame_valid = 0;
frame_data  = 0;
frame_write = 0;
frame_read  = 0;
port_id     = 0;
frame_count = 0;
for(i = 0; i < FRAME_ID_WIDTH-4; i++)
    frame_count_rev[FRAME_ID_WIDTH-4-i] = frame_count[i];         
frame_sop   = 0;
frame_eop   = 0;

//wait until reset is deasserted
while(rst)
begin
    @(posedge clk);
end
$display("RESET Deasserted");

@(posedge clk);
@(posedge clk);
@(posedge clk);

/**********************
  FIRST BEAT
**********************/

//wait until ready is 1
@(posedge clk);
while(noc_ready_reg == 0)
begin
    @(posedge clk);
end

$display("Sending first nocunit");

frame_valid = 1;
frame_data  = 1;
frame_write = 1;
frame_read  = 0;
port_id     = 3;
frame_count = 3;
for(i = 0; i < FRAME_ID_WIDTH-3; i++)
    frame_count_rev[FRAME_ID_WIDTH-4-i] = frame_count[i];         
frame_sop   = 1;
frame_eop   = 0;


/**********************
  SECOND BEAT
**********************/

//wait until ready is 1
@(posedge clk);
while(noc_ready_reg == 0)
begin
    @(posedge clk);
end

$display("Sending second nocunit");

frame_valid = 1;
frame_data  = 2;
frame_write = 1;
frame_read  = 0;
port_id     = 3;
frame_count = 3;
for(i = 0; i < FRAME_ID_WIDTH-3; i++)
    frame_count_rev[FRAME_ID_WIDTH-4-i] = frame_count[i];         
frame_sop   = 0;
frame_eop   = 0;


/**********************
  THIRD BEAT
**********************/

//wait until ready is 1
@(posedge clk);
while(noc_ready_reg == 0)
begin
    @(posedge clk);
end

$display("Sending third nocunit");

frame_valid = 1;
frame_data  = 3;
frame_write = 1;
frame_read  = 0;
port_id     = 3;
frame_count = 3;
for(i = 0; i < FRAME_ID_WIDTH-3; i++)
    frame_count_rev[FRAME_ID_WIDTH-4-i] = frame_count[i];         
frame_sop   = 0;
frame_eop   = 0;


/**********************
  FOURTH BEAT
**********************/

//wait until ready is 1
@(posedge clk);
while(noc_ready_reg == 0)
begin
    @(posedge clk);
end

$display("Sending fourth nocunit");

frame_valid = 1;
frame_data  = 4;
frame_write = 1;
frame_read  = 0;
port_id     = 3;
frame_count = 3;
for(i = 0; i < FRAME_ID_WIDTH-3; i++)
    frame_count_rev[FRAME_ID_WIDTH-4-i] = frame_count[i];         
frame_sop   = 0;
frame_eop   = 0;


/**********************
  FIFTH BEAT
**********************/

//wait until ready is 1
@(posedge clk);
while(noc_ready_reg == 0)
begin
    @(posedge clk);
end

$display("Sending fifth nocunit");

frame_valid = 1;
frame_data  = 5;
frame_write = 1;
frame_read  = 0;
port_id     = 3;
frame_count = 3;
for(i = 0; i < FRAME_ID_WIDTH-3; i++)
    frame_count_rev[FRAME_ID_WIDTH-4-i] = frame_count[i];         
frame_sop   = 0;
frame_eop   = 0;


/**********************
  SIXTH BEAT
**********************/

//wait until ready is 1
@(posedge clk);
while(noc_ready_reg == 0)
begin
    @(posedge clk);
end

$display("Sending sixth nocunit");

frame_valid = 1;
frame_data  = 6;
frame_write = 1;
frame_read  = 0;
port_id     = 3;
frame_count = 3;
for(i = 0; i < FRAME_ID_WIDTH-3; i++)
    frame_count_rev[FRAME_ID_WIDTH-4-i] = frame_count[i];         
frame_sop   = 0;
frame_eop   = 0;


/**********************
  SEVENTH BEAT
**********************/

//wait until ready is 1
@(posedge clk);
while(noc_ready_reg == 0)
begin
    @(posedge clk);
end

$display("Sending seventh nocunit");

frame_valid = 1;
frame_data  = 7;
frame_write = 1;
frame_read  = 0;
port_id     = 3;
frame_count = 3;
for(i = 0; i < FRAME_ID_WIDTH-3; i++)
    frame_count_rev[FRAME_ID_WIDTH-4-i] = frame_count[i];         
frame_sop   = 0;
frame_eop   = 0;


/**********************
  EIGHTH BEAT
**********************/

//wait until ready is 1
@(posedge clk);
while(noc_ready_reg == 0)
begin
    @(posedge clk);
end

$display("Sending last nocunit");

frame_valid = 1;
frame_data  = 8;
frame_write = 1;
frame_read  = 0;
port_id     = 3;
frame_count = 3;
for(i = 0; i < FRAME_ID_WIDTH-3; i++)
    frame_count_rev[FRAME_ID_WIDTH-4-i] = frame_count[i];         
frame_sop   = 0;
frame_eop   = 1;

/**********************
  READ NOW
**********************/

//wait until ready is 1
@(posedge clk);
while(noc_ready_reg == 0)
begin
    @(posedge clk);
end

$display("Sending read request");

frame_valid = 1;
frame_data  = {4'd9,{(AVL_DATA_WIDTH-4){1'b0}}};
frame_write = 0;
frame_read = 1;
port_id     = 3;
frame_count = 3;
for(i = 0; i < FRAME_ID_WIDTH-3; i++)
    frame_count_rev[FRAME_ID_WIDTH-4-i] = frame_count[i];         
frame_sop   = 1;
frame_eop   = 1;

/**********************
  READ AGAIN
**********************/

//wait until ready is 1
@(posedge clk);
while(noc_ready_reg == 0)
begin
    @(posedge clk);
end

$display("Sending read request");

frame_valid = 1;
frame_data  = {4'd10,{(AVL_DATA_WIDTH-4){1'b0}}};
frame_write = 0;
frame_read = 1;
port_id     = 3;
frame_count = 3;
for(i = 0; i < FRAME_ID_WIDTH-3; i++)
    frame_count_rev[FRAME_ID_WIDTH-4-i] = frame_count[i];         
frame_sop   = 1;
frame_eop   = 1;

//wait until ready is 1
@(posedge clk);
while(noc_ready_reg == 0)
begin
    @(posedge clk);
end

//stop
frame_valid = 0;
frame_data  = 0;
frame_write = 0;
frame_read  = 0;
port_id     = 0;
frame_count = 0;
for(i = 0; i < FRAME_ID_WIDTH-3; i++)
    frame_count_rev[FRAME_ID_WIDTH-4-i] = frame_count[i];         
frame_sop   = 0;
frame_eop   = 0;

for(i=0;i<100;i=i+1)
    @(posedge clk);

//$stop();

end
///////////////////////////////////////////////////////////////////////

always @(posedge clk)
    noc_ready_reg <= noc_ready_out;

//-----------------------------------------------------
// Set NOC DATA 
//-----------------------------------------------------

assign frame_id      = {port_id,frame_count_rev};
assign noc_data_in   = {frame_write,frame_read,frame_id,frame_data};
assign noc_valid_in  = {frame_valid,frame_valid,frame_valid,frame_valid};
assign noc_sop_in    = {1'b0,1'b0,1'b0,frame_sop};
assign noc_eop_in    = {frame_eop,1'b0,1'b0,1'b0};


endmodule
