
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
#include <FL/Fl_Window.H>
#include <FL/Fl_Box.H>
#include <FL/Fl_Button.H>
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

class FFI_Widget : public FFI, public Fl_Widget
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

void ffi_widget_set_callback(void *p_widget, void *cb)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  widget->callback(FFI_Widget::callback_caller, cb);
}

void ffi_widget_unset_callback(void *p_widget)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  widget->callback(FFI_Widget::callback_caller, (void *) 0);
}

void ffi_widget_redraw(void *p_widget)
{
  FFI_Widget *widget = (FFI_Widget *) p_widget;
  widget->redraw();
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

class FFI_Group : public FFI, public Fl_Group
{ // <% widget_class do %>
};

extern "C" {

void ffi_group_begin(void *p_group)
{
  ((FFI_Group *) p_group)->begin();
}

void ffi_group_end(void *p_group)
{
  ((FFI_Group *) p_group)->end();
}

void ffi_group_resizable_set(void *p_group, void *p_widget)
{
  ((FFI_Group *) p_group)->resizable((FFI_Widget *) p_widget);
}

} // extern "C"

// <% end %>

// Window

class FFI_Window : public FFI, public Fl_Window
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

class FFI_Box : public FFI, public Fl_Box
{ // <% widget_class do %>
};

// <% end %>

// Button

class FFI_Button : public FFI, public Fl_Button
{ // <% widget_class do %>
};

// <% end %>
