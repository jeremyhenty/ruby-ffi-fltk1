
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


require "rake"
require "rake/clean"

task :default => :build

# tests (first!)
desc "Run the tests"
task :test do
  sh "spec test"
end

desc "Build all the files"
task :build # we will add dependencies later

# a useful namespace
module Build
  class Error < StandardError ; end
end

require "./build/auto"
require "./build/fltk_config"
require "./build/constants"
require "./build/fltk"
require "./build/demo"
require "./build/gem"

# ensure that "extra.rb" exists, and load it
require "./build/extra"
Rake::Task["extra.rb"].invoke
require "./extra"
