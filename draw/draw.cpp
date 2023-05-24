#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string>
#include <map>
#include <cmath>
#include <math.h>

#include "channel.h"
#include "router.h"
#include "bgl_graphics.h"

using namespace std;

void readMapping(char* filename);
void readUtilization(char* filename);

static void drawscreen (GtkWidget *widget, cairo_t *cr);
static void drawRouters(GtkWidget *widget, cairo_t *cr);
static void drawLinks(GtkWidget *widget, cairo_t *cr);
static void drawLegend(GtkWidget *widget, cairo_t *cr);

gtk_win gtkw (drawscreen, 1000, 1000);

map<int,Channel* > mchannels;
map<int,Router* > mrouters;

int main(int argc, char *argv[]) 
{

  if (argc != 3) {
    cout << "Usage: draw <link_mapping_file> <link_utilization_file>" << endl;
    return 0;
  }

  readMapping(argv[1]);

  readUtilization(argv[2]);  

  // Initialize canvas
  gtkw.init_world(0,0,ROUTER_SIZE*(2*MESH_RADIX+3),ROUTER_SIZE*(2*MESH_RADIX+1));
  gtkw.init_graphics("");

  return 0;

}


static void drawscreen (GtkWidget *widget, cairo_t *cr)
{
  gtkw.clearscreen( cr );

  drawRouters(widget,cr);

  drawLinks(widget,cr);

  //drawLegend(widget,cr);

}

static void drawRouters(GtkWidget *widget, cairo_t *cr)
{
  gtkw.setcolor(cr, 0, 0, 0, 1);

  int i=0;

  for (int x=ROUTER_SIZE; x<(ROUTER_SIZE*2*MESH_RADIX+ROUTER_SIZE); x+=ROUTER_SIZE*2) {

    int j=0;
    
    for (int y=ROUTER_SIZE; y<(ROUTER_SIZE*2*MESH_RADIX+ROUTER_SIZE); y+=ROUTER_SIZE*2) {
      
      int router_id = MESH_RADIX*i + j;;
      double colour = (mrouters[router_id]->total_load)/(8*0.16875); // degree of red

      //cout << i << "\t" << j << "\t" << router_id << endl;

      gtkw.setcolor(cr,colour,0,1-colour,2*colour+0.1);

      gtkw.fillrect(cr,x,y,x+ROUTER_SIZE,y+ROUTER_SIZE);
      
      j++;
    }

    i++;

  }

}

static void drawLinks(GtkWidget *widget, cairo_t *cr)
{

  gtkw.setlinewidth(cr, 6);
  
  map<int,Channel* >::iterator it;
  for (it = mchannels.begin(); it != mchannels.end(); ++it) {

    double colour = it->second->_colour;

    if (colour < 1)
      gtkw.setcolor(cr,colour,0,1-colour,2*colour+0.1);
    else
      gtkw.setcolor(cr,1,0,0,1);

    gtkw.drawline(cr,it->second->x_src,it->second->y_src,it->second->x_dst,it->second->y_dst);

  }

}

