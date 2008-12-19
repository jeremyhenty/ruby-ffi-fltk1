
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


# Build hooks. Developers can add code in 'extra.rb' that modify
# these.  Changes to 'extra.rb' only affect local builds, not the
# installed version.

EXTRA_CPP_DEFINES = [ ]

desc "Initialize 'extra.rb'"
file "extra.rb" do |t|
  File.open(t.name,"w") do |extra|
    extra.write <<EXTRA
# This file was created by the build system. Developers can add extra
# test/debug code here for the Rakefile to load. This code will not be
# loaded when you build and install the gem.
EXTRA
  end
end
