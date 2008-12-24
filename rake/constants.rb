
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


# These tasks auto-generate Ruby libraries that contain constants
# defined in the FTLK headers. They determine the values of the
# constants by building shared libraries and loading them with FFI.
# They use ERb to create Ruby and C++ source from lists of constant
# names.

module Project

  module_function

  # directories

  # ERb
  ERB_DIR = "erb"
  def run_erb(binding,in_path,out_path)
    require "erb"
    content = ERB.new(IO.read(in_path)).result(binding)
    File.open(out_path, "w") { |output| output.write(content) }
  end

  # auto-generated intermediates
  AUTO_DIR = "auto"
  directory AUTO_DIR
  CLEAN << AUTO_DIR

  # auto-generated targets
  lib_dir = "lib/ffi/fltk"
  directory lib_dir
  AUTO_LIB_DIR = File.join(lib_dir, "auto")
  directory AUTO_LIB_DIR
  CLOBBER << AUTO_LIB_DIR

  # boxes

  module Box

    module_function

    names =
      [
       "FL_FLAT_BOX",
       "FL_UP_BOX",
       "FL_DOWN_BOX",
      ]

    NAME_PATTERN =
      %r{\AFL_(.*)_BOX\z}

    def mangle_name(name)
      raise "invalid Box type name: #{name}" unless
        name_match = NAME_PATTERN.match(name)
      return name_match.captures.first
    end

    box_dl = File.join(Project::AUTO_DIR, "box.so")
    box_dl_cc = File.join(Project::AUTO_DIR, "box.cc")
    box_dl_src = File.join(Project::ERB_DIR, "box.cc.erb")
    box_ruby = File.join(Project::AUTO_LIB_DIR, "box.rb")
    box_ruby_src = File.join(Project::ERB_DIR, "box.rb.erb")

    task :build => box_ruby

    file box_ruby => [ Project::AUTO_LIB_DIR,
                       box_ruby_src, box_dl ] do |t|

      require "ffi"
      extend FFI::Library
      ffi_lib box_dl
      attach_function :ffi_fl_boxes, [ ], :pointer

      values = ffi_fl_boxes.read_array_of_int(names.size)
      Project.run_erb(binding, box_ruby_src, t.name)
    end

    file box_dl => [ Project::AUTO_DIR, box_dl_cc ] do |t|
      config = fltk_config
      sh \
      "#{config[:cxx]} -shared -fpic " \
      "#{config[:cxxflags]} #{config[:ldflags]} " \
      "#{Project::EXTRA_CPP_DEFINES * ' '} " \
      "-o #{t.name} #{t.prerequisites.last}"
    end

    file box_dl_cc => [ Project::AUTO_DIR, box_dl_src ] do |t|
      Project.run_erb(binding, t.prerequisites.last, t.name)
    end
  end
end
