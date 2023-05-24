#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <algorithm>
#include <vector>
#include <map>
#include <cassert>
#include <utility>
#include <iterator>
#include <random>
#include <math.h>

#include "node.h"
#include "module.h"
#include "stopping_buffer.h"

#define SEED 1234
#define DEFAULT_RADIX 4
#define DEFAULT_PLACE_LIM 1
#define DEFAULT_ALPHA 0.95
#define DEFAULT_INNER_NUM 2
#define DEFAULT_ACCEPT_RATE 0.8
#define DEFAULT_END_FACTOR 0.005
#define QUEUE_DEPTH 10000
#define STOP_THRESH 0.1

using namespace std;

//Returns approximate value of e^x using sum of first n terms of Taylor Series
double exponential(double x)
{
  int n = 10;
  double sum = 1; // initialize sum of series
 
  for (double i = n - 1; i > 0; --i )
    sum = 1 + x * sum / i;
 
  return sum;
}

pair<Node**,Link**> genNOC(int radix); // radix: mesh radix (e.g. n=4: 4x4, 16-node mesh)
map<string,Module*> genModuleGraph(string graphfile);
map<string,Module*>* initialPlacement(int radix, Node** nodes, Link** links, map<string,Module*> &modules);
double computeCost(int radix, Node** nodes, Link** links, map<string,Module*> modules);
void updateLinkUsages(int radix, Link** links, map<string,Module*> modules);
pair<map<string,Module*>,map<string,Module*>*> perturbPlacement(int radix, Link** links, Node** nodes, map<string,Module*> modules, map<string,Module*>* node_module_map, unsigned int place_lim, unsigned int &seed);
bool evaluateStoppingCriteria(StoppingBuffer stop_buffer, double thresh);
bool evaluateStoppingCriteria(double temp, double end_factor, double curr_cost, int num_nets);
double updateTemp(double temp, double alpha, double acceptance_rate);
bool acceptMove(double delta_cost, double temp, unsigned int &seed);
double setStartTemp(int radix, Node**nodes, Link** links, map<string,Module*> modules, map<string,Module*>* node_module_map, unsigned int place_lim, unsigned int &seed, int inner_num, double start_accept_rate);

void anneal(int radix, Node**nodes, Link** links, map<string,Module*> &modules, unsigned int place_lim, unsigned int seed, double alpha, int inner_num, double start_accept_rate, double end_factor);


char* getCmdOption(char ** begin, char ** end, const string & option);
bool cmdOptionExists(char** begin, char** end, const string& option);

int main (int argc, char *argv[])
{

  /* Read command line arguments */
  if (cmdOptionExists(argv, argv+argc, "-h")) {
    cout << "Usage: noc_placer" << endl;
    return 0;
  }

  char* entered_radix = getCmdOption(argv, argv+argc, "-r");
  int mesh_radix = (entered_radix) ? atoi(entered_radix) : DEFAULT_RADIX;

  char* file = getCmdOption(argv, argv+argc, "-f"); 
  string graphfile((file) ? file : "module-graph.out");  
  
  char* entered_lim = getCmdOption(argv, argv+argc, "-lim");
  unsigned int place_lim = (entered_lim) ? atoi(entered_lim) : DEFAULT_PLACE_LIM;

  char* entered_seed = getCmdOption(argv, argv+argc, "-seed");
  unsigned int seed = (entered_seed) ? atoi(entered_seed) : SEED;

  char* entered_alpha = getCmdOption(argv, argv+argc, "-alpha");
  double alpha = (entered_alpha) ? atof(entered_alpha) : DEFAULT_ALPHA;

  char* entered_num = getCmdOption(argv, argv+argc, "-n");
  int inner_num = (entered_num) ? atoi(entered_num) : DEFAULT_INNER_NUM;

  char* entered_rate = getCmdOption(argv, argv+argc, "-ar");
  double start_accept_rate = (entered_rate) ? atof(entered_rate) : DEFAULT_ACCEPT_RATE;

  char* entered_factor = getCmdOption(argv, argv+argc, "-e");
  double end_factor = (entered_factor) ? atof(entered_factor) : DEFAULT_END_FACTOR;

  /* Generate the NoC */
  pair<Node**,Link**> noc = genNOC(mesh_radix);
  Node** node_list = noc.first;
  Link** link_list = noc.second;

  /* Create map of modules connected through the NoC */
  map<string,Module*> module_map = genModuleGraph(graphfile);

  /* Perform simulated annealing */
  anneal(mesh_radix, node_list, link_list, module_map, place_lim, seed, alpha, inner_num,start_accept_rate, end_factor);

  /* Print out final placement */

  cout << "\n********* FINAL PLACEMENT *********" << endl;

  for (map<string,Module*>::iterator it=module_map.begin(); it!=module_map.end(); ++it) {

    cout << it->second->getName() << " -> " << it->second->getNode()->getID() << endl;

  }

  return 0;
}

