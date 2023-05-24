#include "stopping_buffer.h"

StoppingBuffer::StoppingBuffer(unsigned int depth)
{
  _depth = depth;
 
}

void StoppingBuffer::push(double item)
{
  _buffer.push_back(item);
  while (_buffer.size() > _depth) _buffer.pop_front();

}

bool StoppingBuffer::isDeltaBelowThresh(double thresh)
{
  if (_buffer.size() < _depth) return false;
  
  double min = -1;
  double max = 0;

  for (deque<double>::iterator it=_buffer.begin(); it!=_buffer.end(); ++it) {

    if (min == -1 || min > *it) min = *it;
    if (max < *it) max = *it;

  }

  return (max-min) < thresh;

}
