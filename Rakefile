
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


require "rake"
require "rake/clean"

task :default => :build

desc "Build all the files"
task :build # we will add dependencies later

require "./rake/fltk_config"
require "./rake/extra"
require "./rake/wrapper"

desc "Run the demonstration program"
demo_name = "ruby-ffi-fltk1-demo"
task :run => :build do
  # prepend the local lib directory to $RUBYLIB
  lib_dir = File.join(Dir.pwd,"lib")
  lib_path = ENV["RUBYLIB"]
  ENV["RUBYLIB"] =
    lib_path ? ((lib_path.split(':').unshift(lib_dir)) * ':') : lib_dir

  # run the demo
  sh "bin/#{demo_name}"
end

# Rubygems

require "rubygems"
require "rake/gempackagetask"

specification = Gem::Specification.new do |s|
  s.author = "Jeremy Henty"
  s.email = "onepoint@starurchin.org"

  s.name = "ffi-fltk1"
  s.version = "0.0.1"
  s.summary = "A binding of the FLTK1 GUI toolkit using FFI."

  s.platform = Gem::Platform::RUBY
  s.add_dependency "ffi", ">= 0.2.0"
  s.files =
    FileList["COPYING", "AUTHORS",
             "lib/**/*.rb", "rake/**/*.rb",
             "wrapper/*.cc", "bin/*"].to_a
  s.extensions = "Rakefile"
  s.executables = [ demo_name ]
end

class Rake::GemPackageTask
  def gem_path
    File.join(package_dir,gem_file)
  end
end

package = Rake::GemPackageTask.new(specification) { }
gem = package.gem_path

desc "Install the gem"
task :install => "package" do
  sh "gem install #{gem}"
end

desc "Run the installed demonstration program"
task :run_installed => :install do
  sh demo_name
end
