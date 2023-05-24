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


#include "bgl_graphics.h"
#include <math.h>
#include <string.h>


static gboolean mainwin_expose (GtkWidget *widget, GdkEventExpose *event, gpointer data)
{
	cairo_t *cr;
	gtk_win* g_win = (gtk_win*) data;
	
	// get a cairo_t
	cr = gdk_cairo_create (widget->window);
	g_win->cr = cr;
	
	// set a clip region for the expose event 
	cairo_rectangle (cr, event->area.x, event->area.y,  event->area.width, event->area.height);
	
	cairo_clip (cr);
	
	//cairo_set_source_rgb(cr, 0, 0, 0);
	cairo_pattern_t *linpat;
	linpat = cairo_pattern_create_linear (0, 0, 600, 600);
	cairo_pattern_add_color_stop_rgb (linpat, 1,  0, 0, 0);
	cairo_pattern_add_color_stop_rgb (linpat, 0.2,  0.5, 0.5, 0.5);
	cairo_set_source (cr, linpat);
	cairo_paint(cr);

	cairo_destroy (cr);

	return FALSE;
}

static gboolean canvas_expose (GtkWidget *widget, GdkEventExpose *event, gpointer data)
{
	cairo_t *cr;
	gtk_win* g_win = (gtk_win*) data;
	
	// get a cairo_t
	cr = gdk_cairo_create (widget->window);
	
	// set a clip region for the expose event 
	cairo_rectangle (cr, event->area.x, event->area.y,  event->area.width, event->area.height);
	cairo_clip (cr);
	
	cairo_save(cr);
	cairo_identity_matrix(cr);
	g_win->user_tx = 0; g_win->user_ty = 0;
	g_win->drawscreen (widget, cr);
	cairo_restore(cr);
	
	if (g_win->in_window_zoom_mode)
	{
		cairo_set_source_rgba(cr, 0.882353, 0.67843, 0.12549, 0.4);
		g_win->fillrect( cr, g_win->z_xleft, g_win->z_ytop, g_win->z_xright, g_win->z_ybottom);
		cairo_set_source_rgb(cr, 0.70980, 0.572549, 0.207843);
		cairo_set_line_width(cr, 2);
		g_win->drawrect( cr, g_win->z_xleft, g_win->z_ytop, g_win->z_xright, g_win->z_ybottom);
	}
	#ifdef BOUNDING_BOX
		cairo_save (cr);
		cairo_set_operator(cr, CAIRO_OPERATOR_XOR); 
		cairo_set_source_rgb(cr, 0, 0, 0);
		cairo_set_line_width(cr, 2);
		cairo_move_to(cr, g_win->user2win_x(g_win->saved_xleft),  g_win->user2win_y(g_win->saved_ytop) );
		cairo_line_to(cr, g_win->user2win_x(g_win->saved_xleft),  g_win->user2win_y(g_win->saved_ybottom) );
		cairo_line_to(cr, g_win->user2win_x(g_win->saved_xright), g_win->user2win_y(g_win->saved_ybottom) );
		cairo_line_to(cr, g_win->user2win_x(g_win->saved_xright), g_win->user2win_y(g_win->saved_ytop) );
		cairo_line_to(cr, g_win->user2win_x(g_win->saved_xleft),  g_win->user2win_y(g_win->saved_ytop) );
		cairo_stroke(cr);
		cairo_restore (cr);
	#endif
	
	#ifdef VIRTUAL_SCROLLBARS
		g_win->draw_virtual_scrollbars();
	#endif
	cairo_destroy (cr);

	return FALSE;
}

static void gtk_win_scroll(GtkWidget *widget, GdkEventScroll* event, gpointer data)
{
	gtk_win* g_win = (gtk_win*) data;
	double userx = g_win->win2user_x(event->x);
	double usery = g_win->win2user_y(event->y);
	
	double x_left_margin   = userx - g_win->xleft;
	double x_right_margin  = g_win->xright - userx;
	double y_top_margin    = usery - g_win->ytop;
	double y_bottom_margin = g_win->ybottom - usery;
	
	if ( event->direction == GDK_SCROLL_UP )
	{
		g_win->xleft   += x_left_margin*g_win->scroll_zoom_in_multiplier;
		g_win->xright  -= x_right_margin*g_win->scroll_zoom_in_multiplier; 
		g_win->ytop    += y_top_margin*g_win->scroll_zoom_in_multiplier; 
		g_win->ybottom -= y_bottom_margin*g_win->scroll_zoom_in_multiplier; 
	}
	else if ( event->direction == GDK_SCROLL_DOWN )
	{
		g_win->xleft   -= x_left_margin*g_win->scroll_zoom_out_multiplier;
		g_win->xright  += x_right_margin*g_win->scroll_zoom_out_multiplier; 
		g_win->ytop    -= y_top_margin*g_win->scroll_zoom_out_multiplier;
		g_win->ybottom += y_bottom_margin*g_win->scroll_zoom_out_multiplier;
	}
	
	g_win->update_statusbar_msg();
	g_win->focus();
}

static gboolean gtk_mainwin_configure (GtkWidget *widget, GdkEventConfigure *event, gpointer data)
{
	gtk_win* g_win = (gtk_win*) data;
	g_win->win_current_width = event->width;
	g_win->win_current_height = event->height;

	return FALSE;
}

static gboolean gtk_canvas_configure (GtkWidget *widget, GdkEventConfigure *event, gpointer data)
{
	gtk_win* g_win = (gtk_win*) data;
	g_win->canvas_width = event->width;
	g_win->canvas_height = event->height;
	g_win->update_transform();

	return FALSE;
}

static gboolean act_on_key_press (GtkWidget *widget, GdkEventKey *event,  gpointer data)
{
	gtk_win* g_win = (gtk_win*) data;
	
	switch (event->keyval)
	{		
		case GDK_s:
		if (event->state & GDK_CONTROL_MASK)
		{
			g_win->save_as();
		}
		break;
		
		case GDK_Escape:
		g_win->restore_to_onset_view();
		break;
		
		case GDK_Up:
		g_win->translate_up();
		break;
		
		case GDK_Down:
		g_win->translate_down();
		break;
		
		case GDK_Left:
		g_win->translate_left();
		break;
		
		case GDK_Right:
		g_win->translate_right();
		break;
		
		case GDK_r:
		g_win->redraw();
		break;
		
		default:
		break;
	}
	g_win->update_statusbar_msg();
	
	if (g_win->user_key_press_active)
	{
		g_win->user_key_press_method(event);
	}
	
	return FALSE; 
}

static void file_type_selected(GtkWidget *widget, gpointer data)
{
	gtk_win* g_win = (gtk_win*)data;
	gchar *active_text =  gtk_combo_box_get_active_text(GTK_COMBO_BOX(widget));
	
	if ( g_strcmp0 (active_text, "PDF") == 0 )
		g_win->type = PDF;
	else if ( g_strcmp0 (active_text, "PNG") == 0 )
		g_win->type = PNG;
	else if ( g_strcmp0 (active_text, "SVG") == 0 )
		g_win->type = SVG;
	else if ( g_strcmp0 (active_text, "PS") == 0 )
		g_win->type = PS;
}

static gboolean mouse_position_tracker(GtkWidget *widget, GdkEventMotion *event, gpointer data)
{	
	gtk_win* g_win = (gtk_win*) data;
	
	#ifdef FOLLOW_MOUSE_POINTER
		GdkModifierType state;

		if (event->is_hint)
			gdk_window_get_pointer (event->window, &g_win->worldx, &g_win->worldy, &state);
		else
		{
			g_win->worldx = event->x;
			g_win->worldy = event->y;
		}

		g_win->update_statusbar_msg();
	#endif
	
	if (g_win->in_window_zoom_mode)
	{
		#ifndef FOLLOW_MOUSE_POINTER
			GdkModifierType state;

			if (event->is_hint)
				gdk_window_get_pointer (event->window, &g_win->worldx, &g_win->worldy, &state);
			else
			{
				g_win->worldx = event->x;
				g_win->worldy = event->y;
			}

			g_win->update_statusbar_msg();
		#endif
		
		g_win->z_xright  = g_win->win2user_x( event->x );
		g_win->z_ybottom = g_win->win2user_y( event->y );
		gtk_widget_queue_draw_area ( g_win->canvas,  g_win->tx, g_win->ty, 
		                             g_win->canvas_width, g_win->canvas_height);
	}
	
	if (g_win->user_mouse_position_active)
	{
		g_win->user_mouse_pos_method(event);
	}
	
	return TRUE;
}

static gboolean window_zoom(GtkWidget *widget, GdkEventButton *event, gpointer data)
{
	gtk_win* g_win = (gtk_win*) data;
	double x, y;
	g_win->worldx = event->x;
	g_win->worldy = event->y;
	x = g_win->win2user_x( event->x ); 
	y = g_win->win2user_y( event->y );
	
	if ( event->type == GDK_BUTTON_PRESS && g_win->window_zoom_mode_on ) 
	{
		g_win->in_window_zoom_mode = true;
		g_win->z_xleft = x;
		g_win->z_ytop  = y;
	}
	else if ( event->type == GDK_BUTTON_RELEASE && g_win->window_zoom_mode_on)
	{
		g_win->window_zoom_mode_on = false;
		g_win->in_window_zoom_mode = false;
		g_win->z_xright  = x;
		g_win->z_ybottom = y;
		g_win->xleft   = ((g_win->z_xleft < g_win->z_xright)?g_win->z_xleft:g_win->z_xright);
		g_win->xright  = ((g_win->z_xleft > g_win->z_xright)?g_win->z_xleft:g_win->z_xright); 
		g_win->ytop    = ((g_win->z_ytop < g_win->z_ybottom)?g_win->z_ytop:g_win->z_ybottom);
		g_win->ybottom = ((g_win->z_ytop > g_win->z_ybottom)?g_win->z_ytop:g_win->z_ybottom);
		g_win->focus();
	}
	g_win->update_statusbar_msg();
	
	if (g_win->user_mouse_press_active && event->type == GDK_BUTTON_PRESS)
	{
		g_win->user_mouse_button_press_method(event);
	}
	
	return FALSE;
}