static void drawLegend(GtkWidget *widget, cairo_t *cr)
{
  gtkw.setlinewidth(cr, 6);

  //gtkw.setfontsize(cr, width/6);
  //gtkw.setfontface(cr,"sans-serif",CAIRO_FONT_SLANT_NORMAL,CAIRO_FONT_WEIGHT_NORMAL);

  int incr = 1;
  char lbl[10];

  for (double i = 0; i < 20/incr; i++) {

    gtkw.setcolor(cr,(i*incr)/20,0,1-((i*incr)/20),2*((i*incr)/20)+0.1);
    gtkw.drawline(cr,ROUTER_SIZE*(2*MESH_RADIX+1),((i*0.5)+3)*ROUTER_SIZE,ROUTER_SIZE*(2*MESH_RADIX+1.5),((i*0.5)+3)*ROUTER_SIZE);
    sprintf(lbl,"%d Gb/s",(int)i*incr);
    gtkw.setcolor(cr,0,0,0,1);
    gtkw.drawtext(cr,ROUTER_SIZE*(2*MESH_RADIX+1.6),((i*0.5)+3.07)*ROUTER_SIZE,lbl,ROUTER_SIZE);
    
  }

  gtkw.setcolor(cr,1,0,0,1);
  gtkw.drawline(cr,ROUTER_SIZE*(2*MESH_RADIX+1),(((20/incr)*0.5)+3)*ROUTER_SIZE,ROUTER_SIZE*(2*MESH_RADIX+1.5),(((20/incr)*0.5)+3)*ROUTER_SIZE);
  sprintf(lbl,">20 Gb/s");
  gtkw.setcolor(cr,0,0,0,1);
  gtkw.drawtext(cr,ROUTER_SIZE*(2*MESH_RADIX+1.6),(((20/incr)*0.5)+3.07)*ROUTER_SIZE,lbl,ROUTER_SIZE);  


}

void readMapping(char* filename) {

  ifstream ifile;

  // Determine link mapping
  ifile.open(filename);

  string reading;
  int router_id;
  
  while(ifile >> reading) {

    ifile >> router_id;

    Router* r = new Router(router_id);

    ifile >> reading >> reading; 
    // Output channels
    for (int i=0; i<4; i++) {

      ifile >> reading;
      //int chan_id = (int) *reading.rbegin();
      int chan_id = atoi(reading.substr(16,3).c_str());

      if (mchannels.count(chan_id) > 0) {
	// Channel already exists
	mchannels[chan_id]->src = router_id;
      }
      else {
	// Channel does not yet exist
	Channel* c = new Channel(chan_id);
	c->src = router_id;
	mchannels[chan_id] = c;
      }

    }

    ifile >> reading;
    ifile >> reading >> reading; 
    // Input channels
    for (int i=0; i<4; i++) {

      ifile >> reading;
      //int chan_id = (int) *reading.rbegin();
      int chan_id = atoi(reading.substr(16,3).c_str());
      
      (r->in_channels).push_back(chan_id);

      if (mchannels.count(chan_id) > 0) {
	// Channel already exists
	mchannels[chan_id]->dst = router_id;
      }
      else {
	// Channel does not yet exist
	Channel* c = new Channel(chan_id);
	c->dst = router_id;
	mchannels[chan_id] = c;
      }

    }

    mrouters[router_id] = r;

    ifile >> reading;

  }
  
  ifile.close();

  /*
  // Debug
  map<int,Channel* >::iterator it;
  for (it = mchannels.begin(); it != mchannels.end(); ++it) {
    cout << it->second->_id << "\t" << it->second->src << "\t" << it->second->dst << endl;
  }
  */

}

void readUtilization(char* filename) {

  ifstream ifile;

  ifile.open(filename);

  string reading;
  
  while(ifile >> reading) {

    int chan_id = atoi(reading.substr(16,3).c_str());
    double load;
    ifile >> load;

    mchannels[chan_id]->setLoad(load);

  }

  // Determine total load into each router
  map<int,Router* >::iterator it2;
  for (it2 = mrouters.begin(); it2 != mrouters.end(); ++it2) {
    vector<int>::iterator it3;
    for (it3 = (it2->second)->in_channels.begin(); it3 != (it2->second)->in_channels.end(); ++it3) {
      it2->second->total_load += mchannels[*it3]->_load;
    }
  }

  ifile.close();

  /*
  // Debug
  map<int,Channel* >::iterator it;
  for (it = mchannels.begin(); it != mchannels.end(); ++it) {
    cout << it->second->_id << "\t" << it->second->src << "\t" << it->second->dst << "\t" << it->second->x_src << "->" << it->second->x_dst << "\t" << it->second->y_src << "->" << it->second->y_dst << endl;
  }
  */
  

}
