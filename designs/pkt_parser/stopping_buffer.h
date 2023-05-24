#ifndef STOP_BUFFER_H
#define STOP_BUFFER_H

#include <deque>

using namespace std;

class StoppingBuffer
{
 private:
  unsigned int _depth;
  deque<double> _buffer;

 public:
  StoppingBuffer(unsigned int depth);

  void push(double item);
  bool isDeltaBelowThresh(double thresh);
  
};


#endif