static void turn_on_window_zoom_mode(GtkWidget *widget, gpointer data)
{
	style_button* sbutton = (style_button*) data;
	sbutton->application->window_zoom_mode_on = true;
	sbutton->application->update_statusbar_msg();
}
static void save_as_fcn(GtkWidget *widget, gpointer data)
{
	gtk_win* g_win = (gtk_win*) data;
	g_win->save_as();
}

static void zoom_in_fcn(GtkWidget *widget, gpointer data)
{
	gtk_win* g_win = (gtk_win*) data;

	double xdiff, ydiff;
	xdiff = g_win->xright  - g_win->xleft; 
	ydiff = g_win->ybottom - g_win->ytop;
	g_win->xleft   += xdiff/g_win->zoom_in_factor;
	g_win->xright  -= xdiff/g_win->zoom_in_factor;
	g_win->ytop    += ydiff/g_win->zoom_in_factor;
	g_win->ybottom -= ydiff/g_win->zoom_in_factor;
	
	g_win->focus();
	g_win->update_statusbar_msg();
}
static void zoom_out_fcn(GtkWidget *widget, gpointer data)
{
	gtk_win* g_win = (gtk_win*) data;
	
	double xdiff, ydiff;
	xdiff = g_win->xright  - g_win->xleft; 
	ydiff = g_win->ybottom - g_win->ytop;
	g_win->xleft   -= xdiff/g_win->zoom_out_factor;
	g_win->xright  += xdiff/g_win->zoom_out_factor;
	g_win->ytop    -= ydiff/g_win->zoom_out_factor;
	g_win->ybottom += ydiff/g_win->zoom_out_factor;
	
	g_win->focus();
	g_win->update_statusbar_msg();
}
static void zoom_fit_fcn(GtkWidget *widget, gpointer data)
{
	gtk_win* g_win = (gtk_win*) data;
	g_win->restore_to_onset_view();
}
static void refresh_drawing_area(GtkWidget *widget, gpointer data)
{
	gtk_win* g_win = (gtk_win*) data;
	g_win->redraw();
}

static void enter_button(GtkWidget *widget, gpointer data) 
{
	style_button* s_button = (style_button*) data;
	string markup = "<span face=\"Arial\" style=\"normal\" color=\"#ffffff\" bgcolor=\"#f07300\" size=\"x-large\"><b>"
	                + s_button->button_text + "</b></span>";
	gtk_label_set_markup ( GTK_LABEL ( s_button->button_label ), markup.c_str() );
	
	#ifndef FOLLOW_MOUSE_POINTER
		char status[150];
		sprintf(status, "Button name: %s, why is it there? %s", s_button->button_text.c_str(), s_button->desc.substr(0,120).c_str() );
		gtk_statusbar_push( GTK_STATUSBAR(s_button->application->statusbar), 
				    gtk_statusbar_get_context_id( GTK_STATUSBAR(s_button->application->statusbar), status), status );
	#endif
}
static void leave_button(GtkWidget *widget, gpointer data) 
{ 
	style_button* s_button = (style_button*) data;
	string markup = "<span face=\"Arial\" style=\"normal\" color=\"#ffffff\" bgcolor=\"#528ae1\" size=\"x-large\">"
	                + s_button->button_text + "</span>";
	gtk_label_set_markup ( GTK_LABEL ( s_button->button_label ), markup.c_str() );
}

void gtk_win::activate_user_key_press_input( user_key_press_fcn method )
{
	user_key_press_active = true;
	user_key_press_method = method;
}
void gtk_win::deactivate_user_key_press_input( )
{
	user_key_press_active = false;
	user_key_press_method = NULL;
}
void gtk_win::activate_user_mouse_pointer_position_input( user_mouse_pointer_position_fcn method )
{
	user_mouse_position_active = true;
	user_mouse_pos_method = method;
}
void gtk_win::deactivate_user_mouse_pointer_position_input()
{
	user_mouse_position_active = false;
	user_mouse_pos_method = NULL;
}
void gtk_win::activate_user_mouse_button_press_input( user_mouse_button_press_fcn method )
{
	user_mouse_press_active = true;
	user_mouse_button_press_method = method;
}
void gtk_win::deactivate_user_mouse_button_press_input()
{
	user_mouse_press_active = false;
	user_mouse_button_press_method = NULL;
}

static void about_dialouge( GtkWidget *widget, GtkWidget *window )
{
	GdkPixbuf *pixbuf = gdk_pixbuf_new_from_file("logo.png", NULL);

	GtkWidget *dialog = gtk_about_dialog_new();
	gtk_about_dialog_set_name(GTK_ABOUT_DIALOG(dialog), "BridgeGL");
	gtk_about_dialog_set_version(GTK_ABOUT_DIALOG(dialog), "1.0"); 
	gtk_about_dialog_set_copyright(GTK_ABOUT_DIALOG(dialog), 
	"(c) Sandeep Chatterjee [chatte45@eecg.utoronto.ca]");
	gtk_about_dialog_set_comments(GTK_ABOUT_DIALOG(dialog), 
	"An easy-to-use 2D graphics package powered by Cairo ang GTK+, released under GNU license");
	gtk_about_dialog_set_website(GTK_ABOUT_DIALOG(dialog), 
	"http://www.eecg.utoronto.ca/~chatte45/doc/index.html");
	gtk_about_dialog_set_logo(GTK_ABOUT_DIALOG(dialog), pixbuf);
	g_object_unref(pixbuf), pixbuf = NULL;
	gtk_dialog_run(GTK_DIALOG (dialog));
	gtk_widget_destroy(dialog);
}

static void change_zoom_in_factor(GtkWidget *widget, gpointer data)
{
	gtk_win* g_win = (gtk_win*)data;
	string str( gtk_combo_box_get_active_text(GTK_COMBO_BOX(widget)) );
		
	double n = atof(str.substr(0, str.length()-1).c_str() );
	g_win->zoom_in_factor = 2*n/(n-1);
	
	char status[40];
	sprintf(status, "Set toolbar Zoom-in factor as %s", str.c_str() );
	gtk_statusbar_push( GTK_STATUSBAR(g_win->statusbar), 
		            gtk_statusbar_get_context_id( GTK_STATUSBAR(g_win->statusbar), status), status );
}
static void change_zoom_out_factor(GtkWidget *widget, gpointer data)
{
	gtk_win* g_win = (gtk_win*)data;
	string str( gtk_combo_box_get_active_text(GTK_COMBO_BOX(widget)) );
	
	double n = atof(str.substr(0, str.length()-1).c_str() );
	g_win->zoom_out_factor = 2*n/(1-n);
	
	char status[40];
	sprintf(status, "Set toolbar Zoom-out factor as %s", str.c_str() );
	gtk_statusbar_push( GTK_STATUSBAR(g_win->statusbar), 
		            gtk_statusbar_get_context_id( GTK_STATUSBAR(g_win->statusbar), status), status );
}
static void change_scroll_in_factor(GtkWidget *widget, gpointer data)
{
	gtk_win* g_win = (gtk_win*)data;
	string str( gtk_combo_box_get_active_text(GTK_COMBO_BOX(widget)) );
	
	double n = atof(str.substr(0, str.length()-1).c_str() );
	g_win->scroll_zoom_in_multiplier = (n-1)/n;
	
	char status[40];
	sprintf(status, "Set Scroll Zoom-in factor as %s", str.c_str() );
	gtk_statusbar_push( GTK_STATUSBAR(g_win->statusbar), 
		            gtk_statusbar_get_context_id( GTK_STATUSBAR(g_win->statusbar), status), status );
}
static void change_scroll_out_factor(GtkWidget *widget, gpointer data)
{
	gtk_win* g_win = (gtk_win*)data;
	string str( gtk_combo_box_get_active_text(GTK_COMBO_BOX(widget)) );
	
	double n = atof(str.substr(0, str.length()-1).c_str() );
	g_win->scroll_zoom_out_multiplier = (1-n)/n;
	
	char status[40];
	sprintf(status, "Set Scroll Zoom-out factor as %s", str.c_str() );
	gtk_statusbar_push( GTK_STATUSBAR(g_win->statusbar), 
		            gtk_statusbar_get_context_id( GTK_STATUSBAR(g_win->statusbar), status), status );
}
static void change_translate_u_factor(GtkWidget *widget, gpointer data)
{
	gtk_win* g_win = (gtk_win*)data;
	string str( gtk_combo_box_get_active_text(GTK_COMBO_BOX(widget)) );
	
	double n = atof(str.substr(0, str.length()-1).c_str() );
	g_win->translate_u_factor = 100.0/n;
	
	char status[40];
	sprintf(status, "Set Viewport Translate-Up as %s", str.c_str() );
	gtk_statusbar_push( GTK_STATUSBAR(g_win->statusbar), 
		            gtk_statusbar_get_context_id( GTK_STATUSBAR(g_win->statusbar), status), status );
}
static void change_translate_d_factor(GtkWidget *widget, gpointer data)
{
	gtk_win* g_win = (gtk_win*)data;
	string str( gtk_combo_box_get_active_text(GTK_COMBO_BOX(widget)) );
	
	double n = atof(str.substr(0, str.length()-1).c_str() );
	g_win->translate_d_factor = 100.0/n;
	
	char status[40];
	sprintf(status, "Set Viewport Translate-Down as %s", str.c_str() );
	gtk_statusbar_push( GTK_STATUSBAR(g_win->statusbar), 
		            gtk_statusbar_get_context_id( GTK_STATUSBAR(g_win->statusbar), status), status );
}
static void change_translate_l_factor(GtkWidget *widget, gpointer data)
{
	gtk_win* g_win = (gtk_win*)data;
	string str( gtk_combo_box_get_active_text(GTK_COMBO_BOX(widget)) );
	
	double n = atof(str.substr(0, str.length()-1).c_str() );
	g_win->translate_l_factor = 100.0/n;
	
	char status[40];
	sprintf(status, "Set Viewport Translate-Left as %s", str.c_str() );
	gtk_statusbar_push( GTK_STATUSBAR(g_win->statusbar), 
		            gtk_statusbar_get_context_id( GTK_STATUSBAR(g_win->statusbar), status), status );
}
static void change_translate_r_factor(GtkWidget *widget, gpointer data)
{
	gtk_win* g_win = (gtk_win*)data;
	string str( gtk_combo_box_get_active_text(GTK_COMBO_BOX(widget)) );
	
	double n = atof(str.substr(0, str.length()-1).c_str() );
	g_win->translate_r_factor = 100.0/n;
	
	char status[40];
	sprintf(status, "Set Viewport Translate-Right as %s", str.c_str() );
	gtk_statusbar_push( GTK_STATUSBAR(g_win->statusbar), 
		            gtk_statusbar_get_context_id( GTK_STATUSBAR(g_win->statusbar), status), status );
}

