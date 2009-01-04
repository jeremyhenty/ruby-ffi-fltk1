
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

#include <FL/Enumerations.H>

static int boxes[<%= Box.names.size %>] = {
<% Box.names.each do |name|
%>  <%= name %>,
<% end %>};

extern "C" {

int *ffi_fl_boxes()
{
  return boxes;
}

}
