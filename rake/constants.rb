
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

module Build

  module_function

  # auto-generation notices

  def auto_generated_cc
    auto_generated "// "
  end

  def auto_generated_rb
    auto_generated "# "
  end

  def auto_generated(prefix)
    AUTO_GENERATED.gsub(%r{^}, prefix)
  end

  AUTO_GENERATED = <<EOS

This file was auto-generated. Do not edit it!

EOS

  # directories

  # headers
  HEADER_DIR = "include"

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
  AUTO_LIB_DIR = File.join(LIB_DIR, "auto")
  directory AUTO_LIB_DIR
  CLOBBER << AUTO_LIB_DIR

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
      raise "missing Fl_Boxtype enumeration" unless
        enumeration_match = enumeration_pattern.match(enumerations)
      enumeration = enumeration_match.captures.first

      # extract the names from the enumeration
      enum_pattern = %r{(FL_[[:alpha:]_]+)}
      enum_names = enumeration.split(',').collect do |enum|
        next unless enum_match = enum_pattern.match(enum)
        enum_match.captures.first
      end.compact

      # remove "FL_FREE_BOXTYPE", it's not a real box type
      raise "missing FL_FREE_BOXTYPE" unless
        enum_names.last == "FL_FREE_BOXTYPE"
      enum_names.pop

      return enum_names
    end

    def mangle_name(name)
      raise "invalid Box type name: '#{name}'" unless
        name_match = NAME_PATTERN.match(name)
      return name_match.captures.first
    end

    NAME_PATTERN =
      %r{\AFL_(.*)\z}

    box_dl = File.join(Build::AUTO_DIR, "box.so")
    box_dl_cc = File.join(Build::AUTO_DIR, "box.cc")
    box_dl_src = File.join(Build::ERB_DIR, "box.cc.erb")
    box_ruby = File.join(Build::AUTO_LIB_DIR, "box.rb")
    box_ruby_src = File.join(Build::ERB_DIR, "box.rb.erb")

    task :build => box_ruby

    file box_ruby => [ Build::AUTO_LIB_DIR,
                       box_ruby_src, box_dl ] do |t|

      require "ffi"
      extend FFI::Library
      ffi_lib box_dl
      attach_function :ffi_fl_boxes, [ ], :pointer

      values = ffi_fl_boxes.read_array_of_int(names.size)
      Build.run_erb(binding, box_ruby_src, t.name)
    end

    file box_dl => [ Build::AUTO_DIR, "extra.rb", box_dl_cc ] do |t|
      Build.dl_compile(t.name, t.prerequisites.last)
    end

    file box_dl_cc => [ Build::AUTO_DIR, box_dl_src ] do |t|
      Build.run_erb(binding, t.prerequisites.last, t.name)
    end
  end
end