static void preference_dialouge( GtkWidget *widget, gpointer data )
{
	gtk_win* g_win = (gtk_win*) data;
	
	GtkWidget *dialog, *content_area;
	GtkWidget *table, *scroll_table, *translate_table;
	GtkWidget *hsep1, *hsep2, *hsep3;
	
	GtkWidget *zoom_frame;
	GtkWidget *zoom_in_label, *zoom_in_combo, *zoom_in_info_label;
	GtkWidget *zoom_out_label, *zoom_out_combo, *zoom_out_info_label;
	
	GtkWidget *scroll_frame;
	GtkWidget *scroll_in_label, *scroll_in_combo, *scroll_in_info_label;
	GtkWidget *scroll_out_label, *scroll_out_combo, *scroll_out_info_label;
	
	GtkWidget *translate_frame;
	GtkWidget *translate_u_label, *translate_u_combo, *translate_u_info_label;
	GtkWidget *translate_d_label, *translate_d_combo, *translate_d_info_label;
	GtkWidget *translate_l_label, *translate_l_combo, *translate_l_info_label;
	GtkWidget *translate_r_label, *translate_r_combo, *translate_r_info_label;
	 
	char str[20];
	double current_setting;

	/* Create the widgets */
  	dialog = gtk_dialog_new_with_buttons ("Preferences",
                                         GTK_WINDOW(g_win->mainwin),
                                         GTK_DIALOG_MODAL, GTK_STOCK_CLOSE,
                                         GTK_RESPONSE_NONE,
                                         NULL);
        
        content_area = gtk_dialog_get_content_area (GTK_DIALOG (dialog));
        
        /* TOOLBAR PREFERNCES */
        //IN
        zoom_in_label = gtk_label_new( " Zoom in by:" );
        gtk_label_set_width_chars (GTK_LABEL(zoom_in_label), 20);
        char zoom_in_info[50];
        sprintf(zoom_in_info, "Current Setting: %.2fX", g_win->zoom_in_factor/(g_win->zoom_in_factor-2) );
        zoom_in_info_label = gtk_label_new(zoom_in_info);
        zoom_in_combo = gtk_combo_box_new_text();
	for ( double i = 0.96; i >= 1.0/(MAX_ZOOM+0.05); i = i-0.04 )
	{
		sprintf( str,  "%.2fX", 1/i); 
		gtk_combo_box_append_text(GTK_COMBO_BOX(zoom_in_combo), str);
	}
	gtk_combo_box_set_active (GTK_COMBO_BOX(zoom_in_combo), 0);
	g_signal_connect(G_OBJECT(zoom_in_combo), "changed", G_CALLBACK(change_zoom_in_factor), (gpointer)g_win);
        
        //OUT
        zoom_out_label = gtk_label_new( "Zoom out by:" );
        gtk_label_set_width_chars (GTK_LABEL(zoom_out_label), 20);
        char zoom_out_info[50];
        sprintf(zoom_out_info, "Current Setting: %.2fX", g_win->zoom_out_factor/(g_win->zoom_out_factor+2) );
        zoom_out_info_label = gtk_label_new(zoom_out_info);
        zoom_out_combo = gtk_combo_box_new_text();
	for ( double i = 0.96; i >= 1.0/(MAX_ZOOM+0.05); i = i-0.04 )
	{
		sprintf( str,  "%.2fX", i);
		gtk_combo_box_append_text(GTK_COMBO_BOX(zoom_out_combo), str);
	}
	gtk_combo_box_set_active (GTK_COMBO_BOX(zoom_out_combo), 0);
	g_signal_connect(G_OBJECT(zoom_out_combo), "changed", G_CALLBACK(change_zoom_out_factor), (gpointer)g_win);
	
	table = gtk_table_new(2, 3, 0);
	zoom_frame = gtk_frame_new( "Toolbar Zoom options" );
	gtk_table_attach( GTK_TABLE(table), zoom_in_label, 0, 1, 0, 1, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(table), zoom_in_combo, 1, 2, 0, 1, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(table), zoom_in_info_label, 2, 3, 0, 1, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(table), zoom_out_label, 0, 1, 1, 2,GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(table), zoom_out_combo, 1, 2, 1, 2,GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(table), zoom_out_info_label, 2, 3, 1, 2, GTK_FILL, GTK_FILL, 5, 5 );
	
	gtk_container_add(GTK_CONTAINER (zoom_frame), table);
	gtk_container_add(GTK_CONTAINER (content_area), zoom_frame);
	hsep1 = gtk_hseparator_new();
	gtk_container_add(GTK_CONTAINER (content_area), hsep1);
	
	/* SCROLL ZOOM PREFERNCES */
	//IN
	scroll_in_label = gtk_label_new( " Zoom in by:" );
	gtk_label_set_width_chars (GTK_LABEL(scroll_in_label), 20);
	char scroll_in_info[50];
        sprintf(scroll_in_info, "Current Setting: %.2fX", 1/(1 - g_win->scroll_zoom_in_multiplier) );
        scroll_in_info_label = gtk_label_new(scroll_in_info);
        
        scroll_in_combo = gtk_combo_box_new_text();
	for ( double i = 0.96; i >= 1.0/(MAX_ZOOM+0.05); i = i-0.04 )
	{
		sprintf( str,  "%.2fX", 1/i); 
		gtk_combo_box_append_text(GTK_COMBO_BOX(scroll_in_combo), str);
	}
	gtk_combo_box_set_active (GTK_COMBO_BOX(scroll_in_combo), 0);
	g_signal_connect(G_OBJECT(scroll_in_combo), "changed", G_CALLBACK(change_scroll_in_factor), (gpointer)g_win);
        
        //OUT
        scroll_out_label = gtk_label_new( "Zoom out by:" );
        gtk_label_set_width_chars (GTK_LABEL(scroll_out_label), 20);
        char scroll_out_info[50];
        sprintf(scroll_out_info, "Current Setting: %.2fX", 1/(1+g_win->scroll_zoom_out_multiplier) );
        scroll_out_info_label = gtk_label_new(scroll_out_info);
        
        scroll_out_combo = gtk_combo_box_new_text();
	for ( double i = 0.96; i >= 1.0/(MAX_ZOOM+0.05); i = i-0.04 )
	{
		sprintf( str,  "%.2fX", i);
		gtk_combo_box_append_text(GTK_COMBO_BOX(scroll_out_combo), str);
	}
	gtk_combo_box_set_active (GTK_COMBO_BOX(scroll_out_combo), 0);
	g_signal_connect(G_OBJECT(scroll_out_combo), "changed", G_CALLBACK(change_scroll_out_factor), (gpointer)g_win);
	
	scroll_table = gtk_table_new(2, 3, 0);
	scroll_frame = gtk_frame_new( "Scroll Zoom options" );
	gtk_table_attach( GTK_TABLE(scroll_table), scroll_in_label, 0, 1, 0, 1, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(scroll_table), scroll_in_combo, 1, 2, 0, 1, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(scroll_table), scroll_in_info_label, 2, 3, 0, 1, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(scroll_table), scroll_out_label, 0, 1, 1, 2,GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(scroll_table), scroll_out_combo, 1, 2, 1, 2,GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(scroll_table), scroll_out_info_label, 2, 3, 1, 2, GTK_FILL, GTK_FILL, 5, 5 );
	
	gtk_container_add(GTK_CONTAINER (scroll_frame), scroll_table);
	gtk_container_add(GTK_CONTAINER (content_area), scroll_frame);
	hsep2 = gtk_hseparator_new();
	gtk_container_add(GTK_CONTAINER (content_area), hsep2);
	
	/* TRANSLATE PREFERNCES */
	//UP
	translate_u_label = gtk_label_new( "Translate Up by:" );
	gtk_label_set_width_chars (GTK_LABEL(translate_u_label), 20);
	char translate_u_info[50];
        sprintf(translate_u_info, "Current Setting: %.2f%%", 100/g_win->translate_u_factor );
        translate_u_info_label = gtk_label_new(translate_u_info);
        translate_u_combo = gtk_combo_box_new_text();
	for ( int i = 5; i <= MAX_TRANSLATE; i=i+5 )
	{
		sprintf( str,  "%d%%", i); 
		gtk_combo_box_append_text(GTK_COMBO_BOX(translate_u_combo), str);
	}
	gtk_combo_box_set_active (GTK_COMBO_BOX(translate_u_combo), 0);
	g_signal_connect(G_OBJECT(translate_u_combo), "changed", G_CALLBACK(change_translate_u_factor), (gpointer)g_win);
	
	//DOWN
	translate_d_label = gtk_label_new( "Translate Down by:" );
	gtk_label_set_width_chars (GTK_LABEL(translate_d_label), 20);
	char translate_d_info[50];
        sprintf(translate_d_info, "Current Setting: %.2f%%", 100/g_win->translate_d_factor );
        translate_d_info_label = gtk_label_new(translate_d_info);
        translate_d_combo = gtk_combo_box_new_text();
	for ( int i = 5; i <= MAX_TRANSLATE; i=i+5 )
	{
		sprintf( str,  "%d%%", i); 
		gtk_combo_box_append_text(GTK_COMBO_BOX(translate_d_combo), str);
	}
	gtk_combo_box_set_active (GTK_COMBO_BOX(translate_d_combo), 0);
	g_signal_connect(G_OBJECT(translate_d_combo), "changed", G_CALLBACK(change_translate_d_factor), (gpointer)g_win);
	
	//LEFT
	translate_l_label = gtk_label_new( "Translate Left by:" );
	gtk_label_set_width_chars (GTK_LABEL(translate_l_label), 20);
	char translate_l_info[50];
        sprintf(translate_l_info, "Current Setting: %.2f%%", 100/g_win->translate_l_factor );
        translate_l_info_label = gtk_label_new(translate_l_info);
        translate_l_combo = gtk_combo_box_new_text();
	for ( int i = 5; i <= MAX_TRANSLATE; i=i+5 )
	{
		sprintf( str,  "%d%%", i); 
		gtk_combo_box_append_text(GTK_COMBO_BOX(translate_l_combo), str);
	}
	gtk_combo_box_set_active (GTK_COMBO_BOX(translate_l_combo), 0);
	g_signal_connect(G_OBJECT(translate_l_combo), "changed", G_CALLBACK(change_translate_l_factor), (gpointer)g_win);
	
	
	//RIGHT
	translate_r_label = gtk_label_new( "Translate Right by:" );
	gtk_label_set_width_chars (GTK_LABEL(translate_r_label), 20);
	char translate_r_info[50];
        sprintf(translate_r_info, "Current Setting: %.2f%%", 100/g_win->translate_r_factor );
        translate_r_info_label = gtk_label_new(translate_r_info);
        translate_r_combo = gtk_combo_box_new_text();
	for ( int i = 5; i <= MAX_TRANSLATE; i=i+5 )
	{
		sprintf( str,  "%d%%", i); 
		gtk_combo_box_append_text(GTK_COMBO_BOX(translate_r_combo), str);
	}
	gtk_combo_box_set_active (GTK_COMBO_BOX(translate_r_combo), 0);
	g_signal_connect(G_OBJECT(translate_r_combo), "changed", G_CALLBACK(change_translate_r_factor), (gpointer)g_win);
	
	translate_table = gtk_table_new(4, 3, 0);
	translate_frame = gtk_frame_new( "Viewport Translate options" );
	gtk_table_attach( GTK_TABLE(translate_table), translate_u_label, 0, 1, 0, 1, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(translate_table), translate_u_combo, 1, 2, 0, 1, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(translate_table), translate_u_info_label, 2, 3, 0, 1, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(translate_table), translate_d_label, 0, 1, 1, 2, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(translate_table), translate_d_combo, 1, 2, 1, 2, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(translate_table), translate_d_info_label, 2, 3, 1, 2, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(translate_table), translate_l_label, 0, 1, 2, 3, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(translate_table), translate_l_combo, 1, 2, 2, 3, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(translate_table), translate_l_info_label, 2, 3, 2, 3, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(translate_table), translate_r_label, 0, 1, 3, 4, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(translate_table), translate_r_combo, 1, 2, 3, 4, GTK_FILL, GTK_FILL, 5, 5 );
	gtk_table_attach( GTK_TABLE(translate_table), translate_r_info_label, 2, 3, 3, 4, GTK_FILL, GTK_FILL, 5, 5 );
	
	gtk_container_add(GTK_CONTAINER (translate_frame), translate_table);
	gtk_container_add(GTK_CONTAINER (content_area), translate_frame);
	hsep3 = gtk_hseparator_new();
	gtk_container_add(GTK_CONTAINER (content_area), hsep3);
	
	/* Ensure that the dialog box is destroyed when the user responds */
	g_signal_connect_swapped (dialog, "response", G_CALLBACK (gtk_widget_destroy), dialog);
	
	gtk_widget_show_all (dialog);
}

