
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

  attach_function :run, :ffi_fltk_run, [ ], :int
  attach_function :alert, :ffi_fltk_alert, [ :string ], :void

  class Widget

    class DeletedError < FFI::FLTK::Error ; end

    WIDGETS = Set.new

    def self.ffi_attach_function(*args)
      FFI::FLTK.attach_function(*args)
    end

    def self.ffi_callback(*args)
      FFI::FLTK.callback(*args)
    end

    ffi_attach_function :ffi_widget_new_xywhl,
    [ :int, :int, :int, :int, :string ], :pointer

    def initialize(*args)
      @ffi_pointer = ffi_pointer(*args)
      WIDGETS << self
      @ffi_widget_deleted = false
      @ffi_widget_deleted_callback = method(:ffi_widget_deleted)
      ffi_set_delete_callback(@ffi_pointer, @ffi_widget_deleted_callback)
    end

    def ffi_pointer(*args)
      count = args.size
      case count
      when 4: args << nil; ffi_widget_new_xywhl(*args)
      when 5: ffi_widget_new_xywhl(*args)
      else
        raise ArgumentError, "wrong number of arguments (%d for %d))" %
          [ count, count < 4 ? 4 : 5 ]
      end
    end

    ffi_callback :ffi_widget_callback, [ ], :void
    ffi_attach_function :ffi_widget_set_callback,
    [ :pointer, :ffi_widget_callback ], :void
    ffi_attach_function :ffi_widget_unset_callback,
    [ :pointer ], :void

    ffi_callback :ffi_delete_callback, [ ], :void
    ffi_attach_function :ffi_set_delete_callback,
    [ :pointer, :ffi_delete_callback ], :void

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
      if @ffi_callback
        ffi_widget_set_callback(@ffi_pointer, @ffi_callback)
      else
        ffi_widget_unset_callback(@ffi_pointer)
      end
      return @ffi_callback
    end

    alias :callback= :callback
  end

  class Window < Widget

    ffi_attach_function :ffi_window_new_xywhl,
    [ :int, :int, :int, :int, :string ], :pointer
    ffi_attach_function :ffi_window_new_whl,
    [ :int, :int, :string ], :pointer

    ffi_attach_function :ffi_window_show, [ :pointer ], :void
    ffi_attach_function :ffi_window_hide, [ :pointer ], :void

    def initialize(*args)
      super
      yield self if block_given?
    end

    def ffi_pointer(*args)
      count = args.size
      case count
      when 2: args << nil; ffi_window_new_whl(*args)
      when 3: ffi_window_new_whl(*args)
      when 4: args << nil; ffi_window_new_xywhl(*args)
      when 5: ffi_window_new_xywhl(*args)
      else
        raise ArgumentError, "wrong number of arguments (%d for %d))" %
          [ count, count < 2 ? 2 : 5 ]
      end
    end

    def show
      ffi_widget_not_deleted
      ffi_window_show(@ffi_pointer)
    end

    def hide
      ffi_widget_not_deleted
      ffi_window_hide(@ffi_pointer)
    end
  end

  class Box < Widget

    ffi_attach_function :ffi_box_new_xywhl,
    [ :int, :int, :int, :int, :string ], :pointer

    def ffi_pointer(*args)
      count = args.size
      case count
      when 4: args << nil; ffi_box_new_xywhl(*args)
      when 5: ffi_box_new_xywhl(*args)
      else
        raise ArgumentError, "wrong number of arguments (%d for %d))" %
          [ count, count < 4 ? 4 : 5 ]
      end
    end
  end

  require "ffi/fltk/auto/box"

  class Button < Widget

    ffi_attach_function :ffi_button_new_xywhl,
    [ :int, :int, :int, :int, :string ], :pointer

    def ffi_pointer(*args)
      count = args.size
      case count
      when 4: args << nil; ffi_button_new_xywhl(*args)
      when 5: ffi_button_new_xywhl(*args)
      else
        raise ArgumentError, "wrong number of arguments (%d for %d))" %
          [ count, count < 4 ? 4 : 5 ]
      end
    end
  end

end
