#include "node.h"

Node::Node() {

  _x = -1;
  _y = -1;
  _id = -1;

}

Node::Node(int x,int y, int id) {
  
  _x = x;
  _y = y;
  _id = id;

}

Link::Link(int _id, Node* _src, Node* _sink) {
  id = _id;
  src = _src;
  sink = _sink;
  usage = 0;
}