gtk_win::gtk_win( draw_gtk _drawscreen, int onset_width, int onset_height  )
{
	win_current_width  = onset_width;
	win_current_height = onset_height;
	tx = 0;
	ty = 0;
	scale = 1;
	user_tx = 0;
	user_ty = 0; 
	drawscreen = _drawscreen;
	window_zoom_mode_on = false;
	stbar_height = 30;
	sdp_width = 90;
	toolbar_height = 60;
	type = PDF;
	angle = 0;
	
	zoom_in_factor = 2*1.04/(1.04-1);
	zoom_out_factor = 2*0.96/(1-0.96);
	scroll_zoom_in_multiplier = (1.04-1)/1.04;
	scroll_zoom_out_multiplier = (1-0.96)/0.96;
	translate_u_factor = 100/5.0;
	translate_d_factor = 100/5.0;
	translate_l_factor = 100/5.0;
	translate_r_factor = 100/5.0;
	
	user_key_press_method = NULL;
	user_key_press_active = false;
	user_mouse_pos_method = NULL;
	user_mouse_position_active = false;
	user_mouse_button_press_method = NULL;
	user_mouse_press_active = false;
}

style_button::style_button( string _button_text, button_fcn _act_on_button_press, gtk_win *_application )
{
	button_text = _button_text;
	act_on_button_press = _act_on_button_press;
	application = _application;
	desc = "NO IDEA!!!";
	
	#ifdef STYLE_BUTTONS
		button = gtk_button_new();
	#else 
		button = gtk_button_new_with_label( button_text.c_str() );
	#endif
	
	g_signal_connect(G_OBJECT(button), "clicked", G_CALLBACK(act_on_button_press), (gpointer)this );
	gtk_button_set_relief( GTK_BUTTON(button), GTK_RELIEF_HALF );

	#ifdef STYLE_BUTTONS
		button_label = gtk_label_new("");
		gtk_label_set_width_chars( GTK_LABEL (button_label), button_text.length()+2);

		string markup = "<span face=\"Arial\" style=\"normal\" color=\"#ffffff\" bgcolor=\"#528ae1\" size=\"x-large\">"
			        + button_text + "</span>";
		gtk_label_set_markup(GTK_LABEL (button_label), markup.c_str() );
		gtk_container_add (GTK_CONTAINER (button), button_label);
		GtkStyle *style = gtk_widget_get_style(button);

		GdkColor my_white;
		gdk_color_parse("#528ae1", &my_white);
		GdkColor my_orange; 
		gdk_color_parse("#f07300", &my_orange);
	
		style->bg[GTK_STATE_PRELIGHT] = my_orange;
		style->bg[GTK_STATE_NORMAL]   = my_white;
		style->bg[GTK_STATE_ACTIVE]   = my_orange;
		style->bg[GTK_STATE_SELECTED] = my_white;
		style->bg[GTK_STATE_INSENSITIVE] = my_white;
		style->xthickness = 2;
	  	style->ythickness = 2;
		gtk_widget_set_style(button, style);
		g_signal_connect(G_OBJECT(button), "enter", G_CALLBACK(enter_button), (gpointer)this);
		g_signal_connect(G_OBJECT(button), "leave", G_CALLBACK(leave_button), (gpointer)this);
	#endif
}

void style_button::set_desc( string _desc )
{
	desc = _desc;
}

void gtk_win::init_world( double x1, double y1, double x2, double y2 )
{
	xleft = x1;
	xright = x2;
	ytop = y1;
	ybottom = y2;
	
	saved_xleft = xleft;     /* Save initial world coordinates to allow full */
	saved_xright = xright;   /* view button to zoom all the way out.         */
	saved_ytop = ytop;
	saved_ybottom = ybottom;
	
	//update_transform();
	// Fire up GTK!     
	gtk_init (NULL, NULL); 
}

