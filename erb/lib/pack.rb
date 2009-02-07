
# Copyright (C) 2008, 2009 Jeremy Henty.

# This file is part of Ruby-FFI-FLTK1.

# Ruby-FFI-FLTK1 is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.

# Ruby-FFI-FLTK1 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see http://www.gnu.org/licenses/.


<%= generated %><%

builder = Pack

max_name_size = builder.ruby_names.collect { |name| name.size }.max
max_value_size = builder.values.collect { |value| value.to_s.size }.max

%>

module FFI::FLTK
  class <%= builder.ruby_class_name %>

    module Type
<%
name_format = "%%-%ds" % max_name_size
value_format = "%%%ds" % max_value_size
builder.ruby_names.zip(builder.values) do |name, value|
%>      <%= name_format % name %> = <%= value_format % value %>
<% end
%>    end

    TYPES = {
<%
quoted_format = '"%s"'
name_format = "%%-%ds" % (max_name_size + 2)
builder.ruby_names.each do |name|
%>      <%= name_format % (quoted_format % name) %> => Type::<%= name %>,
<% end
%>    }
  end
end
