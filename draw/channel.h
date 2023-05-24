#ifndef CHANNEL_H
#define CHANNEL_H

#define ROUTER_SIZE 58
#define MESH_RADIX 4

class Channel
{
 private:
  

 public:
  Channel(int id);

  int _id;
  double _load;

  int src; // src router
  int dst; // dst router
  bool draw; // draw or don't draw
  int x_src;
  int x_dst;
  int y_src;
  int y_dst;
  double _colour; // degree of red [0-1]

  void setLoad(double load);
  
};


#endif
