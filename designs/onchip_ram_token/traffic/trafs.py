
for i in range(15):
    traf = open("node_"+str(i)+".txt",'w');
    
    for j in range(1000):
        print>>traf, "1"

    traf.close();

