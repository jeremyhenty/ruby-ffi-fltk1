
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


# Call 'fltk-config' to get the FLTK development environment
# configuration.

module Build

  module_function

  # Build hooks.  Add code to extra.rb to modify these.
  EXTRA_CPP_DEFINES = [ ]

  def fltk_config
    @@fltk_config ||= fltk_config_
  end

  def fltk_config_

    config = Hash.new

    # save the output of fltk-config
    [ :version, :cxx, :cxxflags, :ldflags ].each do |key|
      config[key] = %x{ fltk-config --#{key} }.chomp
      raise Build::Error,
      "configuration check for --#{key} failed" unless $?.success?
    end

    # we also want the includedir, but fltk-config has no --includedir
    # :-(

    # workaround: search the cxxflags for the include directory that
    # contains Fl.H

    # search the cxxflags for include directories
    flags = config[:cxxflags].split(%r{[[:space:]]+})
    flag_pattern = %r{\A-I(.*)\z}
    include_dirs = flags.collect do |flag|
      flag_match = flag_pattern.match(flag)
      next unless flag_match
      flag_match.captures.first 
    end.compact

    # special case: fltk-config always omits /usr/include, so add it
    include_dirs.unshift("/usr/include")

    # search the include directories for the one that contains Fl.H
    include_dirs.each do |dir|
      header_dir = File.join(dir, "FL")
      if File.exist?(File.join(header_dir, "Fl.H"))
        config[:header_dir] = header_dir
        break
      end
    end
    raise Build::Error,
    "configuration check for the header directory failed" unless
      config[:header_dir]
    puts "header directory: #{config[:header_dir]}" 

    return config
  end

  def dl_compile(dl_path, *source_paths)
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