void gtk_win::init_graphics( char* windowtitle )
{ 

	mainwin = gtk_window_new (GTK_WINDOW_TOPLEVEL);
	gtk_widget_set_app_paintable(mainwin, TRUE);
	g_signal_connect(G_OBJECT(mainwin), "expose-event", G_CALLBACK(mainwin_expose), (gpointer)this );
	
	canvas = gtk_drawing_area_new ();
	gtk_widget_set_double_buffered ( canvas, true);
	int canvas_width = win_current_width - sdp_width;
	int canvas_height = win_current_height - toolbar_height-stbar_height;
	gtk_widget_set_size_request (canvas, canvas_width, canvas_height);
	
	statusbar = gtk_statusbar_new();
	gtk_widget_set_size_request (statusbar, win_current_width, stbar_height);
	
	char modifiedtitle[100];
	sprintf(modifiedtitle, "BridgeGL: %s", windowtitle);
	gtk_window_set_title(GTK_WINDOW(mainwin), modifiedtitle);	
	
	gtk_widget_add_events(mainwin, GDK_SCROLL_MASK);
	gtk_widget_add_events(mainwin, GDK_POINTER_MOTION_MASK);
	gtk_widget_add_events(mainwin, GDK_BUTTON_PRESS_MASK|GDK_BUTTON_MOTION_MASK);
	gtk_widget_add_events(mainwin, GDK_BUTTON_RELEASE_MASK);
		
	vbox = gtk_vbox_new(FALSE, 1);
	hbox = gtk_hbox_new(FALSE, 1);
	button_vbox = gtk_vbox_new(FALSE, 1);
	gtk_widget_set_size_request (button_vbox, sdp_width, canvas_height);
	vseparator = gtk_vseparator_new();
	
	gtk_box_pack_start(GTK_BOX(hbox), button_vbox, FALSE, FALSE, 1);
	//gtk_box_pack_start(GTK_BOX(hbox), vseparator, FALSE, TRUE, 1);
	gtk_box_pack_end(GTK_BOX(hbox), canvas, TRUE, TRUE, 1); 
	
	gtk_container_add (GTK_CONTAINER (mainwin), vbox);
	
	style_button wzoom_button( "Window", turn_on_window_zoom_mode, this );
	wzoom_button.set_desc("helps user to zoom in by mouse dragging");
	sidepane_buttons.push_back(&wzoom_button);
	
	hseparator1 = gtk_hseparator_new();
	hseparator2 = gtk_hseparator_new();
	
	for( int i = sidepane_buttons.size()-1; i >=0; i-- )
	{
		gtk_box_pack_start(GTK_BOX(button_vbox), sidepane_buttons[i]->button, FALSE, FALSE, 0);
	}
	
	
	toolbar = gtk_toolbar_new();
	gtk_toolbar_set_style(GTK_TOOLBAR(toolbar), GTK_TOOLBAR_ICONS);
	gtk_toolbar_set_icon_size( GTK_TOOLBAR(toolbar), GTK_ICON_SIZE_DIALOG);
	gtk_container_set_border_width(GTK_CONTAINER(toolbar), 2);

	save = gtk_tool_button_new_from_stock(GTK_STOCK_SAVE_AS);
	gtk_toolbar_insert(GTK_TOOLBAR(toolbar), save, -1);
	gtk_tool_item_set_tooltip_text ( save, "save as");
	g_signal_connect(G_OBJECT(save), "clicked", G_CALLBACK(save_as_fcn), (gpointer)this );
	
	refresh = gtk_tool_button_new_from_stock(GTK_STOCK_REFRESH);
	gtk_toolbar_insert(GTK_TOOLBAR(toolbar), refresh, -1);
	gtk_tool_item_set_tooltip_text ( refresh, "refresh drawing area");
	g_signal_connect(G_OBJECT(refresh), "clicked", G_CALLBACK(refresh_drawing_area), (gpointer)this );
	
	zoom_in = gtk_tool_button_new_from_stock(GTK_STOCK_ZOOM_IN);
	gtk_toolbar_insert(GTK_TOOLBAR(toolbar), zoom_in, -1);
	gtk_tool_item_set_tooltip_text (zoom_in, "zoom in");
	g_signal_connect(G_OBJECT(zoom_in), "clicked", G_CALLBACK(zoom_in_fcn), (gpointer)this );
	
	zoom_out = gtk_tool_button_new_from_stock(GTK_STOCK_ZOOM_OUT);
	gtk_toolbar_insert(GTK_TOOLBAR(toolbar), zoom_out, -1);
	gtk_tool_item_set_tooltip_text (zoom_out, "zoom out");
	g_signal_connect(G_OBJECT(zoom_out), "clicked", G_CALLBACK(zoom_out_fcn), (gpointer)this );

	zoom_fit = gtk_tool_button_new_from_stock(GTK_STOCK_ZOOM_FIT);
	gtk_toolbar_insert(GTK_TOOLBAR(toolbar), zoom_fit, -1);
	gtk_tool_item_set_tooltip_text (zoom_fit, "fit to window size");
	g_signal_connect(G_OBJECT(zoom_fit), "clicked", G_CALLBACK(zoom_fit_fcn), (gpointer)this );
	
	preferences = gtk_tool_button_new_from_stock(GTK_STOCK_PREFERENCES);
	gtk_toolbar_insert(GTK_TOOLBAR(toolbar), preferences, -1);
	gtk_tool_item_set_tooltip_text (preferences, "preferences");
	g_signal_connect(G_OBJECT(preferences), "clicked", G_CALLBACK(preference_dialouge), (gpointer)this );
	
	help = gtk_tool_button_new_from_stock(GTK_STOCK_HELP);
	gtk_toolbar_insert(GTK_TOOLBAR(toolbar), help, -1);
	gtk_tool_item_set_tooltip_text (help, "about");
	g_signal_connect(G_OBJECT(help), "clicked", G_CALLBACK(about_dialouge), NULL );
	
	exit = gtk_tool_button_new_from_stock(GTK_STOCK_QUIT);
	gtk_toolbar_insert(GTK_TOOLBAR(toolbar), exit, -1);
	gtk_tool_item_set_tooltip_text (exit, "quit BridgeGL");
	g_signal_connect(G_OBJECT(exit), "clicked", G_CALLBACK(gtk_main_quit), NULL);
	
	GdkColor color;
	gdk_color_parse ("#cdcdc1", &color);
	gtk_widget_modify_bg (toolbar, GTK_STATE_NORMAL, &color);
	

	gtk_box_pack_start(GTK_BOX(vbox), toolbar, FALSE, FALSE, 1);
	//gtk_box_pack_start(GTK_BOX(vbox), hseparator1, FALSE, TRUE, 0);
	gtk_box_pack_start(GTK_BOX(vbox), hbox, TRUE, TRUE, 1); 
	//gtk_box_pack_start(GTK_BOX(vbox), hseparator2, FALSE, TRUE, 0);
	gtk_box_pack_end(GTK_BOX(vbox), statusbar, FALSE, TRUE, 1);
	
	g_signal_connect (mainwin, "destroy", G_CALLBACK (gtk_main_quit), NULL); // Quit graphically 

	// key press events are connected to act_on_key_press
	g_signal_connect (mainwin, "key_press_event", G_CALLBACK (act_on_key_press),  (gpointer)this );
	//gtk_window_set_decorated ( GTK_WINDOW(mainwin), 0);
	
	g_signal_connect(G_OBJECT(canvas), "configure-event", G_CALLBACK(gtk_canvas_configure), (gpointer)this);
	g_signal_connect(G_OBJECT(mainwin), "configure-event", G_CALLBACK(gtk_mainwin_configure), (gpointer)this);
	
	g_signal_connect(mainwin, "scroll-event", G_CALLBACK(gtk_win_scroll), (gpointer)this);
	gtk_signal_connect (GTK_OBJECT(mainwin), "motion_notify_event", G_CALLBACK(mouse_position_tracker), (gpointer)this);
	g_signal_connect(mainwin, "button_press_event", G_CALLBACK(window_zoom), (gpointer)this);
	g_signal_connect(mainwin, "button_release_event", G_CALLBACK(window_zoom), (gpointer)this);

	// Whenever exposed, do the drawing on canvas as per user function
	g_signal_connect (G_OBJECT (canvas), "expose-event", G_CALLBACK (canvas_expose),  (gpointer)this );
	
	// Show the window on the screen 
	gtk_widget_show_all (mainwin); 	
	
	 // Enter the main event loop, and wait for user interaction 
	gtk_main (); //*/
}


void gtk_win::redraw()
{
	 gtk_widget_queue_draw_area ( canvas,  tx, ty,
		             canvas_width, canvas_height);
	
	gtk_statusbar_push( GTK_STATUSBAR(statusbar), 
		            gtk_statusbar_get_context_id( GTK_STATUSBAR(statusbar), "Refreshed Drawing Area"), "Refreshed Drawing Area");
}

void gtk_win::draw_virtual_scrollbars()
{
	//#CCCCCC"
	cr = gdk_cairo_create (canvas->window);
	cairo_set_source_rgba(cr, 0.5, 0.5, 0.5, 0.6);

	double xratio = (saved_xright - saved_xleft)/canvas_width; 
	double yratio = (saved_ybottom - saved_ytop)/canvas_height;
	
	double scroll_xleft   = xleft*xratio;
	if ( scroll_xleft < 0 )
		scroll_xleft = 0;

	double scroll_xright = canvas_width - (saved_xright - xright)*xratio;
	if ( scroll_xright > canvas_width )
		scroll_xright = canvas_width; 
	
	double scroll_ytop    = ytop*yratio;
	if ( scroll_ytop < 0 )
		scroll_ytop = 0;
	
	double scroll_ybottom = canvas_height - (saved_ybottom - ybottom)*yratio;
	if ( scroll_ybottom > canvas_height )
		scroll_ybottom = canvas_height;
	
	#ifdef DEBUG
		printf("scroll_xleft: %.2f, scroll_xright: %.2f, scroll_ytop: %.2f, scroll_ybottom: %.2f\n\n", 
	       		scroll_xleft, scroll_xright, scroll_ytop, scroll_ybottom);
	#endif
	
	cairo_move_to(cr, scroll_xleft, canvas_height - 8 );
	cairo_line_to(cr, scroll_xleft, canvas_height - 3 );
	cairo_line_to(cr, scroll_xright, canvas_height - 3 );
	cairo_line_to(cr, scroll_xright, canvas_height - 8 );
	cairo_line_to(cr, scroll_xleft, canvas_height - 8 );
	cairo_fill(cr);
	
	cairo_move_to(cr, 3, scroll_ytop );
	cairo_line_to(cr, 3, scroll_ybottom );
	cairo_line_to(cr, 8, scroll_ybottom );
	cairo_line_to(cr, 8, scroll_ytop );
	cairo_line_to(cr, 3, scroll_ytop );
	cairo_fill(cr);
	
	cairo_destroy(cr);
}

void gtk_win::update_statusbar_msg()
{
	gchar *str;
	double userx = win2user_x(worldx);
	double usery = win2user_y(worldy);
	
	if( window_zoom_mode_on && !in_window_zoom_mode )
		str = g_strdup_printf("  Win: [%d, %d], User: [%.2f, %.2f], Mode: Window_zoom, Todo: Drag the mouse to zoom in on an area.", 
		                         worldx, worldy, userx, usery );
	else if ( window_zoom_mode_on && in_window_zoom_mode )
		str = g_strdup_printf("  Win: [%d, %d], User: [%.2f, %.2f], Mode: Window_zoom, Zoom Area: %.2fx%.2f from [%.2f, %.2f]", 
		                         worldx, worldy, z_xright, z_ybottom, z_xright - z_xleft,
		                         z_ybottom - z_ytop, z_xleft, z_ytop );
	else
		str = g_strdup_printf("  Win: [%d, %d], User: [%.2f, %.2f], Mode: Normal, Magnification: %.2fX", 
		                         worldx, worldy, userx, usery, 
		                         max( (saved_xright - saved_xleft)/(xright-xleft), (saved_ybottom - saved_ytop)/(ybottom-ytop) ) );

	gtk_statusbar_push( GTK_STATUSBAR(statusbar), 
	                    gtk_statusbar_get_context_id( GTK_STATUSBAR(statusbar), str), str);
	g_free(str);
}

