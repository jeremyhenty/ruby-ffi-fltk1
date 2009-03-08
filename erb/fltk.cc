
// Copyright (C) 2008, 2009 Jeremy Henty.

// This file is part of Ruby-FFI-FLTK1.

// Ruby-FFI-FLTK1 is free software: you can redistribute it and/or
// modify it under the terms of the GNU General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.

// Ruby-FFI-FLTK1 is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.


// <%= generated %>

#ifdef FFI_FLTK_TRACE_DELETE
#include <iostream>
#endif // FFI_FLTK_TRACE_DELETE

#include <FL/Fl.H>
#include <FL/Fl_Widget.H>
#include <FL/Fl_Group.H>
#include <FL/Fl_Pack.H>
#include <FL/Fl_Scroll.H>
#include <FL/Fl_Window.H>
#include <FL/Fl_Box.H>
#include <FL/Fl_Menu_Bar.H>
#include <FL/Fl_Button.H>
#include <FL/Fl_Check_Button.H>
#include <FL/Fl_Light_Button.H>
#include <FL/Fl_Repeat_Button.H>
#include <FL/Fl_Return_Button.H>
#include <FL/Fl_Round_Button.H>
#include <FL/Fl_Toggle_Button.H>
#include <FL/Fl_Input.H>
#include <FL/Fl_Secret_Input.H>
#include <FL/Fl_Int_Input.H>
#include <FL/Fl_Float_Input.H>
#include <FL/Fl_Multiline_Input.H>
#include <FL/Fl_File_Input.H>
#include <FL/Fl_Output.H>
#include <FL/Fl_Multiline_Output.H>
#include <FL/Fl_Valuator.H>
#include <FL/fl_ask.H>

extern "C" {

// FLTK

int ffi_fltk_run()
{
  return Fl::run();
}

void ffi_fltk_alert(const char *message)
{
  fl_alert("%s", message);
}

} // extern "C"

// FFI wrapper

class FFI
{
public:
  typedef void Delete_Callback();
private:
  Delete_Callback *delete_callback;
protected:
  FFI();
  virtual ~FFI();
public:
  void set_delete_callback(Delete_Callback *callback);
};

FFI::FFI() : delete_callback((Delete_Callback *) 0)
{
}

FFI::~FFI() {
  if (delete_callback)
    delete_callback();
}

void FFI::set_delete_callback(Delete_Callback *callback)
{
  delete_callback = callback;
}

extern "C" {

void ffi_set_delete_callback(void *p_ffi, FFI::Delete_Callback *callback)
{
  ((FFI *) p_ffi)->set_delete_callback(callback);
}

} // extern "C"

// Widget

class FFI_Widget
{ // <% widget_class do %>
public:
  typedef void Callback();
  virtual void draw();
  static void callback_caller(Fl_Widget *widget, void *p_cb);

  // publicize some protected Fl_Widget members
  int x() { return Fl_Widget::x(); }
  void x(int _x) { Fl_Widget::x(_x); }
  int y() { return Fl_Widget::y(); }
  void y(int _y) { Fl_Widget::y(_y); }
  int w() { return Fl_Widget::w(); }
  void w(int _w) { Fl_Widget::w(_w); }
  int h() { return Fl_Widget::h(); }
  void h(int _h) { Fl_Widget::h(_h); }
};

void FFI_Widget::draw()
{
}

void FFI_Widget::callback_caller(Fl_Widget *widget, void *p_cb)
{
  // We ignore widget, which is good since it has probably been
  // coerced from (FFI_Widget *) to (FL_Widget *) via (void *) and is
  // therefore bogus.

  if (p_cb)
    ((Callback *) p_cb)();
}

extern "C" {

void *ffi_widget_fl_pointer(void *p_widget)
{
  return (Fl_Widget *)((FFI_Widget *) p_widget);
}

void ffi_callback_set(void *p_widget, void *cb)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  widget->callback(FFI_Widget::callback_caller, cb);
}

void ffi_widget_redraw(void *p_widget)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  widget->redraw();
}

uchar ffi_widget_type(void *p_widget)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  return widget->type();
}

void ffi_widget_type_set(void *p_widget, uchar type)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  widget->type(type);
}

int ffi_widget_box(void *p_widget)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  return widget->box();
}

void ffi_widget_box_set(void *p_widget, int box)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  widget->box((Fl_Boxtype) box);
}

int ffi_widget_x(void *p_widget)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  return widget->x();
}

void ffi_widget_x_set(void *p_widget, int x)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  widget->x(x);
}

int ffi_widget_y(void *p_widget)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  return widget->y();
}

void ffi_widget_y_set(void *p_widget, int y)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  widget->y(y);
}

int ffi_widget_w(void *p_widget)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  return widget->w();
}

void ffi_widget_w_set(void *p_widget, int w)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  widget->w(w);
}

int ffi_widget_h(void *p_widget)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  return widget->h();
}

void ffi_widget_h_set(void *p_widget, int h)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  widget->h(h);
}

} // extern "C"

