#include <iostream>
#include "fabric_sw_interface.cpp"

int nodes = 16;
int vcs = 2;

void check_credits()
{
	for(int i = 0; i < nodes; i++)
		for(int j = 0; j < vcs; j++)
		{
			if(receiveFabricCredit(i,j))
				cout << "Node " << i << " VC " << j <<  " returned a credit" << endl; 
		}
}

int main()
{
	
	connectFabricSocket();
/*
	
	queueFabricFlit(0,1,0,3,1,0);
	injectFabric();
	check_credits();
	nextFabricCycle(1);
	
	queueFabricFlit(0,2,0,3,0,0);
	injectFabric();
	check_credits();
	nextFabricCycle(1);
	
	queueFabricFlit(0,3,0,3,0,0);
	injectFabric();
	check_credits();
	nextFabricCycle(1);
	
	queueFabricFlit(0,4,0,3,0,1);
	injectFabric();
	check_credits();
*/	nextFabricCycle(1);


	queueFabricFlit(1,0,2,4,0,1,0);
	injectFabric();
	check_credits();
	nextFabricCycle(1);
	
	queueFabricFlit(1,1,2,4,0,0,0);
	injectFabric();
	check_credits();
	nextFabricCycle(1);
	
	queueFabricFlit(1,2,2,4,0,0,0);
	injectFabric();
	check_credits();
	nextFabricCycle(1);
	
	queueFabricFlit(1,3,2,4,0,0,0);
	injectFabric();
	check_credits();
	nextFabricCycle(1);
	
	queueFabricFlit(1,4,2,4,0,0,0);
	injectFabric();
	check_credits();
	nextFabricCycle(1);

	queueFabricFlit(1,5,2,4,0,0,0);
	injectFabric();
	check_credits();
	nextFabricCycle(1);

	queueFabricFlit(1,6,2,4,0,0,0);
	injectFabric();
	check_credits();
	nextFabricCycle(1);
	
	queueFabricFlit(1,7,2,4,0,0,0);
	injectFabric();
	check_credits();
	nextFabricCycle(1);
	
//	queueFabricFlit(1,8,2,4,0,0,0);
//	injectFabric();
//	check_credits();
//	nextFabricCycle(1);

	queueFabricFlit(1,9,2,4,0,0,0);
	injectFabric();
	check_credits();
	nextFabricCycle(1);
	
	queueFabricFlit(1,10,2,4,0,0,0);
	injectFabric();
	check_credits();
	nextFabricCycle(1);
	
	queueFabricFlit(1,11,2,4,0,0,1);
	injectFabric();
	check_credits();
	nextFabricCycle(1);

	for(int i = 0;i < 50; i++){
		//if(i < 10)
		//	propagate_stall(4,1);
		//else
		//	propagate_stall(4,0);
		int rec_id = 99;
		int rec_vc = 99;
		int rec = ejectFabric(&rec_id, &rec_vc);
		std::cout << "received " << rec_id << std::endl;
		check_credits();
		nextFabricCycle(1);
	}

	int rec_id = 99;
	int rec_vc = 99;
	
	//send a credit back
	send_credit(4,0,1);
	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);
	
	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);

	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);

	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);

	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);

	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);


	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);



	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);



	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);



	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);



	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);



	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);



	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);



	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);



	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);



	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);



	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);



	ejectFabric(&rec_id, &rec_vc);
	std::cout << " received " << rec_id << std::endl;
	nextFabricCycle(1);


	nextFabricCycle(1);
	nextFabricCycle(1);
	nextFabricCycle(1);
	nextFabricCycle(1);


	exitFabricSocket();

	return 0;

}