// Set up the factors for transforming from the user world to GTK Windows coordinates.
// main concept taken from Prof vaughn betz's easygl code.                                                           
void gtk_win::update_transform()
{
	double mult, y1, y2, x1, x2;
	
	// gtk_drawing_area() coordinates go from (0,0) to 
	// (canvas_width-1, canvas_height-1)
	xmult = (canvas_width - 1)/(xright - xleft);
	ymult = (canvas_height - 1)/(ybottom - ytop);
	
	// Need to use same scaling factor to preserve aspect ratio
	if (fabs(xmult) <= fabs(ymult)) {
		mult = (fabs(ymult/xmult));
		y1 = ytop    - (ybottom-ytop)*(mult-1)/2;
		y2 = ybottom + (ybottom-ytop)*(mult-1)/2;
		ytop = y1;
		ybottom = y2;
	}
	else 
	{
		mult = (fabs(xmult/ymult));
		x1 = xleft - (xright-xleft)*(mult-1)/2;
		x2 = xright + (xright-xleft)*(mult-1)/2;
		xleft = x1;
		xright = x2;
	}
	
	xmult = (canvas_width - 1)/ (xright - xleft);
	ymult = (canvas_height - 1)/ (ybottom - ytop);
	
	// can queue an expose event here to automatically draw after
	// updating transform. But sometimes, we may need to update
	// the transform and wait for another event to draw. hence,
	// we always queue an expose event separately. 
	#ifdef DEBUG
		printf("\nxleft: %.2f, ytop: %.2f, xright: %.2f, ybottom: %.2f\n", 
		       xleft, ytop, xright, ybottom);
		printf("xmult: %.2f, ymult: %.2f, win_current_width: %d, win_current_height: %d, canvas_width: %d, canvas_height: %d\n", 
		       xmult, ymult, win_current_width, win_current_height, canvas_width, canvas_height);
	#endif
}

double gtk_win::user2win_x( double user_x )
{
	return (user_x - xleft)*xmult;
}
	
double gtk_win::user2win_y( double user_y )
{
	return (user_y - ytop)*ymult;
}
	
double gtk_win::win2user_x( double world_x )
{
	return ( xleft + (world_x - sdp_width-6)/xmult );
}
	
double gtk_win::win2user_y( double world_y )
{
	return ( ytop + (world_y - toolbar_height-14)/ymult);
}
void gtk_win::translate_coordinates(cairo_t* cr, double _tx, double _ty )
{
	user_tx = _tx;
	user_ty = _ty;
	cairo_translate(cr, _tx*xmult, _ty*ymult);
	
	/*printf("user_tx: %.2f, user_ty: %.2f, win_tx: %.2f, win_ty: %.2f\n", 
		       _tx, _ty, _tx*xmult, _ty*ymult );
	cairo_matrix_t matrix;
	cairo_get_matrix(cr, &matrix);
	printf("translations:- x: %.2f and y: %.2f\n", matrix.x0, matrix.y0);//*/
}

bool gtk_win::rect_off_screen (cairo_t* cr, double x1, double y1, double x2, double y2) 
{
	//cairo_matrix_t matrix;
	//cairo_get_matrix(cr, &matrix);
	x1 = x1+user_tx;
	y1 = y1+user_ty;
	x2 = x2+user_tx;
	y2 = y2+user_ty;
	
	double xmin, xmax, ymin, ymax;
	
	xmin = min (xleft, xright);
	if (x1 < xmin && x2 < xmin)
	{
		return (1);
	}
	
	xmax = max (xleft, xright);
	if (x1 > xmax && x2 > xmax)
	{
		return (1);
	}
	
	ymin = min (ytop, ybottom);
	if (y1 < ymin && y2 < ymin)
	{
		return (1);
	}
	
	ymax = max (ytop, ybottom);
	if (y1 > ymax && y2 > ymax)
	{
		return (1);
	}
	
	return (0);
}

void gtk_win::focus_on_area( double _xleft, double _ytop, double _xright, double _ybottom )
{
	// no check on limits, is probably dangerous, could overflow or underflow        
	xleft = _xleft;
	xright = _xright;
	ytop = _ytop;
	ybottom = _ybottom;
	
	update_transform();
	
        gtk_widget_queue_draw_area ( canvas,  tx, ty,
		             canvas_width, canvas_height);
}

void gtk_win::focus()
{
	update_transform();		
        gtk_widget_queue_draw_area ( canvas,  tx, ty,
		             canvas_width, canvas_height);
}


void gtk_win::restore_to_onset_view()
{
	xleft = saved_xleft;
	xright = saved_xright;
	ytop = saved_ytop;
	ybottom = saved_ybottom;
	
	focus();
}

void gtk_win::translate_up()
{
	double ystep = (ybottom - ytop)/translate_u_factor;	//user2win_y(50); 
	ytop    -= ystep;
	ybottom -= ystep;
	update_transform();
	
	gtk_widget_queue_draw_area ( canvas,  tx, ty,
		             canvas_width, canvas_height);
}

void gtk_win::translate_down()
{
	double ystep = (ybottom - ytop)/translate_d_factor;	//user2win_y(50); 
	ytop    += ystep;
	ybottom += ystep;
	update_transform();
	
	gtk_widget_queue_draw_area ( canvas,  tx, ty,
		             canvas_width, canvas_height);
}

void gtk_win::translate_left()
{
	double xstep = (xright - xleft)/translate_l_factor;	//user2win_x(50); 
	xleft  -= xstep;
	xright -= xstep; 
	update_transform();
	
	gtk_widget_queue_draw_area ( canvas,  tx, ty,
		             canvas_width, canvas_height);
}

void gtk_win::translate_right()
{
	double xstep = (xright - xleft)/translate_r_factor;	//user2win_x(50); 
	xleft  += xstep;
	xright += xstep; 
	update_transform();
	
	gtk_widget_queue_draw_area ( canvas,  tx, ty,
		             canvas_width, canvas_height);
}

void gtk_win::clearscreen(cairo_t* cr)
{
	cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);
	cairo_paint(cr);
}

void gtk_win::setbgcolor(cairo_t*cr, double red, double green, double blue)
{
	cairo_set_source_rgb(cr, red, green, blue);
	cairo_paint(cr);
}

void gtk_win::setcolor(cairo_t* cr, double red, double green, double blue, double alpha)
{
	cairo_set_source_rgba(cr, red, green, blue, alpha);
}

void gtk_win::setradialgradient(cairo_t* cr, double cx0, double cy0, double r0, double cx1, double cy1, double r1)
{
	
}

void gtk_win::setlineargradient(cairo_t* cr, double cx0, double cy0, double cx1, double cy1)
{
	
}

void gtk_win::setlinestyle(cairo_t* cr, int linestyle)
{
	double dashes[3][2] =
	{
	{0.0, 0.0},
	{4.0, 2.0},
	{2.0, 4.0},
	};
	int num_dashes = (linestyle > 0) ? 1 : 0;
	cairo_set_dash(cr, dashes[linestyle], num_dashes, 0.0);
}

void gtk_win::setlinestyle(cairo_t* cr, int linestyle, double *dashes)
{
	int num_dashes = (linestyle > 0) ? 1 : 0;
	cairo_set_dash(cr, dashes, num_dashes, 0.0);
}

void gtk_win::setlinewidth(cairo_t* cr, double linewidth)
{
	cairo_set_line_width(cr, linewidth);
}

void gtk_win::drawline(cairo_t* cr, double x1, double y1, double x2, double y2)
{
	if (rect_off_screen(cr,x1,y1,x2,y2))	return;
	
	cairo_move_to(cr, user2win_x(x1), user2win_y(y1) );
	cairo_line_to(cr, user2win_x(x2), user2win_y(y2) );
	cairo_stroke(cr);
}

void gtk_win::setfontsize(cairo_t* cr, int pointsize)
{
	#ifdef SCALE_TEXT
		//double fsize = pointsize*max( (saved_xright - saved_xleft)/(xright-xleft), (saved_ybottom - saved_ytop)/(ybottom-ytop) );
		double fsize = pointsize*max( canvas_width/(xright-xleft), canvas_height/(ybottom-ytop) );
		cairo_set_font_size(cr, fsize);
	#else
		cairo_set_font_size(cr, (double)pointsize); 
	#endif
}

void gtk_win::setfontface( cairo_t* cr, char* fontface, cairo_font_slant_t slant, cairo_font_weight_t weight )
{
	cairo_select_font_face (cr, fontface, slant, weight); 
}

void gtk_win::drawtext(cairo_t* cr, double xc, double yc, char *text, double boundx)
{
	cairo_text_extents_t extents;
	cairo_text_extents(cr, text, &extents);
	
	if (rect_off_screen(cr, xc, yc-extents.height, xc+extents.width, yc))	
	{
		//printf("rectangle outside visible area\n");
		return;
	}
	
	if ( extents.width > fabs(xmult*boundx) )
	{
		//printf("width more than bound specified: textwidth: %g and canvas_boundx: %.2f\n", 
		//       extents.width,fabs(xmult*boundx) );
		return;
	}
	
	cairo_move_to(cr, user2win_x(xc), user2win_y(yc) );
	cairo_show_text(cr, text);
}

void gtk_win::drawellipticarc(cairo_t* cr, double xcen, double ycen, double radx, double rady, 
                                           double startang, double angextent)
{
	if (rect_off_screen(cr,xcen-radx, ycen-rady, xcen+radx, ycen+rady))	return;
	
	//cairo_user_to_device(cr, &xcen, &ycen);
	//printf("xcen: %.2f, ycen: %.2f\n", xcen, ycen);
	cairo_save (cr);
	cairo_translate (cr, user2win_x(xcen), user2win_y(ycen) );
	//translate_coordinates( cr, xcen, ycen );
	cairo_scale (cr, fabs(xmult*radx), fabs(ymult*rady));
	cairo_arc (cr, 0., 0., 1., startang*(M_PI/180.0), angextent*(M_PI/180.0) );
	cairo_restore (cr);
	
	cairo_stroke(cr);
}

void gtk_win::fillellipticarc(cairo_t* cr, double xcen, double ycen, double radx, double rady, 
                                           double startang, double angextent)
{
	if (rect_off_screen(cr,xcen-radx, ycen-rady, xcen+radx, ycen+rady))	return;
	
	cairo_move_to(cr, user2win_x(xcen), user2win_y(ycen) );
	cairo_line_to(cr, user2win_x(xcen) + user2win_x(radx)*cos(startang*(M_PI/180.0)), 
	                  user2win_y(ycen) + user2win_y(rady)*sin(startang*(M_PI/180.0)) );
	cairo_save(cr);
	cairo_translate (cr, user2win_x(xcen), user2win_y(ycen) );
	cairo_scale (cr, fabs(xmult*radx), fabs(ymult*rady));
	cairo_arc (cr, 0., 0., 1., startang*(M_PI/180.0), angextent*(M_PI/180.0) );
	cairo_restore (cr);
	
	cairo_fill(cr);
}


