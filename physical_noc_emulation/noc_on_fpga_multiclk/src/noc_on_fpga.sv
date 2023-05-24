/* 
 * function : general top-level file for noc physical interconnection
 * author   : Mohamed S. Abdelfattah
 * date     : 04-Jun-2015
 */

module noc_on_fpga
#( 
    parameter NOC_WIDTH = 600, // can support up to 800 
    parameter NOC_NODES = 16
)
(
	input [NOC_NODES-1:0] clk, //sys clks
	input rst, //active-low async reset
	
	input  [NOC_WIDTH-1:0] v_inputs [0:NOC_NODES-1],
	output [NOC_WIDTH-1:0] v_outputs [0:NOC_NODES-1]
);


reg [NOC_WIDTH-1:0] inputs [0:NOC_NODES-1] /* synthesis noprune  */;
reg [NOC_WIDTH-1:0] outputs [0:NOC_NODES-1] /* synthesis noprune  */;

//The NoC!
generate
    genvar i;
    for(i=0;i<NOC_NODES;i=i+1)
    begin:node
    router
    #(
        .WIDTH(NOC_WIDTH)
    )
    router_inst
    (
        .clk(clk[i]),
        .inputs(inputs[i]),
        .outputs(outputs[i])
    );
	 
	always @ (posedge clk[i])
	begin
		v_outputs[i] = outputs[i];
		inputs[i] = v_inputs[i];
	end
	
	end
	 
endgenerate


endmodule