void anneal(int radix, Node**nodes, Link** links, map<string,Module*> &modules, unsigned int place_lim, unsigned int seed, double alpha, int inner_num, double start_accept_rate, double end_factor)
{
  /* Check legality of place limit */
  if (place_lim < modules.size()/(radix*radix)+1) {
    place_lim = modules.size()/(radix*radix)+1;
    cout << "Adjusting place limit to " << place_lim << endl;
  }

  /* Count number of nets */
  int num_nets = 0;

  for (map<string,Module*>::iterator it=modules.begin(); it!=modules.end(); ++it) {
    num_nets += it->second->nocnets.size();
  }

  cout << "Number of nets: " << num_nets << endl;

  /* Create an initial placement of modules in the NoC */
  map<string,Module*>* node_module_map = initialPlacement(radix, nodes, links, modules);

  StoppingBuffer stop_buffer(QUEUE_DEPTH);
  double temp = setStartTemp(radix, 
			     nodes, 
			     links, 
			     modules, 
			     node_module_map,
			     place_lim,
			     seed, 
			     inner_num, 
			     start_accept_rate);

  cout << "Temp\tProp-Cost\tNew-Cost" << endl;

  double curr_cost = computeCost(radix, nodes, links, modules);

  cout << temp << "\t-\t" << curr_cost << endl;

  while (!evaluateStoppingCriteria(temp,end_factor,curr_cost,num_nets)) {

    int accepted_cnt = 0;
    int neg_move_cnt = 1;

    for (int i=0; i<(inner_num*pow((double)modules.size(),1.3333)); i++) {
    
      cout << temp << "\t";      

      //cout << "Old cost: " << curr_cost << endl;

      pair<map<string,Module*>,map<string,Module*>*> new_placement = perturbPlacement(radix,
										      links,
										      nodes,
										      modules,
										      node_module_map,
										      place_lim,
										      seed);
      map<string,Module*> perturbation = new_placement.first;
      map<string,Module*>* new_mapping = new_placement.second;

      double new_cost = computeCost(radix, nodes, links, perturbation);

      cout << new_cost << "\t";

      if (new_cost < curr_cost) {
    
	/* Cleanup old placement */
	for (map<string,Module*>::iterator m_it=modules.begin(); m_it!=modules.end(); ++m_it)
	  delete m_it->second;

	modules = perturbation;
	node_module_map = new_mapping;

	stop_buffer.push(new_cost);

	curr_cost = new_cost;

	//accepted_cnt++;

      }
      else {

	neg_move_cnt++;
      
	if (acceptMove(new_cost-curr_cost,temp,seed)) {

	  //cout << "****Accepted negative move";

	  /* Cleanup old placement */
	  for (map<string,Module*>::iterator m_it=modules.begin(); m_it!=modules.end(); ++m_it)
	    delete m_it->second;

	  modules = perturbation;
	  node_module_map = new_mapping;

	  stop_buffer.push(new_cost);

	  curr_cost = new_cost;

	  accepted_cnt++;

	}
	else {
	
	  /* Cleanup rejected placement */
	  for (map<string,Module*>::iterator m_it=perturbation.begin(); m_it!=perturbation.end(); ++m_it)
	    delete m_it->second;

	  stop_buffer.push(curr_cost);
	}

      }

      //curr_cost = computeCost(radix, nodes, links, modules);
      cout << curr_cost << endl;

    }

    temp = updateTemp(temp,alpha,(double)accepted_cnt/(double)neg_move_cnt);

  }

}

