
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

#include <FL/Fl.h>
#include <FL/Fl_Widget.h>
#include <FL/Fl_Window.h>
#include <FL/Fl_Button.h>
#include <FL/fl_ask.h>

extern "C" {

// FLTK

int fltk_run()
{
  return Fl::run();
}

void fltk_alert(const char *message)
{
  fl_alert("%s", message);
}

// Window

void *window_new_xywhl(int x, int y, int w, int h, const char *l)
{
  return new Fl_Window(x, y, w, h, l);
}

void *window_new_whl(int w, int h, const char *l)
{
  return new Fl_Window(w, h, l);
}

void window_delete(void *p_win)
{
#ifdef FFI_FLTK_TRACE_DELETE
  std::cout << "window_delete(): p_win = " << p_win << "\n";
#endif // FFI_FLTK_TRACE_DELETE
  delete (Fl_Window *) p_win;
}

void window_show(void *p_win)
{
  ((Fl_Window *) p_win)->show();
}

typedef void FFI_Widget_Callback();
static void widget_callback_caller(Fl_Widget *widget, void *p_cb)
{
  if (p_cb)
    ((FFI_Widget_Callback *) p_cb)();
}

void widget_callback(void *p_widget, void *cb)
{
  ((Fl_Widget *) p_widget)->callback(widget_callback_caller,cb);
}

// Button

void *button_new_xywhl(int x, int y, int w, int h, const char *l)
{
  return new Fl_Button(x, y, w, h, l);
}

void button_delete(void *p_win)
{
#ifdef FFI_FLTK_TRACE_DELETE
  std::cout << "button_delete(): p_win = " << p_win << "\n";
#endif // FFI_FLTK_TRACE_DELETE
  delete (Fl_Button *) p_win;
}

} // extern "C"