void gtk_win::drawarc(cairo_t* cr, double xcen, double ycen, double rad, double startang, double angextent)
{
	if (rect_off_screen(cr,xcen-rad, ycen-rad, xcen+rad ,ycen+rad))	return;
	
	cairo_move_to(cr, user2win_x(xcen) + fabs(xmult*rad)*cos(startang*(M_PI/180.0)), 
	                  user2win_y(ycen) + fabs(ymult*rad)*sin(startang*(M_PI/180.0)) );
	cairo_arc(cr, user2win_x(xcen), user2win_y(ycen), fabs(xmult*rad), 
	              startang*(M_PI/180.0), angextent*(M_PI/180.0));
	cairo_stroke(cr);
}

void gtk_win::fillarc(cairo_t* cr, double xcen, double ycen, double rad, double startang, double angextent)
{
	if (rect_off_screen(cr,xcen-rad, ycen-rad, xcen+rad ,ycen+rad))	return;	
	fillellipticarc(cr, xcen, ycen, rad, rad, startang, angextent);
}
  
void gtk_win::drawrect(cairo_t* cr, double x1, double y1, double x2, double y2)
{
	if (rect_off_screen(cr,x1,y1,x2,y2))	return;
		
	cairo_move_to(cr, user2win_x(x1), user2win_y(y1) );
	cairo_line_to(cr, user2win_x(x1), user2win_y(y2) );
	cairo_line_to(cr, user2win_x(x2), user2win_y(y2) );
	cairo_line_to(cr, user2win_x(x2), user2win_y(y1) );
	cairo_line_to(cr, user2win_x(x1), user2win_y(y1) );
	cairo_stroke(cr);
}

void gtk_win::fillrect(cairo_t* cr, double x1, double y1, double x2, double y2)
{
	if (rect_off_screen(cr,x1,y1,x2,y2))	return;
	
	cairo_move_to(cr, user2win_x(x1), user2win_y(y1) );
	cairo_line_to(cr, user2win_x(x1), user2win_y(y2) );
	cairo_line_to(cr, user2win_x(x2), user2win_y(y2) );
	cairo_line_to(cr, user2win_x(x2), user2win_y(y1) );
	cairo_line_to(cr, user2win_x(x1), user2win_y(y1) );
	cairo_fill(cr);
}

void gtk_win::drawpolygon(cairo_t* cr, vector<double> &x, vector<double> &y)
{
	bool to_stroke = drawpolypath(cr, x, y);
	
	if( to_stroke )
		cairo_stroke (cr);
}

void gtk_win::fillpolygon(cairo_t* cr, vector<double> &x, vector<double> &y)
{
	bool to_fill = drawpolypath(cr, x, y);
	
	if( to_fill )
		cairo_fill(cr);
}

bool gtk_win::drawpolypath(cairo_t* cr, vector<double> &x, vector<double> &y)
{
	if ( ( x.size() != y.size() ) || x.size() <= 1 || y.size() <= 1 )
	{
		fprintf(stderr, "ERROR: cannot draw polygon, illegal input\n");
		return false;
	}
	
	double xmin = x[0], xmax = x[0];
	double ymin = y[0], ymax = y[0];
	
	
	for ( unsigned int i=1; i < x.size(); i++) 
	{
		xmin = min (xmin, x[i] );
		xmax = max (xmax, x[i] );
		ymin = min (ymin, y[i] );
		ymax = max (ymax, y[i] );
	}
	
	if (rect_off_screen(cr,xmin,ymin,xmax,ymax))
		return false;

	cairo_move_to(cr, user2win_x(x[0]), user2win_y(y[0]) );
	for( unsigned int i=1; i < x.size(); i++ )
	{
		cairo_line_to(cr, user2win_x(x[i]), user2win_y(y[i]) );
	}
	cairo_close_path (cr);
	
	return true;
}

bool gtk_win::drawroundedrectpath( cairo_t* cr, double x1, double y1, double x2, double y2, double xarc, double yarc )
{
	if (rect_off_screen(cr,x1,y1,x2,y2))	return false;
	
	xarc = min( xarc, fabs(x1-x2)/2 );
	xarc = min( yarc, fabs(y1-y2)/2 );
	
	double xcen1 = x1+xarc;
	double xcen2 = x2-xarc;
	double ycen1 = y1+yarc;
	double ycen2 = y2-yarc; 
	
	cairo_move_to( cr, user2win_x(x1), user2win_y(ycen2) );
	
	cairo_line_to( cr, user2win_x(x1), user2win_y(ycen1) );
	cairo_save(cr);
	cairo_translate (cr, user2win_x(xcen1), user2win_y(ycen1) );
	cairo_scale (cr, fabs(xmult*xarc), fabs(ymult*yarc));
	cairo_arc (cr, 0., 0., 1., M_PI, 1.5*M_PI );
	cairo_restore (cr);
	
	cairo_line_to( cr, user2win_x(xcen2), user2win_y(y1) );
	cairo_save(cr);
	cairo_translate (cr, user2win_x(xcen2), user2win_y(ycen1) );
	cairo_scale (cr, fabs(xmult*xarc), fabs(ymult*yarc));
	cairo_arc (cr, 0., 0., 1., 1.5*M_PI, 2*M_PI );
	cairo_restore (cr);
	
	cairo_line_to( cr, user2win_x(x2), user2win_y(ycen2) );
	cairo_save(cr);
	cairo_translate (cr, user2win_x(xcen2), user2win_y(ycen2) );
	cairo_scale (cr, fabs(xmult*xarc), fabs(ymult*yarc));
	cairo_arc (cr, 0., 0., 1., 0, 0.5*M_PI );
	cairo_restore (cr);
	
	cairo_line_to( cr, user2win_x(xcen1), user2win_y(y2) );
	cairo_save(cr);
	cairo_translate (cr, user2win_x(xcen1), user2win_y(ycen2) );
	cairo_scale (cr, fabs(xmult*xarc), fabs(ymult*yarc));
	cairo_arc (cr, 0., 0., 1., 0.5*M_PI, 1*M_PI );
	cairo_restore (cr);
	
	return true;
}

void gtk_win::drawroundedrect( cairo_t* cr, double x1, double y1, double x2, double y2, double xarc, double yarc )
{
	if ( xarc <= 0 || yarc <= 0)
	{
		drawrect(cr, x1, y1, x2, y2);
		return;
	}
	bool to_stroke = drawroundedrectpath(cr, x1, y1, x2, y2, xarc, yarc);
	
	if ( to_stroke )	
		cairo_stroke(cr);
}

void gtk_win::fillroundedrect( cairo_t* cr, double x1, double y1, double x2, double y2, double xarc, double yarc )
{
	if ( xarc <= 0 || yarc <= 0)
	{
		fillrect(cr, x1, y1, x2, y2);
		return;
	}
	bool to_fill = drawroundedrectpath(cr, x1, y1, x2, y2, xarc, yarc);
	
	if ( to_fill )	
		cairo_fill(cr);
}

/* It is the responsibility of the user to ensure that his line falls within screen width at given font size*/
void gtk_win::drawtextballoon( cairo_t* cr, double user_x1, double user_y1, double tolerance, vector<string>* arr, 
                               int fontsize, char* fontface, double *rgb_border, double *rgba_fill, double *rgb_text )
{

	if ( rect_off_screen(cr, user_x1-tolerance, user_y1-tolerance, user_x1+tolerance, user_y1+tolerance) ) 	return;	
	
	cairo_save(cr);	
	
	cairo_identity_matrix(cr);
	cairo_set_font_size(cr, (double)fontsize);
	cairo_select_font_face (cr, fontface, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);

	cairo_text_extents_t extents;
	cairo_text_extents(cr, "M", &extents);
	
	// top and bottom margin
	double tb_margin = 2*extents.height;
	
	// left and right side margin
	double lr_margin = 2*extents.width;
	
	double diagbox_ascent = 30;
	double diagbox_height = extents.height*arr->size() + 2*tb_margin;
	double diagbox_width= -1;
	for ( int i = 0; i < arr->size(); i++ )
	{
		cairo_text_extents(cr, (*arr)[i].c_str(), &extents);
		if ( diagbox_width < extents.width )
		{
			diagbox_width = extents.width;
		}
	}
	diagbox_width  = diagbox_width + 2*lr_margin;
	
	double cx1 = user2win_x(user_x1);
	double cy1 = user2win_y(user_y1);
	
	double cx2 = ( cx1 + diagbox_width > canvas_width )?
		       cx1 - diagbox_width: cx1 + diagbox_width;
	double cy2 = ( cy1 + diagbox_height + diagbox_ascent  > canvas_height )?
		       cy1 - diagbox_height - diagbox_ascent:
		       cy1 + diagbox_height + diagbox_ascent;	
	
	double cdelx = cx2-cx1;	
	double c_xanchor1 = cx1 + 0.1*cdelx; 
	double c_xanchor2 = cx1 + 0.25*cdelx;
	double c_yanchor = ((cy1<cy2)?cy1 + diagbox_ascent :cy1 - diagbox_ascent);
	
	double x[7] = {cx1, c_xanchor1,      cx1, cx1, cx2,       cx2, c_xanchor2};
	double y[7] = {cy1, c_yanchor, c_yanchor, cy2, cy2, c_yanchor, c_yanchor };
	
	cairo_set_source_rgba(cr, rgba_fill[0], rgba_fill[1], rgba_fill[2], rgba_fill[3]);
	/*cairo_pattern_t *radpat, *linpat;
	radpat = cairo_pattern_create_radial (cx1, cy1, 30,  cx2, cy2, 70);
	cairo_pattern_add_color_stop_rgb (radpat, 0,  0.2, 0.2, 0.2);
	cairo_pattern_add_color_stop_rgb (radpat, 1,  0.8, 0.8, 0.8);
	cairo_set_source (cr, radpat);*/

	cairo_move_to(cr, x[0], y[0] );
	for( unsigned int i=1; i < 7; i++ )
	{
		cairo_line_to(cr, x[i], y[i] );
	}
	cairo_close_path (cr);
	cairo_fill(cr);
	
	cairo_set_source_rgb(cr, rgb_border[0], rgb_border[1], rgb_border[2]);
	cairo_move_to(cr, x[0], y[0] );
	for( unsigned int i=1; i < 7; i++ )
	{
		cairo_line_to(cr, x[i], y[i] );
	}
	cairo_close_path (cr);
	cairo_stroke(cr);
	
	double xref = lr_margin + ((cx1 < cx2)?cx1:cx2);
	double yref = tb_margin + ((c_yanchor < cy2)?c_yanchor:cy2);
	
	cairo_set_source_rgb(cr, rgb_text[0], rgb_text[1], rgb_text[2]);
	for ( int i = 0; i < arr->size(); i++ )
	{
		cairo_move_to( cr, xref, yref+i*0.8*tb_margin );
		cairo_show_text(cr, (*arr)[i].c_str() );
	}
	cairo_restore(cr);
}