double setStartTemp(int radix, Node**nodes, Link** links, map<string,Module*> modules, map<string,Module*>* node_module_map, unsigned int place_lim, unsigned int &seed, int inner_num, double start_accept_rate)
{
  /* Create a copy of the current placement to perturb */
  map<string,Module*> modules_copy;
  for (map<string,Module*>::iterator m_it=modules.begin(); m_it!=modules.end(); ++m_it) {

    Module* m_copy;

    if (modules_copy.find(m_it->second->getName()) == modules_copy.end()) {
      
      m_copy = new Module(m_it->second->getName());
      m_copy->setNode(m_it->second->getNode());
      modules_copy[m_it->first] = m_copy;

    }
    else
      m_copy = modules_copy[m_it->first];

    for (vector<Module*>::iterator n_it=m_it->second->nocnets.begin(); n_it!=m_it->second->nocnets.end(); ++n_it) {
      
      Module* n_copy;
      
      if (modules_copy.find((*n_it)->getName()) == modules_copy.end()) {

	n_copy = new Module((*n_it)->getName());
	n_copy->setNode((*n_it)->getNode());
	modules_copy[(*n_it)->getName()] = n_copy;

      }
      else {

	n_copy = modules_copy[(*n_it)->getName()];

      }

      m_copy->nocnets.push_back(n_copy);

    }

  }

  map<string,Module*>* node_module_map_copy = new map<string,Module*>[radix*radix];
  for (int i=0; i<(radix*radix); i++) {

    for (map<string,Module*>::iterator m_it=node_module_map[i].begin(); m_it!=node_module_map[i].end(); ++m_it) {

      (node_module_map_copy[i])[m_it->first] = modules_copy[m_it->first];

    }

  }

  double curr_cost = computeCost(radix, nodes, links, modules);

  vector<double> deltas;

  for (int i=0; i<(2*inner_num*pow((double)modules.size(),1.3333)); i++) {

    pair<map<string,Module*>,map<string,Module*>*> new_placement = perturbPlacement(radix,
										    links,
										    nodes,
										    modules_copy,
										    node_module_map_copy,
										    place_lim,
										    seed);
    map<string,Module*> perturbation = new_placement.first;
    map<string,Module*>* new_mapping = new_placement.second;

    double new_cost = computeCost(radix, nodes, links, perturbation);

    if (new_cost >= curr_cost) deltas.push_back(new_cost-curr_cost);

    // accept all moves
    modules_copy = perturbation;
    node_module_map_copy = new_mapping;

  }

  double avg = 0;

  for (vector<double>::iterator it=deltas.begin(); it!=deltas.end(); ++it) 
    avg += *it;

  avg = avg/(double)deltas.size();

  return (-1)*avg/(log(start_accept_rate));

}

double updateTemp(double temp, double alpha, double acceptance_rate)
{
  double a;
  
  if (acceptance_rate > 0.96)
    a = (alpha-0.45>0) ? alpha - 0.45 : 0.05;
  else if (acceptance_rate > 0.8 && acceptance_rate <= 0.96)
    a = alpha - 0.05;
  else if (acceptance_rate > 0.15 && acceptance_rate <= 0.8)
    a = alpha;
  else if (acceptance_rate <= 0.15)
    a = alpha - 0.15;

  return temp * a;

}

bool acceptMove(double delta_cost, double temp, unsigned int &seed)
{
  default_random_engine rand_generator (seed);
  uniform_real_distribution<double> rand_distribution(0.0,1.0);

  default_random_engine seed_generator (seed);
  uniform_int_distribution<int> seed_distribution(0,seed-1);
  seed += seed_distribution(seed_generator);

  double rand = rand_distribution(rand_generator);

  if (rand < exponential((-1)*delta_cost/temp))
    return true;
  else
    return false;
  
}

