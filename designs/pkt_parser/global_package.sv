package global_package;

   // Module name -> connected NoC node
   typedef enum logic [5:0] {ipv4 = 6'd4,
			     ipv6 = 6'd5,
			     tcp = 6'd1,
			     udp = 6'd2
			     } mod_map_t;

   // To select a specific module at a router
   typedef enum logic [2:0] {ipv4_mod = 3'd0,
			     ipv6_mod = 3'd1
			     } mod_t;
   
   
endpackage
