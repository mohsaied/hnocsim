import os.path
import os
import time
import sys


orig_fname = 'testbench_simple_fabric.sv.orig'
mod_fname  = 'testbench_simple_fabric.sv'

#clk varies between 1.25 and 1
clk_nocs = [0.4165]
#clk_nocs = [1.25]
#clk_rtls = [5]
#clk_rtls = [10,5,2.5,2,1.5,1.25,1,0.75,0.7]
clk_rtls = [10,5,2.5,1.667,1.11,1,0.8333,0.714,0.67]
#clk_rtls = [5,2.5,1.65,1.25]
#clks = [1,1.25]
#width varies between 16,160,260,400
widths = [16,160,260,400]
#widths = [16]
# number of inputs 1,10,100,1000,10000
#ninputs = [1]
ninputs = [100]
#destination
#dests = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
#dests = [0,1,2,3,7,11,15]
dests = [1]
#enable or disable stalls
stalls = False

latency = 0

#open report file
rpt = open('summary.txt','w')
print >>rpt, 'clk_noc\tclk_rtl\tflits/pkt\tnum_inputs\tdest\tthroughput\tfpin\tnoc\tfpout\ttot_num_cycles\tnum_output_cycles\tsuccess'
rpt.close()

for clk_noc in clk_nocs:
	for clk_rtl in clk_rtls:
		clk_int = float(float(clk_rtl)/4);
		print "clk_int = "+str(clk_int);
		for width in widths:
			for ninput in ninputs:
				for dest in dests:
					
					rpt_fname = 'rpts/clk_noc'+str(clk_noc)+'clk_rtl'+str(clk_rtl)+'_width'+str(width)+'_ninputs'+str(ninput)+'_dest'+str(dest)+('_stalls' if stalls else '_nostalls')+'.txt'

					if os.path.exists(rpt_fname) == False:		
		
						#-------------------------
						# Modify top_level file
						#-------------------------
			
						#open files
						orig = open(orig_fname,'r')
						mod  = open(mod_fname,'w')
							
						#replace line with modified parameter
						for line in orig:
							if 'config_width' in line:
								line = 'parameter WIDTH_DATA = '+str(width)+';\n'
							if 'config_clk_noc' in line:
								line = 'always #'+str(clk_noc)+' clk_noc = ~clk_noc;\n'
							if 'config_clk_ints' in line:
								line = 'always #'+str(clk_int)+' clk_ints = ~clk_ints;\n'
							if 'config_clk_rtls' in line:
								line = 'always #'+str(clk_rtl)+' clk_rtls = ~clk_rtls;\n'
							if 'config_inputs' in line:
								line = 'localparam N_INPUTS = '+str(ninput)+';\n'
							if 'config_dest' in line:
								line = 'localparam DEST_NODE = '+str(dest)+';\n'
							if 'config_stall' in line:
								if stalls:
									line = '\tpkt_ready_in <= $urandom_range(0,1);\n'
								else:
									line = '\tpkt_ready_in <= 1;\n'
							mod.write(line)
						
						#close files
						orig.close()
						mod.close()
			
						#copy file to working directory
						os.system('cp -f '+mod_fname+' ../')
						
			
						#---------------------------
						# run the tool
						#---------------------------
						
						#change directory up one level
						os.chdir('../');
						
						#run script
						os.system('./quick_script > auto/'+rpt_fname)
			
						#change directory back
						os.chdir('auto')
		
		
					#---------------------------
					# parse the output
					#---------------------------
		
					#open report file
					curr_rpt = open(rpt_fname,'r')
					
					xput_line = ''
					success_line = ''
					fpin_line = ''
					nocin_line = ''
					nocout_line = ''
					fpout_line = ''

					#get relevant lines of report
					for line in curr_rpt:
						if 'failed out of' in line:
							success_line = line
						if 'Total number of cycles' in line:
							xput_line = line
						if 'fpin' in line:
							fpin_line = line;
						if 'fpout' in line:
							fpout_line = line;		
						if 'nocin' in line:
							nocin_line = line;				
						if 'nocout' in line:
							nocout_line = line;				
					
					#close report file
					curr_rpt.close()
					
					#-----------------------------------------
					# extract relevant data and write summary
					#-----------------------------------------
		
					#parse out success
					success_list = success_line.split()
					success = success_list[1]
		
					#parse out total number of cycles and number of output cycles
					xput_list = xput_line.split()
					tot_num_cycles = float(xput_list[6])
					num_output_cycles = float(xput_list[8].strip(')'))
					
					if latency:
						#parse out various component latencies
						nocin_list = nocin_line.split()
						nocin_f = float(nocin_list[1])

						nocout_list = nocout_line.split()
						nocout_f = float(nocout_list[1])

						fpin_list = fpin_line.split()
						fpin_f = float(fpin_list[1])

						fpout_list = fpout_line.split()
						fpout_f = float(fpout_list[1])

		
						fpin_lat = nocin_f - fpin_f
						noc_lat = nocout_f - nocin_f
						fpout_lat = fpout_f - nocout_f

					#write out to rpt
					rpt = open('summary.txt','a')
					print >>rpt, str(clk_noc)+'\t'+\
								 str(clk_rtl)+'\t'+\
								 ('1\t' if width==16 else ('2\t' if width==160 else ('3\t' if width==260 else '4\t')))+\
								 str(ninput)+'\t'+\
								 str(dest)+'\t'+\
								 str(ninput/(num_output_cycles+1))+'\t'+\
								 str(int(tot_num_cycles))+'\t'+\
								 str(int(num_output_cycles))+'\t'+\
								 success
				#	 str(int(fpin_lat))+'\t'+\
							#	 str(int(noc_lat))+'\t'+\
							#	 str(int(fpout_lat))+'\t'+\

					rpt.close()