pair<map<string,Module*>,map<string,Module*>*> perturbPlacement(int radix, Link** links, Node** nodes, map<string,Module*> modules, map<string,Module*>* node_module_map, unsigned int place_lim, unsigned int &seed)
{
  //cout << "Seed: " << seed << endl;
  
  /* Generator of new seeds */
  default_random_engine seed_generator (seed);
  uniform_int_distribution<int> seed_distribution(0,seed-1);

  /* Create a copy of the current placement to perturb */
  map<string,Module*> perturbation;
  for (map<string,Module*>::iterator m_it=modules.begin(); m_it!=modules.end(); ++m_it) {

    Module* m_copy;

    if (perturbation.find(m_it->second->getName()) == perturbation.end()) {
      
      m_copy = new Module(m_it->second->getName());
      m_copy->setNode(m_it->second->getNode());
      perturbation[m_it->first] = m_copy;

    }
    else
      m_copy = perturbation[m_it->first];

    for (vector<Module*>::iterator n_it=m_it->second->nocnets.begin(); n_it!=m_it->second->nocnets.end(); ++n_it) {
      
      Module* n_copy;
      
      if (perturbation.find((*n_it)->getName()) == perturbation.end()) {

	n_copy = new Module((*n_it)->getName());
	n_copy->setNode((*n_it)->getNode());
	perturbation[(*n_it)->getName()] = n_copy;

      }
      else {

	n_copy = perturbation[(*n_it)->getName()];

      }

      m_copy->nocnets.push_back(n_copy);

    }

  }

  map<string,Module*>* new_mapping = new map<string,Module*>[radix*radix];
  for (int i=0; i<(radix*radix); i++) {

    for (map<string,Module*>::iterator m_it=node_module_map[i].begin(); m_it!=node_module_map[i].end(); ++m_it) {

      (new_mapping[i])[m_it->first] = perturbation[m_it->first];

    }

  }
  
  /* Select a random module to move */
  map<string,Module*>::iterator random_module = perturbation.begin();
  default_random_engine module_generator (seed);
  //cout << "Range from 0 to " << perturbation.size()-1 << endl;
  uniform_int_distribution<int> module_distribution(0,perturbation.size()-1);
  int r = module_distribution(module_generator);
  //cout << "Random module " << r << endl;
  advance(random_module, r);
  Module* move_module = random_module->second;
  int old_loc = move_module->getNode()->getID();

  //cout << "Selected: " << move_module->getName() << " at node " << old_loc << endl;
  
  seed += seed_distribution(seed_generator);
  //cout << "Seed: " << seed << endl;

  /* Select a random node to move the module to */
  default_random_engine node_generator (seed);
  uniform_int_distribution<int> node_distribution(0,(radix*radix)-1);
  int new_loc = node_distribution(node_generator);
  
  while (new_loc == old_loc) new_loc = node_distribution(node_generator);

  //cout << "Moving module to node " << new_loc << endl;
  
  seed += seed_distribution(seed_generator);

  /* If node is at limit of connected modules, select a module to swap */
  Module* swap_module = NULL;
  if (new_mapping[new_loc].size() >= place_lim) {
    
    default_random_engine second_module_generator (seed);
    uniform_int_distribution<int> second_module_distribution(0,new_mapping[new_loc].size()-1);
    seed += seed_distribution(seed_generator);
    //cout << "Seed: " << seed << endl;

    map<string,Module*>::iterator random_module_2 = new_mapping[new_loc].begin();
    r = second_module_distribution(second_module_generator);
    //cout << "Random swap module " << r << endl;
    advance(random_module_2, r);
    swap_module = random_module_2->second;    

    swap_module->setNode(nodes[old_loc]);
    new_mapping[new_loc].erase(swap_module->getName());
    (new_mapping[old_loc])[swap_module->getName()] = swap_module;

    //cout << "Swapping with module " << swap_module->getName() << endl;

  }

  /* Remove module from currently connected node */
  new_mapping[old_loc].erase(move_module->getName());
  
  /* Connect module to new node */
  move_module->setNode(nodes[new_loc]);
  (new_mapping[new_loc])[move_module->getName()] = move_module;

  pair<map<string,Module*>,map<string,Module*>*> placement = make_pair(perturbation,new_mapping);
  return placement;
}

double computeCost(int radix, Node** nodes, Link** links, map<string,Module*> modules)
{
  /* compute link usages */
  updateLinkUsages(radix,links,modules);

  double cost = 0;

  for (map<string,Module*>::iterator m_it=modules.begin(); m_it!=modules.end(); ++m_it) {

    Node* src_node = m_it->second->getNode();

    for (vector<Module*>::iterator nets=m_it->second->nocnets.begin(); nets!=m_it->second->nocnets.end(); ++nets) {

      Node* dst_node = (*nets)->getNode();
      Node* intm_node = src_node;

      // XY link traversal
      while (intm_node->getX() != dst_node->getX()) {
	
	Direction d;
	
	if (intm_node->getX() > dst_node->getX()) 
	  d = W; // go west
	else 
	  d = E; // go east

	cost += intm_node->links[d]->usage;
	intm_node = intm_node->links[d]->sink;
	
      }

      while (intm_node->getY() != dst_node->getY()) {

	Direction d;
	
	if (intm_node->getY() > dst_node->getY()) 
	  d = N; // go north
	else 
	  d = S; // go south

	cost += intm_node->links[d]->usage;
	intm_node = intm_node->links[d]->sink;

      }

      assert(intm_node->getID() == dst_node->getID());

    }

  }

  return cost;

}

bool evaluateStoppingCriteria(StoppingBuffer stop_buffer, double thresh)
{
  return stop_buffer.isDeltaBelowThresh(thresh);
}

bool evaluateStoppingCriteria(double temp, double end_factor, double curr_cost, int num_nets)
{
  
  return temp < (end_factor * curr_cost / (double) num_nets);

}

map<string,Module*>* initialPlacement(int radix, Node** nodes, Link** links, map<string,Module*> &modules)
{
  int num_nodes = radix*radix;
  int i = 0;

  map<string,Module*>* node_module_map = new map<string,Module*>[num_nodes];

  /* Place modules naively */
  for (map<string,Module*>::iterator it=modules.begin(); it!=modules.end(); ++it) {
    (node_module_map[i])[it->second->getName()] = it->second;
    it->second->setNode(nodes[i++]);
    if (i>=num_nodes) i = 0;
    
  }

  return node_module_map;

}

