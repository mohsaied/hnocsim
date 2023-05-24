

freq = 100 #MHz
one_cycle = 1000000/freq

#----------------------------------------------
# parse report and find latency and throughput
#----------------------------------------------

#list that will keep all requests
all_requests = dict()
req_id = 0;
read_req_id = 0;
write_req_id = 0;

#open files
rpt = open('output.txt','r')
    
#replace line with modified parameter
for line in rpt:
    if '>>SENDING' in line:
        part_list = line.split()
        
        #find node
        node = int(part_list[0])
        
        #find type
        req_type = 0
        if int(part_list[4]):
            req_type = 0; #read
        else:
            req_type = 1; #write

        #find send time 
        send_time = int(part_list[14])
        
        #reserve a spot for received time
        rec_time = -1
        
        if req_type:
            req_id = write_req_id
            write_req_id = write_req_id + 1
        else:
            req_id = read_req_id
            read_req_id = read_req_id + 1

        #list entry for this request
        req_list = [req_id,node,req_type,send_time,rec_time]
        
        #form hash key
        currkey = str(node)+'_'+str(req_type)+'_'+str(req_id)

        #insert into hash table with key in the format node_reqtype_req_id
        all_requests[currkey] = req_list;
        
        #print currkey, req_list

    elif '>>RECEIVED write' in line:
        #will need to look for the next request that doesnt have
        # a rec_time set in it for this node
        
        part_list = line.split();
        
        #find node
        node = int(part_list[0])
        
        #find time
        rec_time = int(part_list[15])

        #we already know type is 1 because this is a write
        #need to go over all keys that start with thisnode_1_*
        #and their rec_time is still -1
        #store all eligible keys in a list
        elig_keys = []
        for key in all_requests:
            if str(node)+'_1_' in key:
                elig_keys.append(key)
                #print "appending "+str(key)
        #print "done"

        #loop over elig keys and find lowest id with a -1 in rec_time
        min_id = 9999999
        correct_key = ""
        #print elig_keys
        for pos_key in elig_keys:
            if all_requests[pos_key][4] == -1:
                #find the id of this key
                key_list = pos_key.split('_')
                key_id = int(key_list[2])
                #print "key("+str(key_id)+")="+str(key)
                if key_id < min_id:
                    min_id = key_id;
                    correct_key = pos_key
            
        #retreive the list to edit then insert it again in the hash table
        list_to_edit = all_requests[correct_key]
        #insert rec time
        assert(list_to_edit[4] == -1)
        list_to_edit[4] = rec_time
        #re-enter into the table
        all_requests[correct_key] = list_to_edit
        
        #print correct_key, list_to_edit

    elif '>>RECEIVED read' in line:
        #will need to look for the next request that doesnt have
        # a rec_time set in it for this node
        
        part_list = line.split();
        
        #find node
        node = int(part_list[0])
        
        #find time
        rec_time = int(part_list[10])

        #we already know type is 1 because this is a write
        #need to go over all keys that start with thisnode_1_*
        #and their rec_time is still -1
        #store all eligible keys in a list
        elig_keys = []
        for key in all_requests:
            if str(node)+'_0_' in key:
                elig_keys.append(key)
        
        #loop over elig keys and find lowest id with a -1 in rec_time
        min_id = 9999999
        correct_key = ""
        for pos_key in elig_keys:
            if all_requests[pos_key][4] == -1:
                #find the id of this key
                key_list = pos_key.split('_')
                key_id = int(key_list[2])
                if key_id < min_id:
                    min_id = key_id;
                    correct_key = pos_key
            
        #retreive the list to edit then insert it again in the hash table
        list_to_edit = all_requests[correct_key]
        #insert rec time
        assert(list_to_edit[4] == -1)
        list_to_edit[4] = rec_time
        #re-enter into the table
        all_requests[correct_key] = list_to_edit

        #print correct_key, list_to_edit

#close file
rpt.close()
       

#init counters
read_counters  = [0] * 15
write_counters = [0] * 15

read_latency  = [0] * 15
write_latency = [0] * 15

