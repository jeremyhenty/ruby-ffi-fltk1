
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
#include <FL/Fl_Window.h>

extern "C" {

int fltk_run()
{
  return Fl::run();
}

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

} // extern "C"
