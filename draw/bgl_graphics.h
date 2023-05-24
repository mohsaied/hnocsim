/************************************************************************
 BridgeGL is an easy-to-use 2D graphics package powered by cairo and GTK+.
Copyright (c) 2013 Sandeep Chatterjee [chatte45@eecg.utoronto.ca]

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.


You should have received a copy of the GNU General Public License
along with this program. If not, get it here: "http://www.gnu.org/licenses/".
*************************************************************************/

#ifndef _BGL_GRAPHICS_H_
#define _BGL_GRAPHICS_H_

#include <gtk/gtk.h>
#include <cairo.h>
#include <cairo-pdf.h>
#include <cairo-ps.h>
#include <cairo-svg.h>
#include <math.h>
#include <gdk/gdkkeysyms.h>
#include <string>
#include <vector>
#include <stdio.h>
#include <stdlib.h>

#ifndef max
#define max(a,b) (((a) > (b))? (a) : (b))
#endif
#ifndef min
#define min(a,b) ((a) > (b)? (b) : (a))
#endif

//#define DEBUG
#define BOUNDING_BOX
#define STYLE_BUTTONS
//#define FOLLOW_MOUSE_POINTER
//#define VIRTUAL_SCROLLBARS
#define SCALE_TEXT 

#define MAX_ZOOM 5
#define MAX_TRANSLATE 50 

using namespace std;

typedef void (*draw_gtk)(GtkWidget *widget, cairo_t *cr);
typedef void (*button_fcn)(GtkWidget *widget, gpointer data);
typedef void (*user_key_press_fcn)( GdkEventKey *event );
typedef void (*user_mouse_pointer_position_fcn)( GdkEventMotion *event );
typedef void (*user_mouse_button_press_fcn)( GdkEventButton *event );
typedef void (*get_image_map_text)(double x, double y, vector<string>* arr);

enum file_extension{
	PDF,
	PNG,
	SVG,
	PS
};


class style_button;
class image_map;

class gtk_win
{
	public:
	cairo_surface_t* cs;
	cairo_t* cr;
	cairo_pattern_t *radpat, *linpat;
	
	GtkWidget *mainwin;		// the new windows 
	GtkWidget *canvas;		// a new canvas
	GtkWidget *hbox;		// 
	GtkWidget *vbox;		// 
	GtkWidget *button_vbox;
	GtkWidget *console;		// the console window to input commands
	GtkWidget *statusbar;
	vector<style_button*> sidepane_buttons;
	
	GtkWidget *vseparator, *hseparator1, *hseparator2;
	
	int win_current_width, win_current_height;
	int canvas_width, canvas_height;
	int stbar_height, sdp_width, toolbar_height;
	draw_gtk drawscreen;
	double tx, ty, scale;		//as of now are dummy variables, serve no special purpose
	double xleft, xright, ytop, ybottom;
	double saved_xleft, saved_xright, saved_ytop, saved_ybottom;
	double xmult, ymult;
	double angle, user_tx, user_ty;
	
	bool window_zoom_mode_on, in_window_zoom_mode;
	double z_xleft, z_xright, z_ytop, z_ybottom;
	int worldx, worldy;
	double zoom_in_factor, zoom_out_factor;
	double scroll_zoom_in_multiplier, scroll_zoom_out_multiplier;
	double translate_u_factor, translate_d_factor, translate_l_factor, translate_r_factor;
	
	GtkWidget *toolbar;
	GtkToolItem *save;
	GtkToolItem *help;
	GtkToolItem *preferences;
	GtkToolItem *zoom_in;
	GtkToolItem *zoom_out;
	GtkToolItem *zoom_fit;
	GtkToolItem *refresh;
	GtkToolItem *exit;
	
	user_key_press_fcn user_key_press_method;
	bool user_key_press_active;
	user_mouse_pointer_position_fcn user_mouse_pos_method;
	bool user_mouse_position_active;
	user_mouse_button_press_fcn user_mouse_button_press_method;
	bool user_mouse_press_active;
	
	gtk_win( draw_gtk _drawscreen, int onset_width, int onset_height );

	void init_world( double x1, double y1, double x2, double y2 );

	void init_graphics( char* windowtitle );

	void redraw();
	
	void focus_on_area( double _xleft, double _ytop, double _xright, 
		                double _ybottom );
	void focus();
	void restore_to_onset_view();
	
