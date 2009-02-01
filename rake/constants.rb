
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

  # headers
  HEADER_DIR = "include"

  module Constants

    def names
      @names ||= names_
    end

    def values
      @values ||=
        begin
          require "ffi"
          extend FFI::Library
          ffi_lib File.join(Build::Auto::DIR, dl_name)
          attach_function ffi_name, [ ], :pointer
          send(ffi_name).read_array_of_int(names.size)
        end
    end

    def name_root
      @name_root ||= name.sub(%r{\A.*::}, "").downcase
    end

    def dl_name
      @dl_name ||= "#{name_root}.so"
    end

    def ffi_name
      @ffi_name ||= ffi_name_
    end

    def create_ruby_task
      task :build => ruby_path
      file ruby_path => dl_path
    end

    def ruby_path
      @ruby_path ||=
        File.join(Build::Auto::LIB_DIR, "#{name_root}.rb")
    end

    def dl_path
      @dl_path ||=
        File.join(Build::Auto::DIR, dl_name)
    end

  end

  # boxes

  module Box

    extend Constants

    module_function

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

    def ffi_name_ ; :ffi_fl_boxes ; end

    NAME_PATTERN =
      %r{\AFL_(.*)\z}

    box_dl = File.join(Build::Auto::DIR, dl_name)
    box_dl_cc = File.join(Build::Auto::DIR, "box.cc")

    box_init_dl = File.join(Build::Auto::LIB_DIR, "box_init.so")
    box_init_dl_cc = File.join(Build::Auto::DIR, "box_init.cc")

    file box_dl => [ Build::Auto::DIR, box_dl_cc ] do |t|
      Build.dl_compile(t.name, t.prerequisites.last)
    end

    create_ruby_task

    task :build => box_init_dl

    file box_init_dl => [ Build::Auto::DIR, box_init_dl_cc ] do |t|
      Build.dl_compile(t.name, t.prerequisites.last)
    end
  end

  # Pack

  module Pack

    extend Constants

    module_function

    def names_

      _class_decl_pattern = %r{
^\bclass\b
[^\n]*
\bFl_Pack\b
[^\n]*
\{
(.*?) # class contents
^\}[[:space:]]*;
}mx

      enumeration_pattern =
        %r{\benum\b[[:space:]]*\{(.*?)\}}m

      # extract the class declaration from the FLTK header
      pack_header =
        Build.header_pp(File.join(Build::HEADER_DIR,"pack.h"))
      raise Build::Error, "missing Fl_Pack class declaration" unless
        _class_decl_match = _class_decl_pattern.match(pack_header)
      _class_decl = _class_decl_match.captures.first

      # extract the type enumeration from the class declaration
      raise Build::Error, "missing Fl_Pack type enumeration" unless
        enumeration_match = enumeration_pattern.match(_class_decl)
      enumeration = enumeration_match.captures.first

      # extract the names from the enumeration
      enum_pattern = %r{([[:alpha:]_]+)}
      enum_names = enumeration.split(',').collect do |enum|
        next unless enum_match = enum_pattern.match(enum)
        enum_match.captures.first
      end.compact

      return enum_names
    end

    def ffi_name_ ; :ffi_fl_pack_types ; end

    pack_dl = File.join(Build::Auto::DIR, dl_name)
    pack_dl_cc = File.join(Build::Auto::DIR, "pack.cc")
    file pack_dl => [ Build::Auto::DIR, pack_dl_cc ] do |t|
      Build.dl_compile(t.name, t.prerequisites.last)
    end

    create_ruby_task
  end
end
