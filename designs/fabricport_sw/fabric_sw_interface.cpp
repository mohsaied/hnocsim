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

int _NODES = 16;
int _VCS   =  2;
int _DEPTH =  8;

//----------------------------------------------------------------------------------------
// FABRICPORT DATA STRUCTURES 
//----------------------------------------------------------------------------------------

// FABRICPORT OUT
//--------------------

//afifo at the output fabricport
vector< queue<int> > ejectQueues;

//tdm demux registers -- 4 of them
vector< vector<int> > demux;
vector<int> demuxIndex;

//ready signals from modules
vector< vector< int > > moduleReadys;

//number of credits that the fpout should send back to noc
vector< vector< int > > outstandingCredits;

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


//----------------------------------------------------------------------------------------
// FUNCTIONS
//----------------------------------------------------------------------------------------


void connectFabricSocket(){
    connectSocket();

    //resize demuxes
    demuxIndex.resize(_NODES);
    for(int i = 0; i < _NODES; i++){
        demuxIndex[i] = 0;
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
    int rec_id = -1;
    int rec_vc = -1;

    for(int i = 0; i < 4; i++){
        rec_id = -1;
        rec_vc = -1;
        eject(&rec_id, &rec_vc);

        if(rec_id != -1){
            int rec_node = flitMap[rec_id].dest;
            ejectQueues[rec_node].push(rec_id);    
            outstandingCredits[rec_node][rec_vc]++;
        }
        
        //send back credits if module is ready
        for(int node = 0; node < _NODES; node++){
            for(int vc = 0; vc < _VCS; vc++){
                if(moduleReadys[node][vc]==1 && outstandingCredits[node][vc]>0){
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
                //receive credit and increment counters
                receiveFabricCredit(node, vc);
            }
        }

        inject();
        
        nextCycle(speedup);
    }
}

int ejectFabric(int* id, int* vc){
    eject(id,vc);
}

void ejectFourFabric(int node, int* id0, int* id1, int* id2, int* id3, int* valid){
   
    //first check if that module is ready to receive
    //TODO make eject function understand VCs
    if(moduleReadys[node][0]==0){
        //if we aren't ready we output zeroes and not valid
        *valid = 0;
        *id0 = -1;
        *id1 = -1;
        *id2 = -1;
        *id3 = -1;

    } else { // if we are ready we'll output things
        
        bool foundTail = false;

        //readout from ejectQueue
        for(int i = 0; i < 4; i++){
            if(!ejectQueues[node].empty() && demuxIndex[node]<4 && !foundTail){
                int fid =  ejectQueues[node].front();
                
                demux[node][demuxIndex[node]++] = fid;

                foundTail = flitMap[fid].tail == 1;
                
                ejectQueues[node].pop();    
            }
        }

        bool output = demuxIndex[node] == 4 || foundTail;

        //we only output this cycle if we met all the conditions
        if(output){
            *valid = 1;
            *id0 = demux[node][0];
            *id1 = demux[node][1];
            *id2 = demux[node][2];
            *id3 = demux[node][3];

            //reset the values in demux regs
            for(int i = 0; i < 4; i++){
                flitMap.erase(demux[node][i]);
                demux[node][i] = -1;
            }
            //reset index
            demuxIndex[node] = 0;
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

