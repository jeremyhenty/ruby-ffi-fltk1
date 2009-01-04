
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


# Tasks and methods to auto-generate files from templates using ERb.

module Build

  # directories
  FFI_DIR = "lib/ffi"
  LIB_DIR = File.join(FFI_DIR, "fltk1")

  class Auto

    # directories

    DIR = "auto"
    CLEAN << DIR

    LIB_DIR = File.join(Build::LIB_DIR, "auto")
    CLOBBER << LIB_DIR

    # initialize in and out paths

    def initialize(in_path, out_path)
      @in_path  = in_path
      @out_path = out_path
    end

    # comments

    def comment_prefix
      @comment_prefix ||=
        case @out_path
        when %r{\.rb$}; "#"
        when %r{\.cc$}; "//"
        else raise Build::Error,
          "the comment prefix for #{@out_path} is unknown"
        end
    end

    # auto-generation notice

    def generated
      GENERATED.gsub(%r{^}, comment_prefix + " ")
    end

    GENERATED = <<EOS

This file was auto-generated. Do not edit it!

EOS

    # ERb

    def self.erb(*args)
      new(*args).erb
    end

    def erb
      require "erb"
      content = ERB.new(IO.read(@in_path)).result(binding)
      File.open(@out_path, "w") { |output| output.write(content) }
    end

    [
     [ "auto", DIR     ],
     [ "lib",  LIB_DIR ],
    ].each do |erb_dir, prefix|
        Dir.glob("erb/#{erb_dir}/**/*") do |source|
        target = File.join(prefix, source.sub(%r{^erb/.*?/}, ""))
        target_dir = File.dirname(target)
        directory target_dir
        file target => [ target_dir, source ] do
          erb(source, target)
        end
      end
    end
  end
end
