/*
 * function : take packets with ethernet frames from NoC and output write
 *            requests to DDR3 on an avalon bus
 * author   : Mohamed S. Abdelfattah
 * date     : 13-MAR-2015
 */

module frame_buffer
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
    parameter NOC_ADDR_WIDTH = 4,
	parameter WIDTH_PKT = AVL_DATA_WIDTH+1+1+FRAME_ID_WIDTH //this is the data width after the translator strips away the flit headers
)
(
    input clk,
    input rst,

    // NOC SIDE ////////////////////////////
    //packets coming out of NoC (fp output)
	input  wire [WIDTH_PKT-1:0] noc_data_in,
	input  wire           [3:0] noc_valid_in,
	output wire                 noc_ready_out,
    input  wire           [3:0] noc_sop_in,
    input  wire           [3:0] noc_eop_in,
    //packets going back into NoC (fp input)
	output wire      [WIDTH_PKT-1:0] noc_data_out,
	output wire                [3:0] noc_valid_out,
	input  wire                      noc_ready_in,
    output wire                [3:0] noc_sop_out,
    output wire                [3:0] noc_eop_out,
    output wire [NOC_ADDR_WIDTH-1:0] noc_dest_out,

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

//frame offset reg
localparam ADDR_PADDING = AVL_ADDR_WIDTH - BIN_ADDR_WIDTH - FRAME_OFFSET_WIDTH;
reg [FRAME_OFFSET_WIDTH-1:0] frame_offset;

//noc ready reg
reg noc_ready_out_reg;

// signals to get data from NoC
wire                      frame_valid_in;
wire [AVL_DATA_WIDTH-1:0] frame_data_in;
wire                      frame_write_in;
wire                      frame_read_in;
wire [FRAME_ID_WIDTH-1:0] frame_id_in;
wire                      frame_sop_in;
wire                      frame_eop_in;
wire [NOC_ADDR_WIDTH-1:0] frame_dest_in;

//signals going into DDR3
reg    [AVL_DATA_WIDTH-1:0] avl_writedata_reg;
reg    [AVL_DATA_WIDTH-1:0] avl_writedata_bak;
reg    [AVL_DATA_WIDTH-1:0] avl_writedata_frt;
reg    [AVL_ADDR_WIDTH-1:0] avl_address_reg;
reg                         avl_write_reg;
reg                         avl_read_reg;
reg [AVL_BYTE_EN_WIDTH-1:0] avl_byteenable_reg;

localparam FIFO_WIDTH = 1 + 1 + AVL_DATA_WIDTH + FRAME_ID_WIDTH + NOC_ADDR_WIDTH;//store the frame id with the data and sop/eop
localparam FIFO_DEPTH = 16;

//fifo wires
wire [FIFO_WIDTH-1 : 0] fifo_data_in;
wire                    fifo_write_en;
wire                    fifo_full;

wire [FIFO_WIDTH-1 : 0] fifo_data_out;
wire                    fifo_read_en;
wire                    fifo_empty;

reg sop_fifo;
reg eop_fifo;
reg [FRAME_ID_WIDTH-1 : 0] frame_id_fifo;

//signal that goes high for one cycle at the start of a new read request
reg read_start;

reg noc_ready_in_reg;
reg noc_ready_in_delay;
reg fifo_empty_delay;

always @(posedge clk)
begin
    noc_ready_in_reg <= noc_ready_in;
    noc_ready_in_delay <= noc_ready_in_reg;
    fifo_empty_delay <= fifo_empty;
end

reg [NOC_ADDR_WIDTH-1:0] dest_fifo;

reg [FRAME_ID_WIDTH-1:0] frame_id_reg;
reg [NOC_ADDR_WIDTH-1:0] frame_dest_reg;

//-----------------------------------------------------
// NOC DATA EXTRACTION
//-----------------------------------------------------

assign frame_valid_in = noc_valid_in[3]; //if first flit is valid, assume whole word is valid
assign frame_data_in  = noc_data_in[DATA_POS  -: AVL_DATA_WIDTH];
assign frame_write_in = noc_data_in[WRITE_POS -: 1] & frame_valid_in;
assign frame_read_in  = noc_data_in[READ_POS  -: 1] & frame_valid_in;
assign frame_id_in    = noc_data_in[ID_POS    -: FRAME_ID_WIDTH];
assign frame_sop_in   = noc_sop_in[3] & frame_valid_in;// can only be most significant bit
assign frame_eop_in   = |noc_eop_in & frame_valid_in;  // our data ends if any eop is set
assign frame_dest_in  = noc_data_in[DATA_POS  -: NOC_ADDR_WIDTH];

//-----------------------------------------------------
// NOC READ SIDE
//-----------------------------------------------------

localparam FIFO_SOP_POS  = FIFO_WIDTH - 1;
localparam FIFO_EOP_POS  = FIFO_SOP_POS - 1;
localparam FIFO_FID_POS  = FIFO_EOP_POS - 1;
localparam FIFO_DATA_POS = FIFO_FID_POS - FRAME_ID_WIDTH;
localparam FIFO_DEST_POS = FIFO_DATA_POS - AVL_DATA_WIDTH;

//get the data from the fifo and put in the NoC

assign noc_data_out  = {1'b1,fifo_data_out[FIFO_FID_POS -: (FRAME_ID_WIDTH + AVL_DATA_WIDTH)]};
assign noc_valid_out = {!fifo_empty_delay & noc_ready_in_delay, !fifo_empty_delay & noc_ready_in_delay, !fifo_empty_delay & noc_ready_in_delay, !fifo_empty_delay & noc_ready_in_delay}; //whenever we are ready and fifo !empty
assign noc_sop_out   = {fifo_data_out[FIFO_SOP_POS],1'b0,1'b0,1'b0};
assign noc_eop_out   = {1'b0,1'b0,1'b0,fifo_data_out[FIFO_EOP_POS]};

assign noc_dest_out  = fifo_data_out[FIFO_DEST_POS -: NOC_ADDR_WIDTH];

//-----------------------------------------------------
// FIFO between DDR3 readdata and NoC data in
//-----------------------------------------------------

scfifo_moh #(
    .WIDTH(FIFO_WIDTH), 
    .DEPTH(FIFO_DEPTH)
) scfifo_inst (
    .clk(clk),
    .rst(rst),
   
    .i_data_in(fifo_data_in),
    .i_write_en(fifo_write_en),
    .i_full_out(fifo_full), //we should never be full because we can't backpressure ddr3
    
    .o_data_out(fifo_data_out),
    .o_read_en(fifo_read_en),
    .o_empty_out(fifo_empty)
);

assign fifo_data_in  = {sop_fifo, eop_fifo, frame_id_fifo, avl_readdata, dest_fifo};
assign fifo_write_en = avl_readdatavalid;
assign fifo_read_en  = ~fifo_empty & noc_ready_in;

//-----------------------------------------------------
// SM to set the Control Info going in FIFO
//-----------------------------------------------------

reg [2:0] rcnt_state;
parameter RCNT_WAIT = 3'b000,
          RCNT_PRG  = 3'b001;

//counter to count the number of reads
reg [3:0] rcnt_count;

reg wait_for_read;

always @(posedge clk)
begin
    
    if(rst)
    begin
        rcnt_state   = RCNT_WAIT;
        rcnt_count   = 0;
        sop_fifo     = 0;
        eop_fifo     = 0;
        wait_for_read = 0;
    end

    else
    begin
       
        case(rcnt_state)
        
            RCNT_WAIT: begin
                sop_fifo = 0;
                eop_fifo = 0;
                rcnt_count = 0;
                
                wait_for_read = 0;
                
                //we just started a new read operation
                if(read_start)
                begin
                    //set the sop to 1
                    sop_fifo = 1;

                    //change state to read-in-progress
                    rcnt_state = RCNT_PRG;
                end
            end
            
            //go to this state when a read request started
            RCNT_PRG: begin
                
                wait_for_read = 1;

                //sop has been 1 so far, after the first readvalid, set to 0
                if(avl_readdatavalid)
                begin
                    sop_fifo = 0;
                    eop_fifo = 0;
                    rcnt_count = rcnt_count + 1;

                    if(rcnt_count==4'd7)
                    begin
                        eop_fifo = 1;
                        rcnt_state = RCNT_WAIT;
                    end
                end
            end
        endcase
    end
end


//-----------------------------------------------------
// State Machine
//-----------------------------------------------------

reg [2:0] state;
parameter WAIT           = 3'b000,
		  READ           = 3'b001,//
		  READ_WAIT      = 3'b010,//
		  WRITE          = 3'b011,
		  WRITE_WAIT     = 3'b100,
          READ_END_WAIT  = 3'b101,//
          READ_WAIT_FIFO = 3'b110;//


always @(posedge clk)
begin
    
    if(rst)
    begin
        state = WAIT;
        avl_writedata_reg  = 0;
        avl_address_reg    = 0;
        avl_write_reg      = 0;
        avl_read_reg       = 0;
        frame_offset       = 0;
        noc_ready_out_reg  = 0;
        read_start         = 0;
        frame_id_fifo       = 0;
        dest_fifo          = 0;
    end
    else
    begin
        
        case (state)

            //nothing to process, waiting for packet
            WAIT: begin
                
                read_start = 0;
                // Outputs
                //--------
                
                avl_writedata_reg  = 0;
                avl_address_reg    = 0;
                avl_write_reg      = 0;
                avl_read_reg       = 0;
                frame_offset       = 0;
                if(avl_waitrequest | frame_read_in)
                    noc_ready_out_reg  = 0;
                else
                    noc_ready_out_reg  = 1;

                // State transition
                //-----------------
                if(frame_write_in)
                begin         
                    
                    if(frame_sop_in)
                        frame_offset = 0;
                    else
                        frame_offset = frame_offset + 1;

                    if(!avl_waitrequest)
                    begin
                        state = WRITE;
                        avl_writedata_reg = frame_data_in;
                        avl_address_reg   = {{ADDR_PADDING{1'b0}},frame_id_in[FRAME_ID_WIDTH-1 -: BIN_ADDR_WIDTH], frame_offset};
                        avl_write_reg     = 1;
                        avl_read_reg      = 0;
                        noc_ready_out_reg = 1;
                    end
                    else
                    begin
                        state = WRITE_WAIT;
                    end
                end

                else if(frame_read_in)
                begin
                    frame_offset = 0;
                    read_start = 0;
                    
                    if(!avl_waitrequest & fifo_empty & !wait_for_read)
                    begin
                        state = READ;
                        read_start = 1;
                        //store those now because we need to return them in our read resp
                        frame_id_fifo = frame_id_in;
                        dest_fifo = frame_dest_in;
                        avl_writedata_reg = 0;
                        avl_address_reg   = {{ADDR_PADDING{1'b0}},frame_id_fifo[FRAME_ID_WIDTH-1 -: BIN_ADDR_WIDTH], frame_offset};
                        avl_write_reg     = 0;
                        avl_read_reg      = 1;
                        noc_ready_out_reg = 0; //stall any more input until we finish this read request
                    end
                    else if(!fifo_empty | wait_for_read)
                    begin
                        state = READ_WAIT_FIFO;
                        avl_writedata_reg = 0;
                        avl_address_reg   = {{ADDR_PADDING{1'b0}},frame_id_fifo[FRAME_ID_WIDTH-1 -: BIN_ADDR_WIDTH], frame_offset};
                        avl_write_reg     = 0;
                        avl_read_reg      = 0; //dont ask for readdata
                        noc_ready_out_reg = 0; //stall input
                        frame_id_reg = frame_id_in;
                        frame_dest_reg = frame_dest_in;
                    end
                    else
                    begin
                        read_start = 1;
                        //store those now because we need to return them in our read resp
                        frame_id_fifo = frame_id_in;
                        dest_fifo = frame_dest_in;
                        state = READ_WAIT;
                        noc_ready_out_reg = 0; 
                    end
                end
                
            end //of wait state

            //at the begining of a new read request, we wait in this state if
            //the output fifo is not empty.
            READ_WAIT_FIFO:begin

                read_start = 0;

                if(fifo_empty & !wait_for_read)
                begin
                    read_start = 1;
                    //store those now because we need to return them in our read resp
                    frame_id_fifo = frame_id_reg;
                    dest_fifo = frame_dest_reg;
                    if(!avl_waitrequest)
                    begin
                        state = READ;
                        avl_read_reg = 1;
                    end
                    else
                    begin
                        state = READ_WAIT;
                    end
                end
            end

            //write packet arrives
            WRITE: begin
                    
                read_start = 0;
                 
                // Outputs
                //--------
                
                if(frame_sop_in)
                    frame_offset = 0;
                else
                    frame_offset = frame_offset + 1;

                avl_writedata_bak = avl_writedata_reg;
                avl_writedata_frt = frame_data_in;
                avl_writedata_reg = frame_data_in;
                avl_address_reg   = {{ADDR_PADDING{1'b0}},frame_id_in[FRAME_ID_WIDTH-1 -: BIN_ADDR_WIDTH], frame_offset};
                avl_write_reg     = 1;
                avl_read_reg      = 0;
                noc_ready_out_reg = 1;

                // State transition
                //-----------------

                if(frame_write_in)
                begin
                    if(avl_waitrequest)
                    begin
                        frame_offset = frame_offset - 1;
                        avl_writedata_reg = avl_writedata_bak;
                        avl_address_reg   = {{ADDR_PADDING{1'b0}},frame_id_in[FRAME_ID_WIDTH-1 -: BIN_ADDR_WIDTH], frame_offset};
                        state = WRITE_WAIT;
                        noc_ready_out_reg = 0;
                    end
                end
                
                else if(frame_read_in)
                begin
                    frame_offset = 0;
                    read_start = 0;
                    
                    if(!avl_waitrequest & fifo_empty & !wait_for_read)
                    begin
                        state = READ;
                        read_start = 1;
                        //store those now because we need to return them in our read resp
                        frame_id_fifo = frame_id_in;
                        dest_fifo = frame_dest_in;
                        avl_writedata_reg = 0;
                        avl_address_reg   = {{ADDR_PADDING{1'b0}},frame_id_fifo[FRAME_ID_WIDTH-1 -: BIN_ADDR_WIDTH], frame_offset};
                        avl_write_reg     = 0;
                        avl_read_reg      = 1;
                        noc_ready_out_reg = 0; //stall any more input until we finish this read request
                    end
                    else if(!fifo_empty | wait_for_read)
                    begin
                        state = READ_WAIT_FIFO;
                        avl_writedata_reg = 0;
                        avl_address_reg   = {{ADDR_PADDING{1'b0}},frame_id_fifo[FRAME_ID_WIDTH-1 -: BIN_ADDR_WIDTH], frame_offset};
                        avl_write_reg     = 0;
                        avl_read_reg      = 0; //dont ask for readdata
                        noc_ready_out_reg = 0; //stall input
                    end
                    else
                    begin
                        read_start = 1;
                        //store those now because we need to return them in our read resp
                        frame_id_fifo = frame_id_in;
                        dest_fifo = frame_dest_in;
                        state = READ_WAIT;
                        noc_ready_out_reg = 0; 
                    end
                end

                else
                begin
                    state = WAIT;
                    avl_read_reg = 0;
                    avl_write_reg = 0;
                end
      
            end //of WRITE state
            
            WRITE_WAIT: begin
                read_start = 0;
                if(!avl_waitrequest)
                begin
                    state = WRITE;
                    frame_offset = frame_offset + 1;
                    avl_address_reg   = {{ADDR_PADDING{1'b0}},frame_id_in[FRAME_ID_WIDTH-1 -: BIN_ADDR_WIDTH], frame_offset};
                    avl_writedata_reg = avl_writedata_frt;
                    noc_ready_out_reg = 1;
                end
            end

            //read packet arrives
            READ: begin
               
                read_start = 0;

                // Outputs
                //--------
                
                frame_offset = frame_offset + 1;

                avl_writedata_reg = 0;
                avl_address_reg   = {{ADDR_PADDING{1'b0}},frame_id_fifo[FRAME_ID_WIDTH-1 -: BIN_ADDR_WIDTH], frame_offset};
                avl_write_reg     = 0;
                avl_read_reg      = 1;
    
                if(frame_offset == 8) 
                begin
                    
                    avl_read_reg = 0;

                    frame_offset = 0;
                   
                    if(!avl_waitrequest & !wait_for_read)
                    begin
                        state = WAIT; //best to go back to wait state
                        noc_ready_out_reg = 1;
                    end
                    else
                    begin
                        state = READ_END_WAIT;
                    end
                end
                
                else if(avl_waitrequest)
                begin
                    state = READ_WAIT;
                    frame_offset = frame_offset - 1;
                    avl_address_reg = {{ADDR_PADDING{1'b0}},frame_id_fifo[FRAME_ID_WIDTH-1 -: BIN_ADDR_WIDTH], frame_offset};
                    noc_ready_out_reg = 0;
                end

            end //of READ state
            
            READ_WAIT: begin
                read_start = 0;
                if(!avl_waitrequest)
                begin
                    frame_offset = frame_offset + 1;
                    avl_address_reg = {{ADDR_PADDING{1'b0}},frame_id_fifo[FRAME_ID_WIDTH-1 -: BIN_ADDR_WIDTH], frame_offset};
                    state = READ;
                end
            end
            
            //this state is just for the corner case of getting a waitrequest
            //at the end of a read -- need to wait until waitrequest is
            //deasserted before moving forward
            READ_END_WAIT: begin
                read_start = 0;
                if(!avl_waitrequest)
                begin
                    state = WAIT;
                    noc_ready_out_reg = 1;
                end
            end

        endcase

    end
    
end //of state machine process


//-----------------------------------------------------
// AVL signals
//-----------------------------------------------------

assign avl_writedata  = avl_writedata_reg;
assign avl_address    = avl_address_reg;
assign avl_write      = avl_write_reg;
assign avl_read       = avl_read_reg;
assign avl_byteenable = {AVL_BYTE_EN_WIDTH{1'b1}}; //write all bytes for now


//-----------------------------------------------------
// Backpressure 
//-----------------------------------------------------

assign noc_ready_out = noc_ready_out_reg; 


endmodule