	void translate_up();
	void translate_down();
	void translate_left();
	void translate_right();
	
	bool rect_off_screen( cairo_t* cr, double x1, double y1, double x2, double y2 );
	void update_transform();
	
	double user2win_x( double user_x );
	double user2win_y( double user_y );
	double win2user_x( double world_x );
	double win2user_y( double world_y );
	void translate_coordinates( cairo_t* cr, double _tx, double _ty );
	
	//functions for UI display
	void update_statusbar_msg();
	void draw_virtual_scrollbars();

	// The drawing functions: aids in drawing, could have been written
	// in a way that the cairo contetx need not be passed everytime, but
	// would have involved a lot of extra coding to ensure
	// consistency.
	void clearscreen(cairo_t* cr);
	void setbgcolor(cairo_t*cr, double red, double green, double blue);
	void setcolor(cairo_t* cr, double red, double green, double blue, double alpha);
	void setradialgradient(cairo_t* cr, double cx0, double cy0, double r0, double cx1, double cy1, double r1);
	void setlineargradient(cairo_t* cr, double cx0, double cy0, double cx1, double cy1);
	void setlinestyle(cairo_t* cr, int linestyle);
	void setlinestyle(cairo_t* cr, int linestyle, double *dashes);
	void setlinewidth(cairo_t* cr, double linewidth);
	void drawline(cairo_t* cr, double x1, double y1, double x2, double y2);
	void setfontsize(cairo_t* cr,int pointsize);
	void setfontface( cairo_t* cr, char* fontface, cairo_font_slant_t slant, cairo_font_weight_t weight);
	void drawtext(cairo_t* cr, double xc, double yc, char *text, double boundx);
	void drawarc(cairo_t* cr, double xcen, double ycen, double rad, double startang, double angextent);
	void fillarc(cairo_t* cr, double xcen, double ycen, double rad, double startang, double angextent);
	void drawellipticarc(cairo_t* cr, double xcen, double ycen, double radx, double rady, double startang, double angextent);
	void fillellipticarc(cairo_t* cr, double xcen, double ycen, double radx, double rady, double startang, double angextent);
	void drawrect(cairo_t* cr, double x1, double y1, double x2, double y2);
	void fillrect(cairo_t* cr, double x1, double y1, double x2, double y2);
	void drawpolygon(cairo_t* cr, vector<double> &x, vector<double> &y);
	void fillpolygon(cairo_t* cr, vector<double> &x, vector<double> &y);	
	bool drawpolypath(cairo_t* cr, vector<double> &x, vector<double> &y);
	void drawroundedrect(cairo_t* cr, double x1, double y1, double x2, double y2, double xarc, double yarc);
	void fillroundedrect(cairo_t* cr, double x1, double y1, double x2, double y2, double xarc, double yarc);
	bool drawroundedrectpath(cairo_t* cr, double x1, double y1, double x2, double y2, double xarc, double yarc);
	void drawtextballoon(cairo_t* cr, double user_x1, double user_y1,  double tolerance, vector<string>* arr, int fontsize, 
	                     char* fontface, double *rgb_border, double *rgba_fill,  double *rgb_text);
	
	// functions for saving in a particular format
	file_extension type;
	void save_as();
	void save_as_pdf( char* filename, bool appendtype );
	void save_as_png( char* filename, bool appendtype );
	void save_as_svg( char* filename, bool appendtype );
	void save_as_ps ( char* filename, bool appendtype );
	
	// functions for activating user inputs for mouse motion, mouse button press and keyboard press
	void activate_user_key_press_input( user_key_press_fcn method );
	void deactivate_user_key_press_input();
	void activate_user_mouse_pointer_position_input( user_mouse_pointer_position_fcn method );
	void deactivate_user_mouse_pointer_position_input();
	void activate_user_mouse_button_press_input( user_mouse_button_press_fcn method );
	void deactivate_user_mouse_button_press_input();
	
	// utility functions
	void line2arr (char* str, vector<string>* arr);
};

class style_button
{
	public:
	GtkWidget *button;	
	GtkWidget *button_label;
	string button_text;
	button_fcn act_on_button_press;
	gtk_win *application;
	string desc;
	
	style_button( string _button_text, button_fcn _act_on_button_press, gtk_win *_application );
	
	void set_desc(string _desc);
};

class image_map
{
	public:
	double x;
	double y;
	double tolerance;
};

#endif

