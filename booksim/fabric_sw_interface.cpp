#include <iostream>
#include <queue>
#include <vector>
#include <map>
#include "booksim_interface.cpp"

#include "dpi_fabric.h"

using namespace std;

//----------------------------------------------------------------------------------------
// STRUCTS and HELPER FUNCTION DEFs
//----------------------------------------------------------------------------------------

//flit information struct
struct FlitInfo {
    int pid;
    int fid;
    int source;
    int dest;
    int vc;
    int head;
    int tail;
};

void sendFabricCredit(int node, int vc);
void receiveFabricCredit(int node, int vc);

//----------------------------------------------------------------------------------------
// PARMETERS
//----------------------------------------------------------------------------------------

const int _NODES = 16;
const int _VCS   =  4;
const int _DEPTH = 16;

//----------------------------------------------------------------------------------------
// FABRICPORT DATA STRUCTURES 
//----------------------------------------------------------------------------------------

// FABRICPORT OUT
//--------------------

//afifo at the output fabricport
vector< vector< queue<int> > > ejectQueues;

//tdm demux registers -- 4 of them
vector< vector<int> > demux;
vector< vector<int> > demuxTemp0;
vector< vector<int> > demuxTemp1;
vector<int> demuxIndex;
vector< vector<int> > demuxSlots;

//ready signals from modules
vector< vector< int > > moduleReadys;

//number of credits that the fpout should send back to noc
vector< vector< int > > outstandingCredits;

//which VC are we reading from in CD = 0 mode
vector<int> vcAtOutput;
vector<int> previousVc;

// FABRICPORT IN
//--------------------

//afifo at the input fabricport
//one queue per vc per input port
vector< vector< queue< FlitInfo > > > injectQueues;

//credits at the input fabricports
vector< vector< int > > inputCredits;

// OTHER
//--------------------

//map of flit id and flitinfo struct
map<int,FlitInfo> flitMap;


int timex = 0;
int nsend[_NODES][_VCS];
int nrecv[_NODES][_VCS];
int ncred[_NODES][_VCS];

//----------------------------------------------------------------------------------------
// FUNCTIONS
//----------------------------------------------------------------------------------------


void connectFabricSocket(){
    connectSocket();

    //debug
    for(int i = 0; i < _NODES; i++){
        for(int j = 0; j < _NODES; j++){
            nsend[i][j] = 0;
            nrecv[i][j] = 0;
            ncred[i][j] = 0;
        }
    }



    //resize demuxes
    demuxIndex.resize(_NODES);
    for(int i = 0; i < _NODES; i++){
        demuxIndex[i] = 3;
    }
    

    //resize demuxslots
    //this tells us how many slots are available at each VC in a 2 VC system
    //with combine_data mode
    //TODO GENERALIZE THIS!
    demuxSlots.resize(_NODES);
    for(int i = 0; i < _NODES; i++){
        demuxSlots[i].resize(2);
        for(int j = 0; j < 2; j++){
            demuxSlots[i][j] = 0;
        }
    }
    
    //resize demuxTemp0
    demuxTemp0.resize(_NODES);
    for(int i = 0; i < _NODES; i++){
        demuxTemp0[i].resize(2);
        for(int j = 0; j < 2; j++){
            demuxTemp0[i][j] = -1;
        }
    }

    //resize demuxTemp1
    demuxTemp1.resize(_NODES);
    for(int i = 0; i < _NODES; i++){
        demuxTemp1[i].resize(2);
        for(int j = 0; j < 2; j++){
            demuxTemp1[i][j] = -1;
        }
    }
    
    //resize demux
    demux.resize(_NODES);
    for(int i = 0; i < _NODES; i++){
        demux[i].resize(4);
        for(int j = 0; j < 4; j++){
            demux[i][j] = -1;
        }
    }
    
    //resize ejectQueues
    ejectQueues.resize(_NODES);
    for(int i = 0; i < _NODES; i++){
        ejectQueues[i].resize(_VCS);
    }

    //resize injectQueues
    injectQueues.resize(_NODES);
    for(int i = 0; i < _NODES; i++){
        injectQueues[i].resize(_VCS);
    }

    //resize inputCredits and init
    inputCredits.resize(_NODES);
    for(int i = 0; i < _NODES; i++){
        inputCredits[i].resize(_VCS);
        for(int j = 0; j < _VCS; j++){
            inputCredits[i][j] = _DEPTH;
        }
    }

    //resize outstandingCredits and init
    outstandingCredits.resize(_NODES);
    for(int i = 0; i < _NODES; i++){
        outstandingCredits[i].resize(_VCS);
        for(int j = 0; j < _VCS; j++){
            outstandingCredits[i][j] = 0;
        }
    }

    //resize moduleReadys and init
    moduleReadys.resize(_NODES);
    for(int i = 0; i < _NODES; i++){
        moduleReadys[i].resize(_VCS);
        for(int j = 0; j < _VCS; j++){
            moduleReadys[i][j] = 0;
        }
    }

    //resize VC management arrays at output
    vcAtOutput.resize(_NODES);
    previousVc.resize(_NODES);
    for(int i = 0; i < _NODES; i++){
        vcAtOutput[i] = -1; //indicates "look for a VC"
        previousVc[i] = 0;  //start arbitration from VC0
    }
}

