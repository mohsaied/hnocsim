#ifndef ROUTER_H
#define ROUTER_H

#include <vector>

using namespace std;

class Router
{
 private:


 public:
  Router(int id);

  int _id;
  vector<int> in_channels;
  double total_load;

};






#endif
