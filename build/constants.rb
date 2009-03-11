
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

require "./build/auto"

module Build

  class Constants < Auto

    class Error < Build::Error ; end

    extension = Module.new do

      def define_constant_methods(*methods)
        _module = Module.new do
          methods.each do |_method|
            define_method(_method) do |value|
              define_method(_method) do
                value
              end
            end
          end
        end
        extend _module
      end

      def memoize(*methods)
        methods.each do |_method|
          define_method(_method) do
            memoized(_method)
          end
        end
      end

      def values(dl_path, name, size)
        require "ffi"
        extend FFI::Library
        ffi_lib dl_path
        attach_function name, [ ], :pointer
        send(name).read_array_of_int(size)
      end
    end

    extend extension

    memoize \
    :dl_path, :dl_source, :name_base, :name_root,
    :ffi_name, :fl_name, :cc_name_root, :cc_header,
    :names, :values, :ruby_names

    def memoized(_method)
      @memoized[_method] ||=
        send("#{_method}_")
    end

    def initialize
      @memoized = { }
      erb_tasks
      ruby_task
      dl_task
    end

    def erb_tasks
      dl_template = File.join(Auto::ERB_DIR, "list.cc")
      erb_task(dl_template, dl_source)
    end

    def ruby_task
      ruby_path = File.join(Auto::LIB_DIR, "#{name_root}.rb")
      ruby_template = File.join(Auto::ERB_DIR, "list.rb")
      task :build => ruby_path
      erb_task(ruby_template, ruby_path)
      file ruby_path => dl_path
    end

    def dl_task
      dl_compile_task(dl_path, dl_source)
    end

    def dl_path_
      File.join(Auto::DIR, "#{name_root}.so")
    end

    def dl_source_
      File.join(Auto::DIR, "#{name_root}.cc")
    end

    def name_base_
      self.class.name.sub(%r{\A.*::}, "")
    end

    def name_root_
      name_base.downcase
    end

    def fl_name_ ; name_base ; end

    define_constant_methods \
    :enumeration_pattern,
    :enumeration_item_separator,
    :enumeration_item_pattern

    def header
      header_dir = Build.fltk_config[:header_dir]
      return IO.read(File.join(header_dir, cc_header))
    end

    def enum_names(source)
      # extract the type enumeration
      raise Constants::Error,
      "missing #{fl_name} type enumeration" unless
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

    def values_
      self.class.values(dl_path, ffi_name, names.size)
    end

    def ffi_name_
      "ffi_#{cc_name_root}"
    end

    def ruby_class_name ; name_base ; end

    def ruby_names_
      names.collect do |name|
        ruby_name(name)
      end
    end

    module RubyNames
      # prepackaged definitions of ruby names

      module Names
        def ruby_names_ ; names ; end
      end

      module Pattern
        def self.included(mod)
          mod.define_constant_methods :ruby_name_pattern
        end

        def ruby_name(name)
          raise Constants::Error,
          "invalid #{fl_name} type name: '#{name}'" unless
            name_match = ruby_name_pattern.match(name)
          name_match.captures.first
        end
      end
    end

    def cc_variable ; cc_name_root ; end

    def include_cc_header
      comment_strip
      "#include <FL/#{cc_header}>"
    end
  end

  # boxes

  class Box < Constants

    def names_
      _names = enum_names(header)

      # remove "FL_FREE_BOXTYPE", it's not a real box type
      raise Constants::Error, "missing FL_FREE_BOXTYPE" unless
        _names.last == "FL_FREE_BOXTYPE"
      _names.pop

      return _names
    end

    def cc_name(name) ; name ; end
    def cc_name_root_ ; "boxes" ; end
    def cc_header_ ; "Enumerations.H" ; end

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

    def initialize
      super
      box_init_dl = File.join(Auto::LIB_DIR, "box_init.so")
      box_init_dl_cc = File.join(Auto::DIR, "box_init.cc")
      box_init_template = File.join(Auto::ERB_DIR, "box_init.cc")
      erb_task(box_init_template, box_init_dl_cc)
      dl_compile_task(box_init_dl, box_init_dl_cc)
      task :build => box_init_dl
    end

    instance
  end

  # Widget types

  class Types < Constants

    def fl_name_
      begin
        base = name_base.gsub(%r{([^[:upper:]])([[:upper:]])}
                              ) { "#{$1}_#{$2}" }
        "Fl_#{base}"
      end
    end

    def cc_name_root ; "#{name_root}_types" ; end
    def cc_header_ ; "#{fl_name}.H" ; end

    enumeration_pattern %r{\benum\b[[:space:]]*\{(.*?)\}}m
    enumeration_item_separator "\n"
    enumeration_item_pattern %r{\A[[:blank:]]*([[:alpha:]_]+)[[:blank:]]*=}

    def names_

      _class_declaration_pattern = %r{
^\bclass\b
[^\n]*
\b#{fl_name}\b
[^\n]*
\{
(.*?) # class contents
^\}[[:space:]]*;
}mx

      raise Constants::Error,
      "missing #{fl_name} class declaration" unless
        _class_declaration_match =
        _class_declaration_pattern.match(header)
      _class_declaration = _class_declaration_match.captures.first
      return enum_names(_class_declaration)
    end

    def cc_name(name) ; "#{fl_name}::#{name}" ; end
  end

  class Types1 < Types
    include Constants::RubyNames::Names
  end

  # Pack
  class Pack < Types1
    instance
  end

  # Scroll
  class Scroll < Types1
    instance
  end

  class Types2 < Types
    def cc_name(name) ; name ; end
  end

  # MenuItem
  class MenuItem < Types2

    def names_ ; enum_names(header) ; end

    include Constants::RubyNames::Pattern
    ruby_name_pattern %r{\AFL_(?:MENU_)?(.*)\z}

    instance
  end

  class Types3 < Types2

    # convert "#define FL_FOO" to a Ruby constant FOO

    def names_
      pattern = %r{#define[[:blank:]]+(FL_[_A-Z]+)}
      header.scan(pattern).collect { |match| match[0] }
    end

    def ruby_name(name)
      ruby_name_get(name.dup, name)
    end

    def ruby_name_get(name, name_orig)
      raise Constants::Error, "invalid %s type: %s" %
        [ fl_name, name_orig ] unless
        name.sub!(%r{\AFL_}, "")
      name
    end
  end

  # Input
  class Input < Types3

    def fl_name_
      "#{super}_" # the header is "Fl_Input_.H"
    end

    # remove some extra stuff from the C macro names
    def ruby_name_get(name, name_orig)
      name.sub!("_INPUT", "")
      name.sub!("NORMAL_", "")
      super(name, name_orig)
    end

    instance
  end

  # Valuator
  class Valuator < Types3
    instance
  end

  # Counter
  class Counter < Types3

    # remove some extra stuff from the C macro names
    def ruby_name_get(name, name_orig)
      name.sub!("_COUNTER", "")
      super(name, name_orig)
    end

    instance
  end

end
