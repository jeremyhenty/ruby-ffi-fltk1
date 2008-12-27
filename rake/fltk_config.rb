
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


# Call 'fltk-config' to get the FLTK development environment
# configuration.

module Build

  module_function

  # Build hooks.  Add code to extra.rb to modify these.
  EXTRA_CPP_DEFINES = [ ]

  # directories
  FFI_DIR = "lib/ffi"
  LIB_DIR = File.join FFI_DIR, "fltk1"
  directory LIB_DIR

  # auto-generated targets
  AUTO_LIB_DIR = File.join(LIB_DIR, "auto")
  directory AUTO_LIB_DIR
  CLOBBER << AUTO_LIB_DIR

  def fltk_config
    @@fltk_config ||= fltk_config_
  end

  def fltk_config_
    config = Hash.new
    [ :version, :cxx, :cxxflags, :ldflags ].each do |key|
      config[key] = %x{ fltk-config --#{key} }.chomp
      raise Build::Error,
      "configuration check for --#{key} failed" unless $?.success?
    end
    return config
  end

  def dl_compile(dl_path, *source_paths)
    require "./extra"
    config = fltk_config
    sh \
    "#{config[:cxx]} -shared -fpic " \
    "#{config[:cxxflags]} #{config[:ldflags]} " \
    "#{EXTRA_CPP_DEFINES * ' '} " \
    "-o #{dl_path} #{source_paths * ' '}"
  end

  def header_pp(header_path)
    config = fltk_config
    return %x{
    #{config[:cxx]} -E \
    #{config[:cxxflags]} \
    #{header_path}
    }
  end
end
