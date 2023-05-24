/*
 * function : testbench for encoder and decoder
 * author   : Mohamed S. Abdelfattah
 * date     : 08-MAR-2015
 */


module tb_enc_dec();
   
// num_ports = decoded with
parameter num_ports = 8;
parameter width = $clog2(num_ports);

wire [num_ports-1:0] input_data;
wire     [width-1:0] between_data;
wire [num_ports-1:0] output_data;


encoder #(
    .num_ports(num_ports)
) enc_inst (
    .data_in(input_data),
    .data_out(between_data)
);

decoder #(
    .num_ports(num_ports)
) dec_inst (
    .data_in(between_data),
    .data_out(output_data)
);

reg [num_ports-1:0] test_data;
assign input_data = test_data;

integer i;
integer errors;

initial begin
    
    errors = 0;
    
    for(i = 0; i < 256; i=i+1) begin
        test_data = i;
        #100;
        if(   (input_data == 0                       && output_data != 8'bxxxxxxxx)
            ||(input_data == 1                       && output_data != 8'b00000001)
            ||(input_data >= 2   && input_data < 4   && output_data != 8'b00000011)
            ||(input_data >= 4   && input_data < 8   && output_data != 8'b00000111)
            ||(input_data >= 8   && input_data < 16  && output_data != 8'b00001111)
            ||(input_data >= 16  && input_data < 32  && output_data != 8'b00011111)
            ||(input_data >= 32  && input_data < 64  && output_data != 8'b00111111)
            ||(input_data >= 64  && input_data < 128 && output_data != 8'b01111111)
            ||(input_data >= 128 && input_data < 256 && output_data != 8'b11111111))
        begin
            $display("ERROR! %d, %d",input_data,output_data);
            errors = errors + 1;
        end
    end
    
    $display("number of errors = %d",errors);
    
    $finish(0);

end
   
endmodule