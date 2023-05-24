/*
 * function : handle noc-to-avl timing
 * author   : Mohamed S. Abdelfattah
 * date     : 17-MAR-2015
 */

module avl_shim
#(
    // NOC SIDE ////////////
    parameter AVL_DATA_WIDTH = 512,
	parameter WIDTH_PKT = AVL_DATA_WIDTH+1+1+32 //this is the data width after the translator strips away the flit headers
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
    
    // Other SIDE /////////////////////////
	output wire [WIDTH_PKT-1:0] noc_data_out,
	output wire           [3:0] noc_valid_out,
	input  wire                 noc_ready_in,
    output wire           [3:0] noc_sop_out,
    output wire           [3:0] noc_eop_out
);

//-------------------------------------------------------------------------
// Implementation
//-------------------------------------------------------------------------


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
reg                 waitrequest_delay_reg;

always @(posedge clk)
begin
    if(rst)
    begin
        noc_data_reg  = 0;
        noc_valid_reg = 0;
        noc_sop_reg   = 0;
        noc_eop_reg   = 0;
        waitrequest_delay_reg <= 0;
    end
    else
    begin
        if(waitrequest_delay_reg == 0)
        begin
            noc_data_reg  = noc_data_in;
            noc_valid_reg = noc_valid_in;
            noc_sop_reg   = noc_sop_in;
            noc_eop_reg   = noc_eop_in;
        end
        waitrequest_delay_reg  <= ~noc_ready_in;
    end
end

//which data do we choose? registered or not?

//mux to choose registered data when waitrequest asserted
assign noc_data_out  = waitrequest_delay_reg == 1 ? noc_data_reg  : noc_data_in;
assign noc_valid_out = waitrequest_delay_reg == 1 ? noc_valid_reg : noc_valid_in;
assign noc_sop_out   = waitrequest_delay_reg == 1 ? noc_sop_reg   : noc_sop_in;
assign noc_eop_out   = waitrequest_delay_reg == 1 ? noc_eop_reg   : noc_eop_in;


//-----------------------------------------------------
// Backpressure 
//-----------------------------------------------------

assign noc_ready_out = noc_ready_in;

endmodule
