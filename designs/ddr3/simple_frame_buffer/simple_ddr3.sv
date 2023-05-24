/*
 * function : much-simplified ddr3 memory model
 * author   : Mohamed S. Abdelfattah
 * date     : 1-APR-2015
 */

module simple_ddr3 #(
    parameter DATA_WIDTH = 512,
    parameter ADDR_WIDTH = 29,
    parameter RAM_DEPTH = 1 << ADDR_WIDTH,
    parameter BYTE_EN_WIDTH = DATA_WIDTH/8
)
(
    input  wire                     clk,                
    input  wire                     rst,            
    output wire                     waitrequest,            
    input  wire    [ADDR_WIDTH-1:0] address,                
    input  wire               [2:0] burstcount,            
    input  wire    [DATA_WIDTH-1:0] writedata,             
    output wire    [DATA_WIDTH-1:0] readdata,              
    input  wire                     write,                  
    input  wire                     read,                   
    output wire                     readdatavalid,          
    input  wire [BYTE_EN_WIDTH-1:0] byteenable //not used yet
); 


//--------------Internal variables---------------- 
reg [DATA_WIDTH-1:0] readdata_reg;
//reg [DATA_WIDTH-1:0] mem [0:RAM_DEPTH-1];
reg [DATA_WIDTH-1:0] mem [reg [ADDR_WIDTH-1:0]];
reg                  readdatavalid_reg;

//--------------Code Starts Here------------------ 

//readdata
assign readdata = readdata_reg; 
assign readdatavalid = readdatavalid_reg; 

//ideal case: no waitrequests
assign waitrequest = 0;

// Memory Write Block 
always @ (posedge clk)
begin : MEM_WRITE
   if ( write ) begin
       mem[address] = writedata;
   end
end

// Memory Read Block 
always @ (posedge clk)
begin : MEM_READ
  if ( read ) begin
    readdata_reg = mem[address];
    readdatavalid_reg = 1;
  end else begin
    readdatavalid_reg = 0;
  end
end

endmodule
