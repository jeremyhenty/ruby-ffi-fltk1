
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
require "set"

module FFI::FLTK

  class Error < StandardError ; end

  extend FFI::Library
  ffi_lib(__FILE__.sub(%r{\.rb$},".so"))

  attach_function :fltk_run, [ ], :int
  attach_function :fltk_alert, [ :string ], :void

  class Widget

    class DeletedError < FFI::FLTK::Error ; end

    WIDGETS = Set.new

    def self.attach_function(*args)
      FFI::FLTK.attach_function(*args)
    end

    FFI::FLTK.callback :widget_callback_t, [ ], :void
    attach_function :widget_callback, [ :pointer, :widget_callback_t ], :void

    FFI::FLTK.callback :ffi_delete_callback_t, [ ], :void
    attach_function :ffi_set_delete_callback,
    [ :pointer, :ffi_delete_callback_t ], :void

    def ffi_initialize
      WIDGETS << self
      @ffi_widget_deleted = false
      @ffi_widget_deleted_callback = method(:ffi_widget_deleted)
      ffi_set_delete_callback(@ffi_pointer, @ffi_widget_deleted_callback)
    end

    def ffi_widget_deleted
      @ffi_pointer = nil
      WIDGETS.delete(self)
      @ffi_widget_deleted = true
      @ffi_widget_deleted_callback = nil
    end

    def ffi_widget_not_deleted
      raise DeletedError, "the FLTK widget is deleted", caller if
        @ffi_widget_deleted
    end

    def ffi_widget_deleted?
      @ffi_widget_deleted
    end

    def callback(*cbs, &cb1)
      ffi_widget_not_deleted
      return @ffi_callback if cbs.empty? && !cb1
      count = cbs.size
      raise ArgumentError, "wrong number of arguments (%d for 1))" %
        [ count ] if count > 1
      cb0 = cbs.first
      raise ArgumentError, "cannot supply both a Proc and a block" if
        cb0 && cb1
      cb = cb0 || cb1
      @ffi_callback = cb
      widget_callback(@ffi_pointer, @ffi_callback)
      return @ffi_callback
    end

    alias :callback= :callback
  end

  class Window < Widget

    attach_function :window_new_xywhl,
    [ :int, :int, :int, :int, :string ], :pointer
    attach_function :window_new_whl,
    [ :int, :int, :string ], :pointer

    attach_function :window_show, [ :pointer ], :void

    def initialize(*args)
      count = args.size
      @ffi_pointer =
        case count
        when 2: args << nil; window_new_whl(*args)
        when 3: window_new_whl(*args)
        when 4: args << nil; window_new_xywhl(*args)
        when 5: window_new_xywhl(*args)
        else
          raise ArgumentError, "wrong number of arguments (%d for %d))" %
            [ count, count < 2 ? 2 : 5 ]
        end
      ffi_initialize
      yield self if block_given?
    end

    def show
      ffi_widget_not_deleted
      window_show(@ffi_pointer)
    end
  end

  class Button < Widget

    attach_function :button_new_xywhl,
    [ :int, :int, :int, :int, :string ], :pointer

    def initialize(*args)
      count = args.size
      @ffi_pointer =
        case count
        when 4: args << nil; button_new_xywhl(*args)
        when 5: button_new_xywhl(*args)
        else
          raise ArgumentError, "wrong number of arguments (%d for %d))" %
            [ count, count < 4 ? 4 : 5 ]
        end
      ffi_initialize
    end
  end

  def self.run
    fltk_run()
  end

  def self.alert(message)
    fltk_alert(message)
  end

end