void gtk_win::save_as()
{
	GtkWidget *dialog;
	GtkWidget *combo_box;
	
	dialog = gtk_file_chooser_dialog_new ("Save File",
				      GTK_WINDOW(mainwin),
				      GTK_FILE_CHOOSER_ACTION_SAVE,
				      GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL,
				      GTK_STOCK_SAVE, GTK_RESPONSE_ACCEPT,
				      NULL);
	gtk_file_chooser_set_do_overwrite_confirmation (GTK_FILE_CHOOSER (dialog), TRUE);
	combo_box = gtk_combo_box_new_text();
	gtk_combo_box_append_text(GTK_COMBO_BOX(combo_box), "PDF");
	gtk_combo_box_append_text(GTK_COMBO_BOX(combo_box), "PNG");
	gtk_combo_box_append_text(GTK_COMBO_BOX(combo_box), "SVG");
	gtk_combo_box_append_text(GTK_COMBO_BOX(combo_box), "PS");
	gtk_combo_box_set_active (GTK_COMBO_BOX(combo_box), 0);
	g_signal_connect(G_OBJECT(combo_box), "changed", G_CALLBACK(file_type_selected), (gpointer)this);
	gtk_file_chooser_set_extra_widget ( GTK_FILE_CHOOSER(dialog), combo_box);
	
	/*if (user_edited_a_new_document)
	{
		gtk_file_chooser_set_current_folder (GTK_FILE_CHOOSER (dialog), default_folder_for_saving);
		gtk_file_chooser_set_current_name (GTK_FILE_CHOOSER (dialog), "Untitled document");
	}
	else
		gtk_file_chooser_set_filename (GTK_FILE_CHOOSER (dialog), filename_for_existing_document);*/

	if (gtk_dialog_run (GTK_DIALOG (dialog)) == GTK_RESPONSE_ACCEPT)
	{
		char* filename = gtk_file_chooser_get_filename (GTK_FILE_CHOOSER (dialog));
		string fname(filename);
		int index = fname.find_last_of(".");

		if (index != -1)
		{
			string ftype = fname.substr(index+1); 
			if ( ftype == "pdf" )
				save_as_pdf(filename, 0);
			else if ( ftype == "png" )
				save_as_png(filename, 0);
			else if ( ftype == "svg" )
				save_as_svg(filename, 0);
			else if ( ftype == "ps" )
				save_as_ps(filename, 0);
			else if ( type == PDF )
				save_as_pdf(filename, 1);
			else if ( type == PNG )
				save_as_png(filename, 1);
			else if ( type == SVG )
				save_as_svg(filename, 1);
			else if ( type == PS )
				save_as_ps(filename, 1);
		}
		else if ( type == PDF )
			save_as_pdf(filename, 1);
		else if ( type == PNG )
			save_as_png(filename, 1);
		else if ( type == SVG )
			save_as_svg(filename, 1);
		else if ( type == PS )
			save_as_ps(filename, 1);
	
		g_free (filename);
	}
	
	gtk_widget_destroy (combo_box);
	gtk_widget_destroy (dialog);
}

void gtk_win::save_as_pdf( char* filename, bool appendtype )
{
	if ( appendtype )
		strcat(filename, ".pdf");
        cs = cairo_pdf_surface_create(filename, canvas_width,canvas_height);
        cr = cairo_create(cs);
        
        // repaint method
        cairo_identity_matrix(cr);
        user_tx = 0; user_ty = 0;
        cairo_translate(cr, tx, ty);
        cairo_scale(cr, scale, scale);
        drawscreen(canvas, cr);

        cairo_destroy(cr);
        cairo_surface_destroy(cs);
}
void gtk_win::save_as_png( char* filename, bool appendtype )
{
	if ( appendtype )
		strcat(filename, ".png");
        cs = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, canvas_width, canvas_height);
        cr = cairo_create(cs);
        
        // repaint method
        cairo_identity_matrix(cr);
        user_tx = 0; user_ty = 0;
        cairo_translate(cr, tx, ty);
        cairo_scale(cr, scale, scale);
        drawscreen(canvas, cr);

	cairo_surface_write_to_png(cs, filename);
        cairo_destroy(cr);
        cairo_surface_destroy(cs);
}
void gtk_win::save_as_svg( char* filename, bool appendtype )
{
	if ( appendtype )
		strcat(filename, ".svg");
        cs = cairo_svg_surface_create(filename, canvas_width, canvas_height);
        cr = cairo_create(cs);
        
        // repaint method
        cairo_identity_matrix(cr);
        user_tx = 0; user_ty = 0;
        cairo_translate(cr, tx, ty);
        cairo_scale(cr, scale, scale);
        drawscreen(canvas, cr);

        cairo_destroy(cr);
        cairo_surface_destroy(cs);
}
void gtk_win::save_as_ps( char* filename, bool appendtype )
{
	if ( appendtype )
		strcat(filename, ".ps");
        cs = cairo_ps_surface_create(filename, canvas_width, canvas_height);
        cr = cairo_create(cs);
        
        // repaint method
        cairo_identity_matrix(cr);
        user_tx = 0; user_ty = 0;
        cairo_translate(cr, tx, ty);
        cairo_scale(cr, scale, scale);
        drawscreen(canvas, cr);

        cairo_destroy(cr);
        cairo_surface_destroy(cs);
}


void gtk_win::line2arr (char* str, vector<string>* arr)
{	
	string ts;
	char* tok;
	(*arr).clear();
	tok = strtok(str," ");
	while ( tok != NULL )
	{
		ts.assign(tok);
		(*arr).push_back(ts);
		tok = strtok(NULL," ");
	}
}
/* Unused line: may be required later 
	style_banner = gtk_label_new("");
	gtk_widget_set_usize (style_banner, 110, 20);
	gtk_label_set_width_chars( GTK_LABEL (style_banner), 100);
	gtk_label_set_markup (GTK_LABEL (style_banner), 
	"<span face=\"sans\" style=\"normal\" color=\"#1E90FF\" bgcolor=\"#FAEBD7\" size=\"x-large\">CAIRO GRAPHICS WRAPPER</span>" );

	table = gtk_table_new(2,1, false);
	gtk_table_set_row_spacings(GTK_TABLE(table), 2);
	gtk_table_set_col_spacings(GTK_TABLE(table), 2);

	gtk_table_attach_defaults(GTK_TABLE(table), style_banner, 0,1,0,1);
	gtk_table_attach_defaults(GTK_TABLE(table), canvas, 0,1,1,2);
	gtk_table_attach(GTK_TABLE(table), style_banner, 0, 1, 0, 1, 
	GTK_SHRINK, GTK_SHRINK, 5, 5);
	gtk_table_attach(GTK_TABLE(table), canvas, 0, 1, 1, 2, 
	GTK_FILL, GTK_FILL, 5, 5);
	gtk_container_add (GTK_CONTAINER (mainwin), table);
	
	//custom title bar
	title_bar = gtk_hbox_new(FALSE, 1);
	gtk_widget_set_size_request (title_bar, win_current_width, 40);
	close_button = gtk_button_new();//_with_label("Close");
	resize_button = gtk_button_new_with_label("Resize");
	iconify_button = gtk_button_new_with_label("Iconify");
	gtk_box_pack_start(GTK_BOX(title_bar), close_button, FALSE, FALSE, 1);
	gtk_box_pack_start(GTK_BOX(title_bar), resize_button, FALSE, TRUE, 1); 
	gtk_box_pack_end(GTK_BOX(title_bar), iconify_button, FALSE, FALSE, 1);
	g_signal_connect(G_OBJECT(close_button), "clicked", G_CALLBACK(close_window), NULL);
	g_signal_connect(G_OBJECT(iconify_button), "clicked", G_CALLBACK(iconify_window), (gpointer)this);		
	gtk_button_set_relief( GTK_BUTTON(close_button), GTK_RELIEF_HALF );
	close_button_label = gtk_label_new("");
	gtk_label_set_width_chars( GTK_LABEL (close_button_label), 8);
	gtk_label_set_markup(GTK_LABEL (close_button_label), 
	"<span face=\"LMSansQuot8\" style=\"normal\" color=\"#1E90FF\" bgcolor=\"#CCCCCC\" size=\"xx-large\">Close</span>" );
	gtk_container_add (GTK_CONTAINER (close_button), close_button_label);
	GtkStyle *style = gtk_widget_get_style(close_button);
	//style->bg[GTK_STATE_PRELIGHT] = style->bg[GTK_STATE_NORMAL];
	style->xthickness = 0;
	style-> ythickness = 0;
	GdkColor my_white;
	printf("my white:%d\n", gdk_color_parse("#CCCCCC", &my_white) );
	GdkColor my_blue; 
	printf("my bluee:%d\n", gdk_color_parse("DodgerBlue", &my_blue) );
	style->bg[GTK_STATE_PRELIGHT] = my_blue;
	style->bg[GTK_STATE_NORMAL] = my_white;
	style->bg[GTK_STATE_ACTIVE] = my_white;
	style->bg[GTK_STATE_SELECTED] = my_white; 
	gtk_widget_set_style(close_button, style);
	g_signal_connect(G_OBJECT(close_button), "enter", G_CALLBACK(enter_close_button), (gpointer)this);
	g_signal_connect(G_OBJECT(close_button), "leave", G_CALLBACK(leave_close_button), (gpointer)this);
*/
