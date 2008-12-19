
// Copyright (C) 2008 Jeremy Henty.

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


#ifdef FFI_FLTK_TRACE_DELETE
#include <iostream>
#endif // FFI_FLTK_TRACE_DELETE

#include <FL/Fl.H>
#include <FL/Fl_Widget.H>
#include <FL/Fl_Window.H>
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
{
public:
  typedef void Callback();
  static void callback_caller(Fl_Widget *widget, void *p_cb);
  FFI_Widget(int x, int y, int w, int h, const char *l);
  virtual ~FFI_Widget();
};

FFI_Widget::FFI_Widget(int x, int y, int w, int h, const char *l) :
  Fl_Widget(x, y, w, h, l)
{
}

FFI_Widget::~FFI_Widget()
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

} // extern "C"

// Window

class FFI_Window : public FFI, public Fl_Window
{
public:
  FFI_Window(int x, int y, int w, int h, const char *l);
  FFI_Window(int w, int h, const char *l);
  virtual ~FFI_Window();
};

FFI_Window::FFI_Window(int x, int y, int w, int h, const char *l) :
  Fl_Window(x, y, w, h, l)
{
}

FFI_Window::FFI_Window(int w, int h, const char *l) :
  Fl_Window(w, h, l)
{
}

FFI_Window::~FFI_Window()
{
}

extern "C" {

void *ffi_window_new_xywhl(int x, int y, int w, int h, const char *l)
{
  return new FFI_Window(x, y, w, h, l);
}

void *ffi_window_new_whl(int w, int h, const char *l)
{
  return new FFI_Window(w, h, l);
}

void ffi_window_show(void *p_win)
{
  ((FFI_Window *) p_win)->show();
}

} // extern "C"

// Button

class FFI_Button : public FFI, public Fl_Button
{
public:
  FFI_Button(int x, int y, int w, int h, const char *l);
  virtual ~FFI_Button();
};

FFI_Button::FFI_Button(int x, int y, int w, int h, const char *l) :
  Fl_Button(x, y, w, h, l)
{
}

FFI_Button::~FFI_Button()
{
}

extern "C" {

void *ffi_button_new_xywhl(int x, int y, int w, int h, const char *l)
{
  return new FFI_Button(x, y, w, h, l);
}

} // extern "C"