void updateLinkUsages(int radix, Link** links, map<string,Module*> modules)
{
  int num_links = 2*2*radix*(radix-1);

  /* Reset link usages */
  for (int i=0; i<num_links; i++) links[i]->usage = 0;

  /* Compute link usages */
  bool* updateUsage = new bool[num_links]; // flag for updating link usage
  for (int i=0; i<num_links; i++) updateUsage[i] = false; // sanity check
  
  for (map<string,Module*>::iterator it=modules.begin(); it!=modules.end(); ++it) {
    
    Node* src_node = it->second->getNode();

    for(vector<Module*>::iterator nets=it->second->nocnets.begin(); nets!=it->second->nocnets.end(); ++nets) {

      Node* dst_node = (*nets)->getNode();
      Node* intm_node = src_node;

      // XY link traversal
      while (intm_node->getX() != dst_node->getX()) {
	
	Direction d;
	
	if (intm_node->getX() > dst_node->getX()) 
	  d = W; // go west
	else 
	  d = E; // go east

	updateUsage[intm_node->links[d]->id] = true;
	intm_node = intm_node->links[d]->sink;
	
      }

      while (intm_node->getY() != dst_node->getY()) {

	Direction d;
	
	if (intm_node->getY() > dst_node->getY()) 
	  d = N; // go north
	else 
	  d = S; // go south

	updateUsage[intm_node->links[d]->id] = true;
	intm_node = intm_node->links[d]->sink;

      }

      assert(intm_node->getID() == dst_node->getID());

    }

    // update link usages
    for (int i=0; i<num_links; i++) {
      if (updateUsage[i]) links[i]->usage++;
      updateUsage[i] = false;
    }

  }  

}

map<string,Module*> genModuleGraph(string graphfile)
{
  map<string,Module*> module_list;

  ifstream fin;
  fin.open(graphfile.data());
  assert(fin.is_open());

  string s;

  while (getline(fin,s)) {
    
    istringstream line(s);

    string main_module_name;
    line >> main_module_name;

    if (module_list.find(main_module_name) == module_list.end()) {
      // doesn't exist yet
      Module* main_module_new = new Module(main_module_name);
      module_list[main_module_name] = main_module_new;
    }
    
    string module_name;
    while (line >> module_name) {

      if (module_list.find(module_name) == module_list.end()) {
	// doesn't exist yet
	Module* module_new = new Module(module_name);
	module_list[module_name] = module_new;	
      }

      // connect it to main module
      (module_list[main_module_name]->nocnets).push_back(module_list[module_name]);
    }

  }

  fin.close();

  return module_list;
}


pair<Node**,Link**> genNOC(int radix)
{
  Link** link_list = new Link* [2*2*radix*(radix-1)];
  Node** nodes = new Node* [radix*radix];
  int node_id = 0;
  int link_id = 0;

  for (int y=0; y<radix; y++) {

    for (int x=0; x<radix; x++) {
           
      Node* n = new Node(x,y,node_id);
      nodes[node_id++] = n;

    }

  }

  for (int i=0; i<node_id; i++) {
    int x = nodes[i]->getX();
    int y = nodes[i]->getY();
    Link* new_link;

    if (x-1 >= 0) { // west link
      new_link = new Link(link_id,nodes[i],nodes[i-1]);
      nodes[i]->links[W] = new_link;
      link_list[link_id++] = new_link;
    }
        
    if (x+1 < radix) { // east link
      new_link = new Link(link_id,nodes[i],nodes[i+1]);
      nodes[i]->links[E] = new_link;
      link_list[link_id++] = new_link;
    }
    
    if (y-1 >= 0) { // north link
      new_link = new Link(link_id,nodes[i],nodes[i-radix]);
      nodes[i]->links[N] = new_link;
      link_list[link_id++] = new_link;
    }
    
    if (y+1 < radix) { // south link
      new_link = new Link(link_id,nodes[i],nodes[i+radix]);
      nodes[i]->links[S] = new_link;
      link_list[link_id++] = new_link;
    }
    
  }
  
  pair<Node**,Link**> noc = make_pair (nodes,link_list);
  
  return noc;
  
}

char* getCmdOption(char ** begin, char ** end, const string & option)
{
    char ** itr = std::find(begin, end, option);
    if (itr != end && ++itr != end)
    {
        return *itr;
    }
    return 0;
}

bool cmdOptionExists(char** begin, char** end, const string& option)
{
    return std::find(begin, end, option) != end;
}
