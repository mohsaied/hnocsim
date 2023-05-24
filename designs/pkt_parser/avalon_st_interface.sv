interface avalonST #(parameter WIDTH = 512);
   
   logic 		     valid, sop, eop, error;
   logic [$clog2(WIDTH/8)-1:0] empty;
   logic [WIDTH-1:0] 	     data;
   logic 		     ready;

   modport src (output valid,
		output sop,
		output eop,
		output error,
		output empty,
		output data,
		input  ready);

   modport sink (input  valid,
		 input 	sop,
		 input 	eop,
		 input 	error,
		 input 	empty,
		 input 	data,
		 output ready);
   
endinterface