// <% end %>

// Group

class FFI_Group
{ // <% widget_class do %>
};

extern "C" {

void *ffi_group_current()
{
  return Fl_Group::current();
}

void ffi_group_current_set(void *p_group)
{
  Fl_Group::current((FFI_Group *) p_group);
}

void ffi_group_begin(void *p_group)
{
  ((FFI_Group *) p_group)->begin();
}

void ffi_group_end(void *p_group)
{
  ((FFI_Group *) p_group)->end();
}

void *ffi_group_resizable(void *p_group)
{
  return ((FFI_Group *) p_group)->resizable();
}

void ffi_group_resizable_set(void *p_group, void *p_widget)
{
  ((FFI_Group *) p_group)->resizable((FFI_Widget *) p_widget);
}

} // extern "C"

// <% end %>

// Pack

class FFI_Pack
{ // <% widget_class do %>
};

// <% end %>

// Scroll

class FFI_Scroll
{ // <% widget_class do %>
};

// <% end %>

// Window

class FFI_Window
{ // <% widget_class do %>
public:
  FFI_Window(int w, int h, const char *l);
};

FFI_Window::FFI_Window(int w, int h, const char *l) :
  Fl_Window(w, h, l)
{
}

extern "C" {

void *ffi_window_new_whl(int w, int h, const char *l)
{
  return new FFI_Window(w, h, l);
}

void ffi_window_show(void *p_win)
{
  ((FFI_Window *) p_win)->show();
}

void ffi_window_hide(void *p_win)
{
  ((FFI_Window *) p_win)->hide();
}

void ffi_window_size_range(void *p_win,
			   int minw, int minh, int maxw, int maxh,
			   int dw, int dh, int aspect)
{
  ((FFI_Window *) p_win)->size_range(minw, minh, maxw, maxh,
				     dw, dh, aspect);
}

} // extern "C"

// <% end %>

// Box

class FFI_Box
{ // <% widget_class do %>
};

// <% end %>

// Menu_Bar

class FFI_Menu_Bar
{ // <% widget_class do %>
};

extern "C" {

void ffi_menu_add_i(void *p_menu,
		    const char *label, int shortcut,
		    void *callback,
		    int flags)
{
  ((FFI_Menu_Bar *) p_menu)->add(label, shortcut,
				 FFI_Widget::callback_caller,
				 callback, flags);
}

void ffi_menu_add_s(void *p_menu,
		    const char *label, const char *shortcut,
		    void *callback,
		    int flags)
{
  ((FFI_Menu_Bar *) p_menu)->add(label, shortcut,
				 FFI_Widget::callback_caller,
				 callback, flags);
}

} // extern "C"

// <% end %>

// Button

class FFI_Button
{ // <% widget_class do %>
};

// <% end %>

// Check_Button

class FFI_Check_Button
{ // <% widget_class do %>
};

// <% end %>

// Light_Button

class FFI_Light_Button
{ // <% widget_class do %>
};

// <% end %>

// Repeat_Button

class FFI_Repeat_Button
{ // <% widget_class do %>
};

// <% end %>

// Return_Button

class FFI_Return_Button
{ // <% widget_class do %>
};

// <% end %>

// Round_Button

class FFI_Round_Button
{ // <% widget_class do %>
};

// <% end %>

// Toggle_Button

class FFI_Toggle_Button
{ // <% widget_class do %>
};

// <% end %>

// Input

class FFI_Input
{ // <% widget_class do %>
};

extern "C" {

const char *ffi_input_value(void *p_widget)
{
  FFI_Input *widget = (FFI_Input *) p_widget;
  return widget->value();
}

void ffi_input_value_set(void *p_widget, const char *value)
{
  FFI_Input *widget = (FFI_Input *) p_widget;
  widget->value(value);
}

} // extern "C"

// <% end %>

// Secret_Input

class FFI_Secret_Input
{ // <% widget_class do %>
};

// <% end %>

// Int_Input

class FFI_Int_Input
{ // <% widget_class do %>
};

// <% end %>

// Float_Input

class FFI_Float_Input
{ // <% widget_class do %>
};

// <% end %>

// Multiline_Input

class FFI_Multiline_Input
{ // <% widget_class do %>
};

// <% end %>

// File_Input

class FFI_File_Input
{ // <% widget_class do %>
};

// <% end %>

// Output

class FFI_Output
{ // <% widget_class do %>
};

// <% end %>

// Multiline_Output

class FFI_Multiline_Output
{ // <% widget_class do %>
};

// <% end %>

// Valuator

class FFI_Valuator
{ // <% widget_class :abstract => true do %>
};

extern "C" {

double ffi_valuator_value(void *p_widget)
{              
  FFI_Valuator *widget = (FFI_Valuator *) p_widget;
  return widget->value();
}

void ffi_valuator_value_set(void *p_widget, double value)
{
  FFI_Valuator *widget = (FFI_Valuator *) p_widget;
  widget->value(value);
}

} // extern "C"

// <% end %>
