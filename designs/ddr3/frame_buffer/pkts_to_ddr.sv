/*
 * function : take packets with ethernet frames from NoC and output write
 *            requests to DDR3 on an avalon bus
 * author   : Mohamed S. Abdelfattah
 * date     : 13-MAR-2015
 */

module pkts_to_ddr
#(
    // AVL SIDE ////////////
    parameter AVL_ADDR_WIDTH = 29,
    parameter AVL_DATA_WIDTH = 512,
    parameter AVL_BYTE_EN_WIDTH = AVL_DATA_WIDTH/8,
    parameter FRAME_ID_WIDTH = 4+28, //4 bits for each port, and 28 bits for each frame 2^28 ~ 268,000,000
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
	input  wire [WIDTH_PKT-1:0] noc_data_in,
	input  wire           [3:0] noc_valid_in,
	output wire                 noc_ready_out,
    input  wire           [3:0] noc_sop_in,
    input  wire           [3:0] noc_eop_in,

    // DDR3 AVL SIDE ///////////////////////
    
    //slave
    output wire    [AVL_DATA_WIDTH-1:0] avl_writedata,
    output wire    [AVL_ADDR_WIDTH-1:0] avl_address,
    output wire                         avl_write,
    output wire                         avl_read,
    input  wire    [AVL_DATA_WIDTH-1:0] avl_readdata,
    output wire [AVL_BYTE_EN_WIDTH-1:0] avl_byteenable,
    input  wire                         avl_readdatavalid,

    input  wire                         avl_waitrequest
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
wire                      frame_valid;
wire [AVL_DATA_WIDTH-1:0] frame_data;
wire                      frame_write;
wire                      frame_read;
wire [FRAME_ID_WIDTH-1:0] frame_id;
wire                      frame_sop;
wire                      frame_eop;

wire [AVL_ADDR_WIDTH-1:0] frame_addr;


//-----------------------------------------------------
// Ready/waitreq buffer
//-----------------------------------------------------

//need to store data somewhere when a waitrequest comes through
//because the NoC and the avalon interface treat ready signal timing
//differently

//registered versions of noc output
reg [WIDTH_PKT-1:0] noc_data_reg;
reg           [3:0] noc_valid_reg;
reg           [3:0] noc_sop_reg;
reg           [3:0] noc_eop_reg;
reg                 waitrequest_reg;
reg                 waitrequest_delay_reg;

reg waitreq;
reg reading;

always @(posedge clk)
begin
    if(rst)
    begin
        noc_data_reg  = 0;
        noc_valid_reg = 0;
        noc_sop_reg   = 0;
        noc_eop_reg   = 0;
        waitrequest_reg <= 0;
        waitrequest_delay_reg <= 0;
    end
    else
    begin
        if(waitrequest_delay_reg == 0 || reading)
        begin
            noc_data_reg  = noc_data_in;
            noc_valid_reg = noc_valid_in;
            noc_sop_reg   = noc_sop_in;
            noc_eop_reg   = noc_eop_in;
        end
        waitrequest_reg       <= waitreq;
        waitrequest_delay_reg <= waitrequest_reg;
    end
end

//which data do we choose? registered or not?
reg [WIDTH_PKT-1:0] noc_data;
reg           [3:0] noc_valid;
reg           [3:0] noc_sop;
reg           [3:0] noc_eop;

//do we need to delay waitrequest?
//assign waitrequest_reg = avl_waitrequest;

//mux to choose registered data when waitrequest asserted
assign noc_data  = waitrequest_delay_reg == 1 ? noc_data_reg  : noc_data_in;
assign noc_valid = waitrequest_delay_reg == 1 ? noc_valid_reg : noc_valid_in;
assign noc_sop   = waitrequest_delay_reg == 1 ? noc_sop_reg   : noc_sop_in;
assign noc_eop   = waitrequest_delay_reg == 1 ? noc_eop_reg   : noc_eop_in;


//-----------------------------------------------------
// NOC DATA EXTRACTION
//-----------------------------------------------------

assign frame_valid = noc_valid[3]; //if first flit is valid, assume whole word is valid
assign frame_data  = noc_data[DATA_POS  -: AVL_DATA_WIDTH];
assign frame_write = noc_data[WRITE_POS -: 1] & frame_valid;
assign frame_read  = noc_data[READ_POS  -: 1] & frame_valid;
assign frame_id    = noc_data[ID_POS    -: FRAME_ID_WIDTH];
assign frame_sop   = noc_sop[3] & frame_valid;// can only be most significant bit
assign frame_eop   = |noc_eop & frame_valid;  // our data ends if any eop is set


//-----------------------------------------------------
// READ logic
//-----------------------------------------------------

reg stall_input;
reg [FRAME_OFFSET_WIDTH-1:0] frame_offset;


always @(posedge clk)
begin
    if(rst)
    begin
        reading = 0;
    end
    else
    begin
        if(!reading & frame_read)
        begin
            reading = 1;
        end
        else if(reading && (frame_offset == 7) ) //hardcoded to reading a 512 byte packet
        begin
            reading = 0;
        end
    end
end

//-----------------------------------------------------
// ADDRESS GENERATION
//-----------------------------------------------------

localparam ADDR_PADDING = AVL_ADDR_WIDTH - BIN_ADDR_WIDTH - FRAME_OFFSET_WIDTH;

//need counter that starts at 1 with sop
//and increments whenever we have another nuint

always @(posedge clk)
begin
    if(rst)
        frame_offset = 0;
    else if(frame_valid)
    begin
        //go back to zero at an eop or an end of a read
        if( (frame_write & frame_eop) | (frame_offset == 8) )
            frame_offset = 0;
        //otherwise keep incrementing the offset
        else if(avl_waitrequest==0)
            frame_offset = frame_offset + 1;
    end
end


//frame address depends on the most-significant BIN_ADDR_WIDTH of frame_id
assign frame_addr  = {{ADDR_PADDING{1'b0}}, frame_id[FRAME_ID_WIDTH-1 -: BIN_ADDR_WIDTH], frame_offset};


//-----------------------------------------------------
// AVL signals
//-----------------------------------------------------

assign avl_writedata  = frame_data;
assign avl_address    = frame_addr;
assign avl_write      = frame_write;
assign avl_read       = frame_read;
assign avl_byteenable = {AVL_BYTE_EN_WIDTH{1'b1}}; //write all bytes for now


//-----------------------------------------------------
// Backpressure 
//-----------------------------------------------------


assign waitreq = avl_waitrequest | reading;
assign stall_input = (~waitreq) & (~reading); 
assign noc_ready_out = stall_input;

endmodule