void exitFabricSocket(){
	exitSocket();
}

void queueFabricFlit(int pid, int fid, int source, int destination, int vc, int head, int tail){

    //store flit information
    FlitInfo newFlit = {pid, fid, source, destination, vc, head, tail};
    flitMap[fid] = newFlit;
    
    //insert it into its injectQueue
    injectQueues[source][vc].push(newFlit);
}

void insertFabricFlit(int node, int vc){
    //check that we have enough credits at this node and VC
    if(inputCredits[node][vc] > 0){
        //then fetch a flit if there are any queued
        if(!injectQueues[node][vc].empty()){
            nsend[node][vc]++;
            FlitInfo flit = injectQueues[node][vc].front();
            queueFlit(flit.pid, flit.fid, flit.source, flit.dest, flit.vc, flit.head, flit.tail);
            inputCredits[node][vc]--;
            injectQueues[node][vc].pop();
        }
    }
}

void queueFourFabricFlit(int pid1, int fid1, int source1, int destination1, int vc1, int head1, int tail1, int pid2, int fid2, int source2, int destination2, int vc2, int head2, int tail2, int pid3, int fid3, int source3, int destination3, int vc3, int head3, int tail3, int pid4, int fid4, int source4, int destination4, int vc4, int head4, int tail4){
    if(fid1!=-1)
        queueFabricFlit(pid1, fid1, source1, destination1, vc1, head1, tail1);
    if(fid2!=-1)
        queueFabricFlit(pid2, fid2, source2, destination2, vc2, head2, tail2);
    if(fid3!=-1)
        queueFabricFlit(pid3, fid3, source3, destination3, vc3, head3, tail3);
    if(fid4!=-1)
        queueFabricFlit(pid4, fid4, source4, destination4, vc4, head4, tail4);
}

void nextFabricCycle(int speedup){
    int rec_id = -2;
    int rec_vc = -1;

    for(int i = 0; i < 4; i++){
        rec_id = -2;
        rec_vc = -1;
        timex++;
        
        //cout << timex << endl;

        while(rec_id != -1){
            
            eject(&rec_id, &rec_vc);

            if(rec_id >= 0){
                int rec_node = flitMap[rec_id].dest;
                nrecv[rec_node][rec_vc]++;
                ejectQueues[rec_node][rec_vc].push(rec_id);    
                outstandingCredits[rec_node][rec_vc]++;
            }
        }
        
        //send back credits if module is ready
        for(int node = 0; node < _NODES; node++){
            for(int vc = 0; vc < _VCS; vc++){
                //if((moduleReadys[node][vc]==1 && outstandingCredits[node][vc]>0)){
                if((moduleReadys[node][vc]==1 && outstandingCredits[node][vc]>0) && ejectQueues[node][vc].size() < _DEPTH ){
                    ncred[node][vc]++;
                    sendFabricCredit(node,vc);
                    outstandingCredits[node][vc]--;
                }
            }
        }

        //send flits, receive credits (in that order)
        for(int node = 0; node < _NODES; node++){
            for(int vc = 0; vc < _VCS; vc++){
                //send flit
                insertFabricFlit(node,vc);
            }
        }

        inject();
 
        //send flits, receive credits (in that order)
        for(int node = 0; node < _NODES; node++){
            for(int vc = 0; vc < _VCS; vc++){
                //receive credit and increment counters
                receiveFabricCredit(node, vc);
            }
        }       

        nextCycle(speedup);

        /*
        for(int node = 0; node < _NODES; node++)
            for(int vc = 0; vc < _VCS; vc++)
                cout << "node,vc=(" << node << "," << vc << "): "  << nsend[node][vc] << " - " << nrecv[node][vc] << " - " << ncred[node][vc] << " - " << nsend[node][vc]-nrecv[node][vc] << endl;
        cout << "-----------" << endl;
        */
    }
}

