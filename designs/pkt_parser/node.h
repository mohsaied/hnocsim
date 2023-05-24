#ifndef NODE_H
#define NODE_H

#include <map>

using namespace std;

enum Direction {N,S,E,W};

class Node;

class Link
{
 public:
  Link(int _id, Node* _src, Node* _sink);
  int id;
  Node* src;
  Node* sink;
  int usage;
};

class Node 
{

 private:
  int _x;
  int _y;
  int _id;
   

 public:
  map<Direction,Link*> links;

  Node();
  Node(int x, int y, int id);

  inline int getX() const {return _x;}
  inline int getY() const {return _y;}
  inline int getID() const {return _id;}

};


#endif
