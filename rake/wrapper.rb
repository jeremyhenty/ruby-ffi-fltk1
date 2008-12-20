
# Copyright (C) 2008 Jeremy Henty.

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


# Build hooks.  Add code to extra.rb to modify these.
Project::EXTRA_CPP_DEFINES = [ ]

desc "Compile the wrapper library"
wrapper_library = "lib/ffi/fltk1.so"
wrapper_source = "wrapper/fltk1.cc"
CLOBBER.include(wrapper_library)
file wrapper_library => [ "extra.rb", wrapper_source ] do |t|
  puts "building '#{t.name}'"
  require "./extra"
  config = fltk_config
  sh \
  "#{config[:cxx]} -shared -fpic " \
  "#{config[:cxxflags]} #{config[:ldflags]} " \
  "#{Project::EXTRA_CPP_DEFINES * ' '} " \
  "-o #{t.name} #{wrapper_source}"
end
task :build => wrapper_library
