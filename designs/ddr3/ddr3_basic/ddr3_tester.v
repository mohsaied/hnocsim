/*
 * function : traffic generator and checker for DDR3
 * author   : Mohamed S. Abdelfattah
 * date     : 3-MAR-2015
 */


`timescale 1 ps / 1 ps

module ddr3_tester (
    input clk,
    input rst,
    output wire   [2:0] burstcount,
    input  wire         waitrequest,
    output wire [511:0] writedata,
    output wire  [28:0] address,
    output wire         write,
    output wire         read,
    input  wire [511:0] readdata,
    output wire  [63:0] byteenable,
    input  wire         readdatavalid
);


reg [511:0] data;
reg [2:0] burstcount_reg;
assign burstcount = burstcount_reg;
reg [511:0] writedata_reg;
assign writedata = writedata_reg;
reg [28:0] address_reg;
assign address = address_reg;
reg write_reg;
assign write = write_reg;
reg read_reg;
assign read = read_reg;
reg [63:0] byteenable_reg;
assign byteenable = byteenable_reg;
   
integer i;

initial begin

data = 0;

while(data < 100)
begin

    burstcount_reg = 3'd1;
    writedata_reg = data;
    address_reg = data[28:0];
    write_reg = 1'b1;
    read_reg = 1'b0;
    byteenable_reg = 64'hffffffffffffffff;

    @ (posedge clk)

    if(waitrequest == 1'b0)
    begin
        data = data + 1;
    end //if

end //while

write_reg = 0;

for(i = 0; i < 200; i=i+1)
    @ (posedge clk)

$finish(0);

end //initial



endmodule
