#ifndef MODULE_H
#define MODULE_H

#include <string>
#include <vector>
#include "node.h"

using namespace std;

class Module 
{

 private:
  string _name;
  Node* _connection_node;
  
 public:
  vector<Module*> nocnets;

  Module();
  Module(string name);

  inline string getName() const {return _name;}

  inline Node* getNode() const {return _connection_node;}
  inline void setNode(Node* n) {_connection_node = n;}
  


};


#endif
