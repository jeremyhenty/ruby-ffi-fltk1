
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


# These tasks auto-generate Ruby libraries that contain constants
# defined in the FTLK headers. They determine the values of the
# constants by building shared libraries and loading them with FFI.
# They use ERb to create Ruby and C++ source from lists of constant
# names.

module Build

  module_function

  # directories

  # headers
  HEADER_DIR = "include"

  # boxes

  module Box

    module_function

    def names
      @@names ||= names_
    end

    def names_

      enumeration_pattern = %r{
\benum\b
[[:space:]]+
\bFl_Boxtype\b
[[:space:]]*
\{
(.*?) # enumeration contents
\}[[:space:]]*;
}mx

      # extract the Fl_Boxtype enumeration from the FLTK header
      enumerations =
        Build.header_pp(File.join(Build::HEADER_DIR,"enumerations.h"))
      raise Build::Error, "missing Fl_Boxtype enumeration" unless
        enumeration_match = enumeration_pattern.match(enumerations)
      enumeration = enumeration_match.captures.first

      # extract the names from the enumeration
      enum_pattern = %r{(FL_[[:alpha:]_]+)}
      enum_names = enumeration.split(',').collect do |enum|
        next unless enum_match = enum_pattern.match(enum)
        enum_match.captures.first
      end.compact

      # remove "FL_FREE_BOXTYPE", it's not a real box type
      raise Build::Error, "missing FL_FREE_BOXTYPE" unless
        enum_names.last == "FL_FREE_BOXTYPE"
      enum_names.pop

      return enum_names
    end

    def mangle_name(name)
      raise Build::Error, "invalid Box type name: '#{name}'" unless
        name_match = NAME_PATTERN.match(name)
      return name_match.captures.first
    end

    def values
      @@values ||= values_
    end

    def values_

      require "ffi"
      extend FFI::Library
      ffi_lib File.join(Build::Auto::DIR, "box.so")
      attach_function :ffi_fl_boxes, [ ], :pointer

      return ffi_fl_boxes.read_array_of_int(names.size)
    end

    NAME_PATTERN =
      %r{\AFL_(.*)\z}

    box_dl = File.join(Build::Auto::DIR, "box.so")
    box_dl_cc = File.join(Build::Auto::DIR, "box.cc")
    box_dl_src = File.join(Build::Auto::ERB_DIR, "box.cc.erb")

    box_init_dl = File.join(Build::AUTO_LIB_DIR, "box_init.so")
    box_init_dl_cc = File.join(Build::Auto::DIR, "box_init.cc")
    box_init_dl_src = File.join(Build::Auto::ERB_DIR, "box_init.cc.erb")

    box_ruby = File.join(Build::AUTO_LIB_DIR, "box.rb")
    box_ruby_src = File.join(Build::Auto::ERB_DIR, "box.rb.erb")

    task :build => box_ruby

    file box_ruby => [ Build::AUTO_LIB_DIR,
                       box_ruby_src, box_dl ] do |t|
      Build::Auto.erb(box_ruby_src, t.name)
    end

    file box_dl => [ Build::Auto::DIR, "extra.rb", box_dl_cc ] do |t|
      Build.dl_compile(t.name, t.prerequisites.last)
    end

    file box_dl_cc => [ Build::Auto::DIR, box_dl_src ] do |t|
      Build::Auto.erb(t.prerequisites.last, t.name)
    end

    task :build => box_init_dl

    file box_init_dl => [ Build::Auto::DIR, "extra.rb", box_init_dl_cc ] do |t|
      Build.dl_compile(t.name, t.prerequisites.last)
    end

    file box_init_dl_cc => [ Build::Auto::DIR, box_init_dl_src ] do |t|
      Build::Auto.erb(t.prerequisites.last, t.name)
    end
  end
end
