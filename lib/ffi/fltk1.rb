
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


require "ffi"

module FFI::FLTK

  class Error < StandardError ; end

  extend FFI::Library
  ffi_lib(*Dir.glob("#{File.dirname(__FILE__)}/**/*.so"))

  attach_function :run, :ffi_fltk_run, [ ], :int
  attach_function :alert, :ffi_fltk_alert, [ :string ], :void

  class FFI_Wrapper

    DEFAULTS = {
      :attach_new => true,
    }

    def self.ffi_wrapper(options_=nil)
      options = DEFAULTS.dup
      options.merge!(options_) if options_
      if options[:attach_new]
        key = name.gsub(%r{\A.*::}, "").downcase
        ffi_pointer_new_method :"ffi_#{key}_new_xywhl"
      end
    end

    def self.ffi_attach_function(*args)
      FFI::FLTK.attach_function(*args)
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
  end

  class Widget < FFI_Wrapper

    ffi_wrapper

    class DeletedError < FFI::FLTK::Error ; end

    WIDGETS = Hash.new

    def self.from_ffi(pointer)
      WIDGETS[pointer.address]
    end

    def from_ffi(pointer)
      self.class.from_ffi(pointer) 
    end

    attr_reader :ffi_pointer

    def self.to_ffi(arg)
      case arg
      when Widget ; arg.ffi_pointer
      else arg
      end
    end

    def to_ffi(arg)
      self.class.to_ffi(arg) 
    end

    def self.ffi_callback(*args)
      FFI::FLTK.callback(*args)
    end

    def initialize(*args)
      @ffi_pointer = ffi_pointer_new(*args)
      @ffi_widget_deleted = false
      @ffi_widget_deleted_callback = method(:ffi_widget_deleted)
      ffi_send(:ffi_set_delete_callback, @ffi_widget_deleted_callback)
      @ffi_fl_address = ffi_send(:ffi_widget_fl_pointer).address
      WIDGETS[@ffi_fl_address] = self
    end

    def ffi_pointer_new(*args)
      count = args.size
      case count
      when 2
        args.unshift(0, 0)
        args << nil
      when 3
        args.unshift(0, 0)
        args[-1] = String(args.last)
      when 4
        args << nil
      when 5
        args[-1] = String(args.last)
      else
        raise ArgumentError, "wrong number of arguments (%d for %d))" %
          [ count, count < 2 ? 2 : 5 ]
      end
      ffi_pointer_new_(*args)
    end

    def ffi_pointer_new_(*args)
      FFI::FLTK.send(self.class.ffi_pointer_new_method, *args)
    end

    def self.ffi_send(meth, *args)
      args = args.collect { |arg| to_ffi(arg) }
      FFI::FLTK.send(meth, *args)
    end

    def ffi_send(meth, *args)
      ffi_widget_not_deleted
      args = args.collect { |arg| to_ffi(arg) }
      FFI::FLTK.send(meth, @ffi_pointer, *args)
    end

    ffi_attach_function :ffi_widget_fl_pointer, [ :pointer ], :pointer

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
      WIDGETS.delete(@ffi_fl_address)
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

    ffi_attach_function :ffi_widget_redraw, [ :pointer ], :void

    def redraw()
      ffi_send(:ffi_widget_redraw)
    end

    [ :type, :box, :x, :y, :w, :h ].each do |meth|

      ffi_attach_function :"ffi_widget_#{meth}",
      [ :pointer ], :int
      ffi_attach_function :"ffi_widget_#{meth}_set",
      [ :pointer, :int ], :void

      meth0 =
        case meth
        when :type ; "widget_#{meth}"
        else ; meth
        end

      class_eval <<DEF, __FILE__, __LINE__
      def #{meth0}(_#{meth}=nil)
        if _#{meth}
          ffi_send(:ffi_widget_#{meth}_set, _#{meth})
        else
          ffi_send(:ffi_widget_#{meth})
        end
      end
DEF

      alias_method :"#{meth0}=", meth0
    end
  end

  class Group < Widget

    ffi_wrapper

    ffi_attach_function :ffi_group_current, [ ], :pointer
    ffi_attach_function :ffi_group_current_set, [ :pointer ], :void

    def self.current(*args)
      count = args.size
      case count
      when 0
        from_ffi(ffi_send(:ffi_group_current))
      when 1
        ffi_send(:ffi_group_current_set, args.first)
        nil
      else 
        raise ArgumentError,
        "wrong number of arguments (%d for 1))" % [ count ]
      end
    end

    class << self
      alias :current= :current
    end

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

    ffi_attach_function :ffi_group_resizable,
    [ :pointer ], :pointer
    ffi_attach_function :ffi_group_resizable_set,
    [ :pointer, :pointer ], :void

    def resizable(*args)
      count = args.size
      case count
      when 0
        from_ffi(ffi_send(:ffi_group_resizable))
      when 1
        ffi_send(:ffi_group_resizable_set, args.first)
        nil
      else
        raise ArgumentError,
        "wrong number of arguments (%d for 1))" % [ count ]
      end
    end

    alias :resizable= :resizable
  end

  class Pack < Group
    ffi_wrapper
  end

  require "ffi/fltk1/auto/pack"

  class Window < Group

    ffi_wrapper :attach_new => false

    ffi_attach_function :ffi_window_new_xywhl,
    [ :int, :int, :int, :int, :string ], :pointer
    ffi_attach_function :ffi_window_new_whl,
    [ :int, :int, :string ], :pointer

    ffi_attach_function :ffi_window_show, [ :pointer ], :void
    ffi_attach_function :ffi_window_hide, [ :pointer ], :void

    def ffi_pointer_new(*args)
      count = args.size
      case count
      when 2
        args << nil
        ffi_window_new_whl(*args)
      when 3
        args[-1] = String(args.last)
        ffi_window_new_whl(*args)
      when 4
        args << nil
        ffi_window_new_xywhl(*args)
      when 5
        args[-1] = String(args.last) 
        ffi_window_new_xywhl(*args)
      else
        raise ArgumentError, "wrong number of arguments (%d for %d))" %
          [ count, count < 2 ? 2 : 5 ]
      end
    end

    def show ; ffi_send(:ffi_window_show) ; end
    def hide ; ffi_send(:ffi_window_hide) ; end

    ffi_attach_function :ffi_window_size_range,
    [ :pointer, :int, :int, :int, :int, :int, :int, :int ], :void

    def size_range(minw, minh, maxw=0, maxh=0, dw=0, dh=0, aspect=0)
      ffi_send(:ffi_window_size_range,
               minw, minh, maxw, maxh, dw, dh, aspect)
    end
  end

  attach_function :ffi_fl_box_initialize, [ ], :void
  ffi_fl_box_initialize

  class Box < Widget
    ffi_wrapper
  end

  require "ffi/fltk1/auto/box"

  class Button < Widget
    ffi_wrapper
  end

  class Check_Button < Button
    ffi_wrapper
  end

  class Light_Button < Button
    ffi_wrapper
  end

  class Repeat_Button < Button
    ffi_wrapper
  end

  class Return_Button < Button
    ffi_wrapper
  end

  class Round_Button < Button
    ffi_wrapper
  end

  class Toggle_Button < Button
    ffi_wrapper
  end

end
