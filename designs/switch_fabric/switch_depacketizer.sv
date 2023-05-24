module switch_depacketizer #
  (
   parameter DATA_WIDTH = 64,
   parameter ADDRESS_WIDTH = 4,
   parameter VC_ADDRESS_WIDTH = 1,
   parameter WIDTH_OUT = 142,
   parameter WIDTH_IN = 600
   )
   (
    input 			 clk,
    input 			 reset,
    
    input [WIDTH_IN-1:0] 	 i_data_in,
    input 			 i_valid_in,
    output 			 i_ready_out,
   
    output logic [WIDTH_OUT-1:0] o_data_out,
    output logic 		 o_valid_out,
    input 			 o_ready_in
    );

   logic 		   rdack [0:3];
   logic 		   wrreq [0:3];
   wire 		   empty [0:3];
   wire 		   full [0:3];
   wire 		   alm_full [0:3];
   wire [WIDTH_IN/4-1:0]   data[0:3];
   

   genvar 		   j;

   //logic 		   sop_in_flag_r, sop_in_flag_next;
   //logic skid_wr_r [0:3];
   //logic skid_wr_next [0:3];
   
   generate
      for (j=0;j<4;j++) begin:A
	 fifo_shallow_almf fifo (.clock(clk),
				 .sclr(reset),
				 .data(i_data_in[ ( (4-j) * (WIDTH_IN/4) ) - 1 -: WIDTH_IN/4]),
				 .rdreq(rdack[j]), // read acknowledge
				 .wrreq(wrreq[j]),
				 .empty(empty[j]),
				 .full(full[j]),
				 .almost_full(alm_full[j]),
				 .q(data[j]));

//	 always_ff @(posedge clk or posedge reset) skid_wr_r[j] <= (reset) ? skid_wr_next[j] : 1'b0;
      end
   endgenerate

   assign i_ready_out = o_ready_in && !alm_full[0] && !alm_full[1] && !alm_full[2] && !alm_full[3];
   //assign o_valid_out = i_valid_in;
   
   int unsigned i;

   //always_ff @(posedge clk or posedge reset) sop_in_flag_r <= (reset) ? 1'b0 : sop_in_flag_next;

     
   
   always_comb begin
          
      for (i=0; i<4; i++) begin
	 /*
	 wrreq[i] = 1'b0;
	 skid_wr_next[i] = skid_wr_r[i];
	 	 
	 if (i_valid_in && i_data_in[(4-i)*(WIDTH_IN/4)-1] && !full[i]) begin
	    
	    if (i_ready_out)
	      wrreq[i] = 1'b1;
	    else
	      skid_wr_next[i] = 1'b1;
	    
	 end
	
	 if (skid_wr_r[i]) begin
	    wrreq[i] = 1'b1;
	    skid_wr_next[i] = 1'b0;
	 end
	 */
	 wrreq[i] = (i_valid_in && i_data_in[(4-i)*(WIDTH_IN/4)-1] && !full[0] && !full[1] && !full[2] && !full[3]);

	 // debug
	 if (i_valid_in && full[i])
	   $error("ERROR: Valid data but full buffer (t=%d)",$time);
	 	 
      end // for (i=0; i<4; i++)
      
   end

   int 			  unsigned n;
   
   logic [1:0] 		  k;
   logic [2:0] 		  empty_cnt;
   logic [1:0] 		  rr_cnt_r, rr_cnt_next;
   logic 		  sop_flag_r, sop_flag_next;
   
   // temp virtual wires
   logic 		  head,tail;
   logic 		  eop0,eop1;
   logic [2:0] 		  empty0,empty1;
   logic 		  error0,error1;
   logic [DATA_WIDTH-1:0] data0,data1;
      
   always_ff @(posedge clk or posedge reset) rr_cnt_r <= (reset) ? 2'd0 : rr_cnt_next;
   always_ff @(posedge clk or posedge reset) sop_flag_r <= (reset) ? 1'b0 : sop_flag_next;
         
   always_comb begin
      // defaults
      for (n=0;n<4;n++) rdack[n] = 1'b0;
      o_data_out   = 'b0;
      o_valid_out  = 1'b0;
      rr_cnt_next  = rr_cnt_r;
      head 	   = 1'b0;
      tail 	   = 1'b0;
      eop0 	   = 1'b0;
      eop1 	   = 1'b0;
      empty0 	   = 'b0;
      empty1 	   = 'b0;
      error0 	   = 1'b0;
      error1 	   = 1'b0;
      data0 	   = 'b0;
      data1 	   = 'b0;

      sop_flag_next = sop_flag_r;
                              
      if (o_ready_in) begin
	 
	 k = rr_cnt_r;
	 empty_cnt = 0;
	 
	 while (empty_cnt != 3'd4) begin
	    
	    if (!empty[k]) begin
	    
	       o_valid_out 	= 1'b1;

	       head = data[k][WIDTH_IN/4-2];
	       tail = data[k][WIDTH_IN/4-3];
	       eop0 = data[k][WIDTH_IN/4-9];
	       empty0 = data[k][WIDTH_IN/4-10 -: 3];
	       error0 = data[k][WIDTH_IN/4-13];
	       data0 = data[k][WIDTH_IN/4-14 -: DATA_WIDTH];
	       eop1 = data[k][WIDTH_IN/4-14-DATA_WIDTH];
	       empty1 = data[k][WIDTH_IN/4-14-DATA_WIDTH-1 -: 3];
	       error1 = data[k][WIDTH_IN/4-14-DATA_WIDTH-4];
	       data1 = data[k][WIDTH_IN/4-14-DATA_WIDTH-5 -: DATA_WIDTH];
	       
	       o_data_out = {1'b1,head,eop0,empty0,error0,data0,
			     !eop0,1'b0,eop1,empty1,error1,data1};
	       	       
	       rdack[k] 	= 1'b1;

	       if (eop0 || eop1)
		 rr_cnt_next = 2'd0; // sop always arrives at top of demux
	       else
		 rr_cnt_next      = k+1;

	       // Debug
	       if (head && (eop0 || eop1))
		 sop_flag_next = 1'b0;
	       else if (head) begin
		 if (sop_flag_r)
		   $error("ERROR: Depacketizer sending SOP, expecting EOP. (t=%d)",$time);
		 else
		   sop_flag_next = 1'b1;
	       end
	       else if (eop0 || eop1) begin
		  if (sop_flag_r)
		    sop_flag_next = 1'b0;
		  else
		    $error("ERROR: Depacketizer sending EOP, expecting SOP. (t=%d)",$time);
	       end
	       else begin
		  if (!sop_flag_r)
		    $error("ERROR: Depacketizer sending data, expecting SOP. (t=%d)",$time);
	       end

	       break;	  
	       	             
	    end // if (!empty[k])
	    else empty_cnt++;
	    
	    k++;
	    	    	    	    
	 end
	 
      end
	 
   end

endmodule