#loop over all requests and find number of requests serviced for each node
for key in all_requests:
    
    #key format node_reqtype_req_id reqtype 0 is read and 1 is write
    #value format: req_list = [req_id,node,req_type,send_time,rec_time]
    
    curr_entry = all_requests[key]
    curr_node = curr_entry[1]
    curr_type = curr_entry[2]
    curr_sent = curr_entry[3]
    curr_recd = curr_entry[4]

    if curr_recd != -1:
        
        #compute the latency        
        curr_latency = (curr_entry[4] - curr_entry[3])/one_cycle
         
        #increment the proper counter
        if curr_type:
            write_counters[curr_node] = write_counters[curr_node] + 1
            write_latency[curr_node] = write_latency[curr_node] + curr_latency
        else:
            read_counters[curr_node] = read_counters[curr_node] + 1
            read_latency[curr_node] = read_latency[curr_node] + curr_latency


#average out the latency lists
for i in range(0,15):
    read_latency[i] = read_latency[i]/read_counters[i] if read_counters[i] != 0 else -1
    write_latency[i] = write_latency[i]/write_counters[i] if write_counters[i] != 0 else -1

#print some of these statistics
for i in range(0,15):
    print "node: "+str(i)+" reads: "+str(read_counters[i])+" latency: "+str(read_latency[i])+" writes: "+str(write_counters[i])+" latency: "+str(write_latency[i])

        
print ""

list_size = 100000
read_list = [None]*list_size
for i in range(list_size):
    read_list[i] = -1


write_list = [None]*list_size
for i in range(list_size):
    write_list[i] = -1



#loop over hash table
for key in all_requests:

    list_of_key = all_requests[key]
    if list_of_key[4] != -1:    
        #print "id: "+str(list_of_key[0])+" type: "+str(list_of_key[2])+" sent: "+str(list_of_key[3])+" received: "+str(list_of_key[4])+" approx_lat: "+str((list_of_key[4]-list_of_key[3])/one_cycle)
        if list_of_key[2]: #read
            write_list[list_of_key[0]] = (list_of_key[4]-list_of_key[3])/one_cycle
        else:
            read_list[list_of_key[0]] = (list_of_key[4]-list_of_key[3])/one_cycle


#parse things, write reports

num_ops = 10000

write_rpt = open('write_lat.txt','w')
read_rpt  = open('read_lat.txt','w')

#print "read list"
for i in range(num_ops):
    if(read_list[i] < 0):
        print "read cool down started at req "+str(i)+" : "+str(read_list[i])
        break;
    #print str(i)+" : "+str(read_list[i])
    print>>read_rpt, str(read_list[i])

#print "write list"
for i in range(num_ops):
    if(write_list[i] < 0):
        print "write cool down started at req "+str(i)+" : "+str(write_list[i])
        break;
    #print str(i)+" : "+str(write_list[i])
    print>>write_rpt, str(write_list[i])

write_rpt.close()
read_rpt.close()


#test_key = "1_0_0"
#test_result = all_requests[test_key]
#print test_key, test_result


#find average min and max read latency


read_avg = 0;
read_sum = 0;
read_num = 0;
read_min = 99999999;
read_max = -1;

for i in range(num_ops):
    if read_list[i] > 0:
        read_sum = read_sum + read_list[i]
        read_num = read_num + 1
        if read_list[i] < read_min:
            read_min = read_list[i]
        if read_list[i] > read_max:
            read_max = read_list[i]
    else:
        break


print "\nSummary over "+str(read_num)+" read operations"
print "min read latency = "+str(read_min)+" cycles"
print "max read latency = "+str(read_max)+" cycles"
print "avg read latency = "+str(float(read_sum/read_num))+" cycles"



write_avg = 0;
write_sum = 0;
write_num = 0;
write_min = 99999999;
write_max = -1;

for i in range(num_ops):
    if write_list[i] > 0:
        write_sum = write_sum + write_list[i]
        write_num = write_num + 1
        if write_list[i] < write_min:
            write_min = write_list[i]
        if write_list[i] > write_max:
            write_max = write_list[i]
    else:
        break


print "\nSummary over "+str(write_num)+" write operations"
print "min write latency = "+str(write_min)+" cycles"
print "max write latency = "+str(write_max)+" cycles"
print "avg write latency = "+str(float(write_sum/write_num))+" cycles"
print ""




