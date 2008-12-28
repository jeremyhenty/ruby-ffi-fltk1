
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
  ffi_lib(*Dir.glob("#{File.dirname(__FILE__)}/**/*.so"))

  attach_function :run, :ffi_fltk_run, [ ], :int
  attach_function :alert, :ffi_fltk_alert, [ :string ], :void

  class Widget

    class DeletedError < FFI::FLTK::Error ; end

    WIDGETS = Set.new

    attr_reader :ffi_pointer

    def self.ffi_attach_function(*args)
      FFI::FLTK.attach_function(*args)
    end

    def self.ffi_callback(*args)
      FFI::FLTK.callback(*args)
    end

    def self.ffi_pointer_new_method(*args)
      count = args.size
      case count
      when 0
        @ffi_pointer_new_method
      when 1
        @ffi_pointer_new_method = args.first
        ffi_attach_function @ffi_pointer_new_method,
        [ :int, :int, :int, :int, :string ], :pointer
        nil
      else
        raise ArgumentError,
        "wrong number of arguments (%d for 1))" % [ count ]
      end
    end

    ffi_pointer_new_method :ffi_widget_new_xywhl

    def initialize(*args)
      @ffi_pointer = ffi_pointer_new(*args)
      WIDGETS << self
      @ffi_widget_deleted = false
      @ffi_widget_deleted_callback = method(:ffi_widget_deleted)
      ffi_set_delete_callback(@ffi_pointer, @ffi_widget_deleted_callback)
    end

    def ffi_pointer_new(*args)
      count = args.size
      case count
      when 4: args << nil; ffi_pointer_new_(*args)
      when 5: ffi_pointer_new_(*args)
      else
        raise ArgumentError, "wrong number of arguments (%d for %d))" %
          [ count, count < 4 ? 4 : 5 ]
      end
    end

    def ffi_pointer_new_(*args)
      send(self.class.ffi_pointer_new_method, *args)
    end

    def ffi_send(meth, *args)
      ffi_widget_not_deleted
      send(meth, @ffi_pointer, *args)
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
        ffi_send(:ffi_widget_set_callback, @ffi_callback)
      else
        ffi_send(:ffi_widget_unset_callback)
      end
      return @ffi_callback
    end

    alias :callback= :callback

    ffi_attach_function :ffi_widget_box, [ :pointer ], :int
    ffi_attach_function :ffi_widget_box_set, [ :pointer, :int ], :void

    def box(b=nil)
      if b
        ffi_send(:ffi_widget_box_set, b)
      else
        ffi_send(:ffi_widget_box)
      end
    end

    alias :box= box
  end

  class Group < Widget

    ffi_pointer_new_method :ffi_group_new_xywhl

    def initialize(*args)
      super
      if block_given?
        # the FLTK constructor has already called Group::begin
        begin yield self
        ensure group_end
        end
      end
    end

    ffi_attach_function :ffi_group_begin, [ :pointer ], :void
    ffi_attach_function :ffi_group_end, [ :pointer ], :void

    def group_begin
      if block_given?
        group_begin_
        begin yield
        ensure group_end
        end
      else group_begin_
      end
    end

    def group_begin_
      ffi_send(:ffi_group_begin)
    end

    def group_end
      ffi_send(:ffi_group_end)
    end
  end

  class Window < Group

    ffi_attach_function :ffi_window_new_xywhl,
    [ :int, :int, :int, :int, :string ], :pointer
    ffi_attach_function :ffi_window_new_whl,
    [ :int, :int, :string ], :pointer

    ffi_attach_function :ffi_window_show, [ :pointer ], :void
    ffi_attach_function :ffi_window_hide, [ :pointer ], :void

    def ffi_pointer_new(*args)
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

    def show ; ffi_send(:ffi_window_show) ; end
    def hide ; ffi_send(:ffi_window_hide) ; end
  end

  attach_function :ffi_fl_box_initialize, [ ], :void
  ffi_fl_box_initialize

  class Box < Widget
    ffi_pointer_new_method :ffi_box_new_xywhl
  end

  require "ffi/fltk1/auto/box"

  class Button < Widget
    ffi_pointer_new_method :ffi_button_new_xywhl
  end

end
