#include <iostream>
#include "fabric_sw_interface.hpp"

int nodes = 16;
int vcs = 2;

int main()
{
	
	connectFabricSocket();

    nextFabricCycle(1);

	queueFourFabricFlit(0,0,2,4,0,1,0, 0,1,2,4,0,0,0, 0,2,2,4,0,0,0, 0,3,2,4,0,0,1);
	queueFourFabricFlit(1,4,5,7,0,1,0, 1,5,5,7,0,0,0, 1,6,5,7,0,0,1, 1,-1,5,7,0,0,1);
	nextFabricCycle(1);
	queueFourFabricFlit(2,7,2,4,0,1,0, 2,8,2,4,0,0,1, 3,9,2,4,0,1,0, 3,10,2,4,0,0,1);
	nextFabricCycle(1);
    queueFourFabricFlit(4,11,2,4,0,1,1, 5,12,2,4,0,1,1, 6,13,2,4,0,1,1, 7,14,2,4,0,1,1);
	nextFabricCycle(1);


	for(int i = 0;i < 20; i++){
		int rec_id0 = 99;
        int rec_id1 = 99;
        int rec_id2 = 99;
        int rec_id3 = 99;

		int rec = ejectFourFabric(4, &rec_id0, &rec_id1, &rec_id2, &rec_id3);
		std::cout << "received <4>|"  << rec_id0 << "|"  << rec_id1 << "|"  << rec_id2 << "|" << rec_id3 << "|" << std::endl;
		rec = ejectFourFabric(7, &rec_id0, &rec_id1, &rec_id2, &rec_id3);
		std::cout << "received <7>|"  << rec_id0 << "|"  << rec_id1 << "|"  << rec_id2 << "|" << rec_id3 << "|" << std::endl;
		std::cout  << std::endl;
		nextFabricCycle(1);
	}

	nextFabricCycle(1);
	nextFabricCycle(1);


	exitFabricSocket();

	return 0;

}
