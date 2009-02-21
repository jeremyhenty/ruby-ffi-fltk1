
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

require "./rake/auto"

module Build

  class Constants_ < Auto
    def self.constant_method(_method)
      raise Build::Error,
      "constant method %s has not been defined" % [ _method ]
    end
  end

  class Constants < Constants_

    module Extension

      def define_constant_methods(*methods)
        delegate_to_class(*methods)
        _module = Module.new do
          methods.each do |_method|
            define_method(_method) do |*args|
              constant_method(_method, *args)
            end
          end
        end
        extend _module
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
          return value || superclass.constant_method(_method)
        when 1
          value, = *args
          (@constants ||= Hash.new)[_method] = value
        else
          raise ArgumentError,
          "wrong number of arguments (%d for 1)" % [ count ]
        end
      end

      def defaults
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
          File.join(Auto::LIB_DIR, "#{name_root}.rb")
      end

      def ruby_template
        @ruby_template ||=
          File.join(Auto::ERB_DIR, "list.rb")
      end

      def dl_task
        dl_compile_task(dl_path, dl_source)
      end

      def dl_path
        @dl_path ||=
          File.join(Auto::DIR, "#{name_root}.so")
      end

      def dl_source
        @dl_source ||=
          File.join(Auto::DIR, "#{name_root}.cc")
      end

      def dl_template
        @dl_template ||=
          File.join(Auto::ERB_DIR, "list.cc")
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

      def fl_name ; @fl_name ||= fl_name_ ; end
      def fl_name_ ; name_base ; end

      def header(path)
        header_dir = Build.fltk_config[:header_dir]
        return IO.read(File.join(header_dir, path))
      end

      def enum_names(source)
        # extract the type enumeration
        raise Build::Error, "missing #{fl_name} type enumeration" unless
          enumeration_match = enumeration_pattern.match(source)
        enumeration = enumeration_match.captures.first

        # extract the names from the enumeration
        separator = enumeration_item_separator
        pattern = enumeration_item_pattern
        enumeration.split(separator).collect do |enum|
          next unless enumeration_item_match = pattern.match(enum)
          enumeration_item_match.captures.first
        end.compact
      end
    end

    extend Extension

    define_constant_methods \
    :cc_name_root, :cc_headers,
    :enumeration_pattern,
    :enumeration_item_separator,
    :enumeration_item_pattern

    delegate_to_class :name_base, :names, :values, :fl_name, :ffi_name

    def ruby_class_name ; name_base ; end

    def ruby_names
      @ruby_names ||= ruby_names_
    end

    module RubyNames
      # prepackaged definitions of ruby_names_

      module Names
        def ruby_names_ ; names ; end
      end

      module Pattern
        def self.included(mod)
          mod.define_constant_methods :ruby_name_pattern
        end

        def ruby_names_
          names.collect do |name|
            raise Build::Error,
            "invalid #{fl_name} type name: '#{name}'" unless
              name_match = ruby_name_pattern.match(name)
            name_match.captures.first
          end
        end
      end
    end

    def cc_variable ; cc_name_root ; end

    def include_cc_headers
      comment_strip
      cc_headers.collect do |header|
        "#include<FL/#{header}>"
      end * "\n"
    end
  end

  # boxes

  class Box < Constants

    def self.names_
      _names = enum_names(header("Enumerations.H"))

      # remove "FL_FREE_BOXTYPE", it's not a real box type
      raise Build::Error, "missing FL_FREE_BOXTYPE" unless
        _names.last == "FL_FREE_BOXTYPE"
      _names.pop

      return _names
    end

    def cc_name(name) ; name ; end

    cc_name_root "boxes"
    cc_headers [ "Enumerations.H" ]

    enumeration_pattern %r{
\benum\b
[[:space:]]+
\bFl_Boxtype\b
[[:space:]]*
\{
(.*?) # enumeration contents
\}[[:space:]]*;
}mx

    enumeration_item_separator ","
    enumeration_item_pattern %r{(FL_[[:alpha:]_]+)}

    include Constants::RubyNames::Pattern
    ruby_name_pattern %r{\AFL_(.*)\z}

    defaults

    box_init_dl = File.join(Auto::LIB_DIR, "box_init.so")
    box_init_dl_cc = File.join(Auto::DIR, "box_init.cc")
    box_init_template = File.join(Auto::ERB_DIR, "box_init.cc")
    erb_task(box_init_template, box_init_dl_cc)
    dl_compile_task(box_init_dl, box_init_dl_cc)
    task :build => box_init_dl
  end

  # Widget types

  class Types < Constants

    module Extension

      def names_
        _header = header("#{fl_name}.H")
        raise Build::Error, "missing #{fl_name} class declaration" unless
          _class_decl_match = class_declaration_pattern.match(_header)
        _class_decl = _class_decl_match.captures.first
        return enum_names(_class_decl)
      end

      def class_declaration_pattern
        %r{
^\bclass\b
[^\n]*
\b#{fl_name}\b
[^\n]*
\{
(.*?) # class contents
^\}[[:space:]]*;
}mx
      end

      def fl_name_
        begin
          base = name_base.gsub(%r{([^[:upper:]])([[:upper:]])}
                                ) { "#{$1}_#{$2}" }
          "Fl_#{base}"
        end
      end

      def defaults
        cc_name_root "#{name_root}_types"
        cc_headers [ "#{fl_name}.H" ]
        super
      end
    end

    extend Extension

    enumeration_pattern %r{\benum\b[[:space:]]*\{(.*?)\}}m
    enumeration_item_separator "\n"
    enumeration_item_pattern %r{\A[[:blank:]]*([[:alpha:]_]+)[[:blank:]]*=}

    include Constants::RubyNames::Names

    def cc_name(name) ; "#{fl_name}::#{name}" ; end
  end

  # Pack
  class Pack < Types
    defaults
  end

  # Scroll
  class Scroll < Types
    defaults
  end

  # MenuItem
  class MenuItem < Types

    def self.names_
      enum_names(header("#{fl_name}.H"))
    end

    def cc_name(name) ; name ; end

    include Constants::RubyNames::Pattern
    ruby_name_pattern %r{\AFL_(?:MENU_)?(.*)\z}

    defaults
  end
end
