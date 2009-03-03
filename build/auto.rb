
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

require "singleton"

module Build

  # directories
  FFI_DIR = "lib/ffi"
  LIB_DIR = File.join(FFI_DIR, "fltk1")
  directory LIB_DIR

  class Auto

    include Singleton

    # directories

    DIR = "auto"
    directory DIR
    CLEAN << DIR

    LIB_DIR = File.join(Build::LIB_DIR, "auto")
    directory LIB_DIR
    CLOBBER << LIB_DIR

    # comments

    def comment_prefix
      @comment_prefix ||=
        case @target
        when %r{\.rb$}; "#"
        when %r{\.cc$}; "//"
        else raise Build::Error,
          "the comment prefix for #{@target} is unknown"
        end
    end

    # auto-generation notice

    def generated
      comment_strip
      GENERATED.gsub(%r{^}, comment_prefix + " ")
    end

    GENERATED = <<EOS

This file was auto-generated. Do not edit it!

EOS

    # ERb

    ERB_DIR = "erb"

    def erb_task(source, target)
      target_dir = File.dirname(target)
      directory target_dir
      file target => [ target_dir, source ] do
        erb(source, target)
      end
    end

    attr_reader :erb_out

    def erb(source, target)
      require "erb"
      @comment_prefix = nil
      @comment_strip_regexp = nil
      @source  = source
      @target = target
      input = IO.read(@source)
      template = ERB.new(input, nil, nil, "@erb_out")
      output = template.result(binding)
      File.open(@target, "w") { |out_file| out_file.write(output) }
    end

    def comment_strip
      @comment_strip_regexp ||=
        Regexp.new('[[:blank:]]*' +
                   Regexp.escape(comment_prefix) +
                   '[[:blank:]]*\z')
      @erb_out.sub!(@comment_strip_regexp, "")
    end

    # compiling
    def dl_compile_task(path,source)
      file path => [ File.dirname(path), source ] do |t|
        Build.dl_compile(t.name, t.prerequisites.last)
      end
    end
  end
end
