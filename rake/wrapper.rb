
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


require "./rake/auto"

module Build

  class FLTK < Auto

    def widget_class(&block)
      Widget_Class.new(self).run(&block)
    end

    class Widget_Class

      def initialize(auto)
        @auto = auto
      end

      def run

        # parse the class declaration
        @auto.comment_strip
        raise Build::Error, "cannot find a widget class declaration" unless
          declaration_match = DECLARATION_PATTERN.match(@auto.erb_out)
        ffi_class_name, = *declaration_match.captures
        raise Build::Error, "invalid widget class name #{class_name}" unless
          name_match = NAME_PATTERN.match(ffi_class_name)
        ffi_class_key, = *name_match.captures
        fl_class_name = "Fl_#{ffi_class_key}"
        ffi_class_key.downcase!
        puts "line %4s: class: %s" %
          [ caller[1].match(CALLER_PATTERN)[1], ffi_class_name ]

        # augment the class declaration
        @auto.erb_out.sub!(DECLARATION_END_PATTERN) do
          " : public FFI, public #{fl_class_name}#{$1}"
        end

        # add the automatic declarations
        @auto.comment_strip
        @auto.erb_out << <<DECLARATIONS

// auto-generated declarations : begin
public:
  #{ffi_class_name}(int x, int y, int w, int h, const char *l);
  virtual ~#{ffi_class_name}();
// auto-generated declarations : end
DECLARATIONS

        yield

        # add the automatic definitions
        @auto.comment_strip
        @auto.erb_out << <<DEFINITIONS
// auto-generated definitions : begin

#{ffi_class_name}::#{ffi_class_name}(int x, int y, int w, int h, const char *l) :
  #{fl_class_name}(x, y, w, h, l)
{
}

#{ffi_class_name}::~#{ffi_class_name}()
{
}

extern "C" {

void *ffi_#{ffi_class_key}_new_xywhl(int x, int y, int w, int h, const char *l)
{
  return new #{ffi_class_name}(x, y, w, h, l);
}

}

// auto-generated definitions : end
DEFINITIONS
      end

      DECLARATION_PATTERN =
        %r{^class[[:blank:]]+([^[:blank:]]+)[[:blank:]]*\n\{\z}x

      NAME_PATTERN =
        %r{\AFFI_(.*)\z}

      CALLER_PATTERN =
        %r{:([[:digit:]]+):}

      DECLARATION_END_PATTERN =
        %r{[[:blank:]]*(\n.*)\z}
    end

    library = File.join(Auto::LIB_DIR, "fltk.so")
    source = File.join(Auto::DIR, "fltk.cc")
    template = File.join(Auto::ERB_DIR, "fltk.cc")

    erb_task(template, source)
    dl_compile_task(library, source)
    task :build => library
  end
end
