import os.path
import os
import time
import sys


orig_fname = 'testbench_simple_fabric.sv.orig'
mod_fname  = 'testbench_simple_fabric.sv'

#clk varies between 1.25 and 1
clks = [1,1.25]
#clks = [1,1.25]
#width varies between 16,160,260,400
#widths = [16,160,260,400]
widths = [400]
# number of inputs 1,10,100,1000,10000
ninputs = [1]
#destination
dests = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
#dests = [1]
#enable or disable stalls
stalls = True

#open report file
rpt = open('summary.txt','w')
print >>rpt, 'clk\tflits/pkt\tnum_inputs\tdest\tthroughput\ttot_num_cycles\tnum_output_cycles\tsuccess'
rpt.close()

for clk in clks:
	for width in widths:
		for ninput in ninputs:
			for dest in dests:
				
				rpt_fname = 'rpts/clk'+('fast' if clk==1 else 'slow')+'_width'+str(width)+'_ninputs'+str(ninput)+'_dest'+str(dest)+('_stalls' if stalls else '_nostalls')+'.txt'

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
						if 'config_clk' in line:
							line = 'always #'+str(clk)+' clk_noc = ~clk_noc;\n'
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
	
				#get relevant lines of report
				for line in curr_rpt:
					if 'failed out of' in line:
						success_line = line
					if 'Total number of cycles' in line:
						xput_line = line
		
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
				
				#write out to rpt
				
				rpt = open('summary.txt','a')
				print >>rpt, ('fast\t' if clk==1 else 'slow\t')+\
							 ('1\t' if width==16 else ('2\t' if width==160 else ('3\t' if width==260 else '4\t')))+\
							 str(ninput)+'\t'+\
							 str(dest)+'\t'+\
							 str(ninput/tot_num_cycles)+'\t'+\
							 str(int(tot_num_cycles))+'\t'+\
							 str(int(num_output_cycles))+'\t'+\
							 success
	
				rpt.close()