int ejectFabric(int* id, int* vc){
    eject(id,vc);
}

void ejectFourFabric_cd(int node, int combine_data, int* id0, int* id1, int* id2, int* id3, int* valid){
  
    //first check if that module has any part that is ready to receive
    bool nodeIsReady = false;
    for(int i = 0; i < moduleReadys[node].size();i++)
        nodeIsReady |= moduleReadys[node][i];
    
    //cout << "node " << node << " ready=" << nodeIsReady << " cd="  << combine_data << endl;

    if(!nodeIsReady){
        //if we aren't ready we output zeroes and not valid
        *valid = 0;
        *id0 = -1;
        *id1 = -1;
        *id2 = -1;
        *id3 = -1;
    } else { // if we are ready we'll output things
       
        bool output = false;

        //default mode, no combining
        if(combine_data == 0){

            bool foundTail = false;

            //readout from ejectQueues
            //read from VC0 completely, then VC1 etc
            //cannot mix between VCs while on the same packet
            
            //first case: see if we already have something in demux[node] -- in
            //which case we'll just continue reading from the same VC until we
            //find a tail. Note that even if demux is empty, we have to make
            //sure that we finished reading a packet in the last round because
            //we can have long packets and multiple VCs
            
            //second case: we don't have anything in demux, implement
            //a round-robin arbiter to select the next non-empty VC
            
            int selectedVc = vcAtOutput[node];

            //this means look for a VC -- RR arbiter
            //otherwise, we'll take whichever previous value
            if(selectedVc == -1){
                //start with previous node
                selectedVc = previousVc[node];
                for(int i = 0; i < 4; i++){
                    //choose next available VC
                    selectedVc = (selectedVc + 1) % _VCS;
                    previousVc[node] = selectedVc;
                    if(!ejectQueues[node][selectedVc].empty()){
                        //we have found a VC that is ready to output
                        break;
                    }
                }
            }
            
            // take some flits from the selected VC
            for(int i = 0; i < 4; i++){
                if(!ejectQueues[node][selectedVc].empty() && demuxIndex[node]>=0 && !foundTail){
                    
                    int fid =  ejectQueues[node][selectedVc].front();

                    demux[node][demuxIndex[node]--] = fid;
                
                    foundTail = flitMap[fid].tail == 1;
                    
                    //cout << node <<  " |found id " << fid << ", tail = "  << foundTail  << endl;
                    
                    ejectQueues[node][selectedVc].pop();    
                }
            }

            //we'll output if we filled the port or if we found the tail flit
            output = demuxIndex[node] == -1 || foundTail;
            
            //we'll only change VC next cycle  if we found the tail flit
            if(foundTail){
                vcAtOutput[node] = -1;
            } else {
                vcAtOutput[node] = selectedVc;
            }
        
        //split port in 2 and each VC gets half
        } else if(combine_data == 1){
           
            bool foundTail0 = false;
            bool foundTail1 = false;
 
            //decide what to output
            bool output0 = false;
            bool output1 = false;

            //readout from ejectQueues
            for(int i = 0; i < 2; i++){
                
                //look in VC0
                if(!ejectQueues[node][0].empty()){
                    
                    int fid = ejectQueues[node][0].front();
                    bool tail = flitMap[fid].tail == 1;

                    //first VC0
                    if(demuxSlots[node][0]<2 && !foundTail0 && moduleReadys[node][0]){
                        demuxTemp0[node][demuxSlots[node][0]++] = fid;
                        foundTail0 = tail;
                        ejectQueues[node][0].pop();    
                        //cout << "found cd2 flit " << fid << ",on vc 0" << ",tail " << tail << endl;
                    }
                   
                    // set output for vc0
                    if((demuxSlots[node][0]==2 || foundTail0) && !output0){
                        output0 = true;
                        //set output in demux
                        demux[node][1]=demuxTemp0[node][0];
                        demux[node][0]=demuxTemp0[node][1];

                        //reset demuxtemp
                        demuxTemp0[node][0] = -1;
                        demuxTemp0[node][1] = -1;

                        //reset demuxSlots
                        demuxSlots[node][0] = 0;
                    }
                }

                //look in VC1
                if(!ejectQueues[node][1].empty()){
                 
                    int fid = ejectQueues[node][1].front();
                    bool tail = flitMap[fid].tail == 1;
                    
                    //second VC1
                    if(demuxSlots[node][1]<2 && !foundTail1 && moduleReadys[node][1]){
                        demuxTemp1[node][demuxSlots[node][1]++] = fid;
                        foundTail1 = tail;
                        ejectQueues[node][1].pop();    
                        //cout << "found cd2 flit " << fid << ",on vc 1" << ",tail " << tail << endl;
                    }

                    // set output for vc1
                    if((demuxSlots[node][1]==2 || foundTail1) && !output1){
                        output1 = true;

                        //set output in demux
                        demux[node][3]=demuxTemp1[node][0];
                        demux[node][2]=demuxTemp1[node][1];

                        //reset demuxtemp
                        demuxTemp1[node][0] = -1;
                        demuxTemp1[node][1] = -1;

                        //reset demuxSlots
                        demuxSlots[node][1] = 0;
                    }
                }
            }

            //we'll output if we got data from either VC
            output = output0 || output1;

        //split port in 4, each of 3 VCs uses the first 3 slots
        } else if(combine_data == 2 || combine_data == 3){
            
            bool valids[4] = {false, false, false, false};
           
            //cout << "ejectQueue node" << node << " = (" << ejectQueues[node][0].size() << ","<< ejectQueues[node][1].size() << ","<< ejectQueues[node][2].size() << ","<< ejectQueues[node][3].size() <<")" << endl;

            //in this case it's one flit from each VC in all cases
            //loop over VCs
            for(int i = 0; i < 4; i++){
                if(!ejectQueues[node][i].empty() && moduleReadys[node][i]){
                    
                    int fid = ejectQueues[node][i].front();
                    
                    valids[i] = true;
                    demux[node][i] = fid;
                    ejectQueues[node][i].pop();
                }
            }
            
            output = valids[0] | valids[1] | valids[2] | valids[3];
        }

        //we only output this cycle if we met all the conditions
        if(output){
            *valid = 1;
            *id0 = demux[node][0];
            *id1 = demux[node][1];
            *id2 = demux[node][2];
            *id3 = demux[node][3];
            
            int sample = *id0;

            //cout << "outputting "  << *id0 << " | "  << *id1 << " | "  << *id2 << " | " << *id3  << endl;

            //reset the values in demux regs
            for(int i = 0; i < 4; i++){
                flitMap.erase(demux[node][i]);
                demux[node][i] = -1;
            }
            //reset index
            demuxIndex[node] = 3;
           
           /*
            if(sample>10000){
                for(std::map<int,FlitInfo>::iterator it = flitMap.begin(); it != flitMap.end(); ++it)
                    cout << it->first << " - "; 
                cout << "------------------------------------------------------" << endl;
            }
            */
            
        } else {
            *valid = 0;
            *id0 = -1;
            *id1 = -1;
            *id2 = -1;
            *id3 = -1;
        }
    }
}

// this function tells the module whether the NoC fpin is ready to receive
int checkNocReady(int node, int vc){
    if(inputCredits[node][vc]>0)
        return 1;
    //cout << "node=" << node << " vc=" << vc << " credits=" << inputCredits[node][vc] << endl;
    return 0;
}

//this function tells the NoC fpout whether the module is ready to receive
void sendModuleReady(int node, int vc, int ready){
   moduleReadys[node][vc] = ready; 
}

void receiveFabricCredit(int node, int vc){
    int credit = receive_credit(node, vc);
    inputCredits[node][vc] += credit;
}

void sendFabricCredit(int node, int vc){
    send_credit(node, vc, 1);
}

