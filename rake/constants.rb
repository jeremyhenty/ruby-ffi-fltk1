
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

  class Constants < Build::Auto

    TEMPLATE_DIR = File.join(Build::Auto::ERB_DIR, "template")

    module Extension

      def define_constant_methods(*methods)
        methods.each do |_method|
          delegate_to_class_(_method)
          (class << self ; self ; end).class_eval do
            define_method(_method) do |*args|
              constant_method(_method, *args)
            end
          end
        end
      end

      def delegate_to_class(*methods)
        methods.each do |_method|
          delegate_to_class_(_method)
        end
      end

      def delegate_to_class_(_method)
        define_method(_method) do
          self.class.send(_method)
        end
      end

      def constant_method(_method, *args)
        count = args.size
        case count
        when 0
          value = @constants && @constants[_method]
          raise Build::Error,
          "constant method %s has not been defined" % [ _method ] unless value
          return value
        when 1
          value, = *args
          (@constants ||= Hash.new)[_method] = value
        else
          raise ArgumentError,
          "wrong number of arguments (%d for 1)" % [ count ]
        end
      end

      def default_tasks
        erb_tasks
        ruby_task
        dl_task
      end

      def erb_tasks
        erb_task(dl_template, dl_source)
      end

      def ruby_task
        task :build => ruby_path
        erb_task(ruby_template, ruby_path)
        file ruby_path => dl_path
      end

      def ruby_path
        @ruby_path ||=
          File.join(Build::Auto::LIB_DIR, "#{name_root}.rb")
      end

      def ruby_template
        @ruby_template ||=
          File.join(TEMPLATE_DIR, "list.rb")
      end

      def dl_task
        dl_compile_task(dl_path, dl_source)
      end

      def dl_path
        @dl_path ||=
          File.join(Build::Auto::DIR, "#{name_root}.so")
      end

      def dl_source
        @dl_source ||=
          File.join(Build::Auto::DIR, "#{name_root}.cc")
      end

      def dl_template
        @dl_template ||=
          File.join(TEMPLATE_DIR, "list.cc")
      end

      def dl_compile_task(path,source)
        file path => [ File.dirname(path), source ] do |t|
          Build.dl_compile(t.name, t.prerequisites.last)
        end
      end

      def name_base
        @name_base ||= name.sub(%r{\A.*::}, "")
      end

      def name_root
        @name_root ||= name_base.downcase
      end

      def values
        @values ||=
          begin
            require "ffi"
            extend FFI::Library
            ffi_lib dl_path
            attach_function ffi_name, [ ], :pointer
            send(ffi_name).read_array_of_int(names.size)
          end
      end

      def names
        @names ||= names_
      end

      def ffi_name ; "ffi_#{cc_name_root}" ; end

      def header(path)
        header_dir = Build.fltk_config[:header_dir]
        return IO.read(File.join(header_dir, path))
      end
    end

    extend Extension

    define_constant_methods :cc_name_root, :cc_headers
    delegate_to_class :name_base, :names, :values, :ffi_name

    def ruby_class_name ; name_base ; end

    def ruby_names
      @ruby_names ||= ruby_names_
    end

    def cc_variable ; cc_name_root ; end

    def include_cc_headers
      "\n" + cc_headers.collect do |header|
        "#include<FL/#{header}>"
      end * "\n"
    end
  end

  # boxes

  class Box < Constants

    def self.names_

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
      enumerations = header("Enumerations.h")
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

    def ruby_names_
      names.collect do |name|
        raise Build::Error, "invalid Box type name: '#{name}'" unless
          name_match = NAME_PATTERN.match(name)
        name_match.captures.first
      end
    end

    def cc_name(name) ; name ; end

    cc_name_root "boxes"
    cc_headers [ "Enumerations.H" ]

    NAME_PATTERN =
      %r{\AFL_(.*)\z}

    default_tasks

    box_init_dl = File.join(Build::Auto::LIB_DIR, "box_init.so")
    box_init_dl_cc = File.join(Build::Auto::DIR, "box_init.cc")
    box_init_template = File.join(TEMPLATE_DIR, "box_init.cc")
    erb_task(box_init_template, box_init_dl_cc)
    dl_compile_task(box_init_dl, box_init_dl_cc)
    task :build => box_init_dl
  end

  # Pack

  class Pack < Constants

    def self.names_

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
      pack_header = header("Fl_Pack.h")
      raise Build::Error, "missing Fl_Pack class declaration" unless
        _class_decl_match = _class_decl_pattern.match(pack_header)
      _class_decl = _class_decl_match.captures.first

      # extract the type enumeration from the class declaration
      raise Build::Error, "missing Fl_Pack type enumeration" unless
        enumeration_match = enumeration_pattern.match(_class_decl)
      enumeration = enumeration_match.captures.first

      # extract the names from the enumeration
      enum_pattern = %r{\A[[:blank:]]*([[:alpha:]_]+)[[:blank:]]+=}
      enum_names = enumeration.split("\n").collect do |enum|
        next unless enum_match = enum_pattern.match(enum)
        enum_match.captures.first
      end.compact

      return enum_names
    end

    def ruby_names_ ; names ; end

    def cc_name(name) ; "Fl_Pack::#{name}" ; end

    cc_name_root "pack_types"
    cc_headers [ "Fl_Pack.H" ]

    default_tasks
  end
end
