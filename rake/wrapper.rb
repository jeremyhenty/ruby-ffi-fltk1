
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


module Build

  class Auto

    def widget_class(&block)
      Widget_Class.new(self).run(&block)
    end

    class Widget_Class

      def initialize(auto)
        @auto = auto
      end

      def run
        @auto.comment_strip
        raise Build::Error, "cannot find a widget class declaration" unless
          declaration_match = DECLARATION_PATTERN.match(@auto.erb_out)
        _class_name, = *declaration_match.captures
        raise Build::Error, "invalid widget class name #{class_name}" unless
          name_match = NAME_PATTERN.match(_class_name)
        _class_key, = *name_match.captures
        _class_key.downcase!
        puts "class: #{_class_name}"
        yield
        @auto.comment_strip
        @auto.erb_out << <<EXTERN
// auto-generated definitions : begin

extern "C" {

void *ffi_#{_class_key}_new_xywhl(int x, int y, int w, int h, const char *l)
{
  return new #{_class_name}(x, y, w, h, l);
}

}

// auto-generated definitions : end
EXTERN
      end

      DECLARATION_PATTERN =
        %r{^class[[:blank:]]+([^[:blank:]]+).*\n\{\z}

      NAME_PATTERN =
        %r{\AFFI_(.*)\z}
    end
  end

  desc "Compile the wrapper library"
  library = File.join(Auto::LIB_DIR, "fltk.so")
  source = File.join(Auto::DIR, "fltk.cc")
  file library => [ "extra.rb", source ] do |t|
    puts "building '#{t.name}'"
    dl_compile(t.name, t.prerequisites.last)
  end
  task :build => library
end
