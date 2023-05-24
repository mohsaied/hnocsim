#include <cmath>
#include <math.h>

#include "channel.h"

using namespace std;

Channel::Channel(int id) : _id(id)
{

}

void Channel::setLoad(double load) {

  _load = load;
  _colour = 1.5*_load;

  // determine canvas coordinates

  if (abs(src - dst) == 1) {
    // Vertical link
    draw = true;
    
    if (src > dst) {
      // Going up
      x_src = (2*(src/MESH_RADIX)+1)*ROUTER_SIZE+ROUTER_SIZE/4;
      x_dst = x_src;

      y_dst = (2*((dst%MESH_RADIX)+1))*ROUTER_SIZE;
      y_src = y_dst + ROUTER_SIZE;
  
    }
    else {
      // Going down
      x_src = (2*(src/MESH_RADIX)+1)*ROUTER_SIZE+3*ROUTER_SIZE/4;
      x_dst = x_src;

      y_src = (2*((src%MESH_RADIX)+1))*ROUTER_SIZE;
      y_dst = y_src + ROUTER_SIZE;

    }

  }
  else if (abs(src - dst) == MESH_RADIX) {
    // Horizontal link
    draw = true;

    if (src > dst) {
      // Going left

      y_src = (2*(src%MESH_RADIX)+1)*ROUTER_SIZE+3*ROUTER_SIZE/4;
      y_dst = y_src;

      x_dst = (2*((dst/MESH_RADIX)+1))*ROUTER_SIZE;
      x_src = x_dst + ROUTER_SIZE;

    }
    else {
      // Going right

      y_src = (2*(src%MESH_RADIX)+1)*ROUTER_SIZE+ROUTER_SIZE/4;
      y_dst = y_src;

      x_src = (2*((src/MESH_RADIX)+1))*ROUTER_SIZE;
      x_dst = x_src + ROUTER_SIZE;

    }

  }
  else {
    // Non-existent link
    draw = false;
  }

}
