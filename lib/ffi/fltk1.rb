
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


require "ffi"

module FFI::FLTK

  extend FFI::Library
  ffi_lib(__FILE__.sub(%r{\.rb$},".so"))

  attach_function :fltk_run, [ ], :int
  attach_function :fltk_alert, [ :string ], :void

  class Window

    def self.attach_function(*args)
      FFI::FLTK.attach_function(*args)
    end

    attach_function :window_new_xywhl, [ :int, :int, :int, :int, :string ], :pointer
    attach_function :window_new_whl, [ :int, :int, :string ], :pointer
    attach_function :window_delete, [ :pointer ], :void
    attach_function :window_show , [ :pointer ], :void

    def initialize(*args)
      count = args.size
      @pointer =
        case count
        when 2: args << nil; window_new_whl(*args)
        when 3: window_new_whl(*args)
        when 4: args << nil; window_new_xywhl(*args)
        when 5: window_new_xywhl(*args)
        else
          raise ArgumentError, "wrong number of arguments (%d for %d))" %
            [ count, count < 2 ? 2 : 5 ]
        end
      @auto_pointer = FFI::AutoPointer.new(@pointer, method(:window_delete))
      yield self if block_given?
    end

    def show
      window_show(@pointer)
    end
  end

  class Button

    def self.attach_function(*args)
      FFI::FLTK.attach_function(*args)
    end

    attach_function :button_new_xywhl, [ :int, :int, :int, :int, :string ], :pointer
    attach_function :button_delete, [ :pointer ], :void
    FFI::FLTK.callback :widget_callback_t, [ ], :void
    attach_function :widget_callback, [ :pointer, :widget_callback_t ], :void

    def initialize(*args)
      count = args.size
      @pointer =
        case count
        when 4: args << nil; button_new_xywhl(*args)
        when 5: button_new_xywhl(*args)
        else
          raise ArgumentError, "wrong number of arguments (%d for %d))" %
            [ count, count < 4 ? 4 : 5 ]
        end
      @auto_pointer = FFI::AutoPointer.new(@pointer, method(:button_delete))
      yield self if block_given?
    end

    def callback(*cbs, &cb1)
      return @ffi_callback if cbs.empty? && !cb1
      count = cbs.size
      raise ArgumentError, "wrong number of arguments (%d for 1))" %
        [ count ] if count > 1
      cb0 = cbs.first
      raise "cannot supply both a Proc and a block" if cb0 && cb1
      cb = cb0 || cb1
      @ffi_callback = cb
      widget_callback(@pointer, @ffi_callback)
      return @ffi_callback
    end

    alias :callback= :callback
  end

  def self.run
    fltk_run()
  end

  def self.alert(message)
    fltk_alert(message)
  end

end
