
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


module Build
  DEMO_NAME = "ruby-ffi-fltk1-demo"
  desc "Run the demonstration program"
  task :run => :build do
    # prepend the local lib directory to $RUBYLIB
    lib_dir = File.join(Dir.pwd,"lib")
    lib_path = ENV["RUBYLIB"]
    ENV["RUBYLIB"] =
      lib_path ? ((lib_path.split(':').unshift(lib_dir)) * ':') : lib_dir

    # run the demo
    sh "bin/#{DEMO_NAME}"
  end
end
