
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
    }.freeze

    def self.ffi_wrapper(options_=nil)
      options = DEFAULTS.dup
      options.merge!(options_) if options_
      if options[:attach_new]
        # convert ClassName to Class_Name, then downcase
        key = name.gsub(%r{\A.*::}, ""
                        ).gsub(%r{([^[:upper:]])([[:upper:]])}
                               ) { "#{$1}_#{$2}" }.downcase
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
        "wrong number of arguments (%d for 1)" % [ count ]
      end
    end
  end

  class Widget < FFI_Wrapper

    ffi_wrapper

    class Error < FFI::FLTK::Error ; end

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
      @ffi_ffi_callback = method(:ffi_ffi_callback)
      @ffi_callback = nil
      @ffi_userdata = nil
    end

    def ffi_pointer_new(*args)
      ffi_pointer_new_args_size_check(args.size)
      args.push(nil) if args.size % 2 == 0
      @ffi_label = String(args.pop).dup.freeze
      method, args = ffi_pointer_new_method_args(args)
      FFI::FLTK.send(*( [ method ] + args + [ @ffi_label ] ))
    end

    def ffi_pointer_new_method_args(args)
      args.unshift(nil, nil) while args.size < 4
      _method = self.class.ffi_pointer_new_method
      [ _method, ffi_pointer_new_args(args) ]
    end

    def ffi_pointer_new_args(args)
      current = Group.current
      parent = current ? current.parent : nil
      _x_default = current ? current.x_default : 0
      _y_default = current ? current.y_default : 0
      x, y, w, h = *args
      x ||= _x_default
      y ||= _y_default
      w ||= (current ? (_x_default + current.w - x) : 0)
      h ||= (current ? (_y_default + current.h - y) : 0)
      [ x, y, w, h ]
    end

    def ffi_pointer_new_args_size_check(size)
      raise ArgumentError,
      "wrong number of arguments (%d for 5)" % [ size ] if
        size > 5
    end

    def x_default ; parent ? x : 0 ; end
    def y_default ; parent ? y : 0 ; end

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

    ffi_attach_function :ffi_widget_parent, [ :pointer ], :pointer

    def parent
      from_ffi(ffi_send(:ffi_widget_parent))
    end

    ffi_callback :ffi_widget_callback, [ ], :void
    ffi_attach_function :ffi_callback_set,
    [ :pointer, :ffi_widget_callback ], :void

    class DeletedError < Error ; end

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

    def callback(*args, &callback)
      count = args.size
      if block_given?
        @ffi_callback = callback
        case count
        when 0, 1
          @ffi_userdata = *args
        else
          raise ArgumentError,
          "wrong number of arguments (%d for 1)" % [ count ]
        end
      else
        case count
        when 0
          return @ffi_callback
        when 1, 2
          @ffi_callback, @ffi_userdata = *args
        else
          raise ArgumentError,
          "wrong number of arguments (%d for 2)" % [ count ]
        end
      end
      if @ffi_callback
        ffi_send(:ffi_callback_set, @ffi_ffi_callback)
      else
        ffi_send(:ffi_callback_set, nil)
      end
      return nil
    end

    def userdata(*args)
      count = args.size
      case count
      when 0
        return @ffi_userdata
      when 1
        @ffi_userdata, = *args
        return nil
      else
        raise ArgumentError,
        "wrong number of arguments (%d for 1)" % [ count ]
      end
    end

    alias :userdata= :userdata

    def ffi_ffi_callback
      if @ffi_callback
        @ffi_callback.call(self, @ffi_userdata)
      end
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

    ffi_attach_function :ffi_widget_label_set,
    [ :pointer, :string ], :void

    def label(*args)
      count = args.size
      case count
      when 0
        @ffi_label.dup
      when 1
        _label = String(args.first).freeze
        ffi_send(:ffi_widget_label_set, _label)
        @ffi_label = _label
      else
        "wrong number of arguments (%d for 1)" % [ count ]
      end
    end

    alias :label= :label
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
        "wrong number of arguments (%d for 1)" % [ count ]
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
        "wrong number of arguments (%d for 1)" % [ count ]
      end
    end

    alias :resizable= :resizable
  end

  class Pack < Group
    def x_default ; 0 ; end
    def y_default ; 0 ; end

    ffi_wrapper
  end

  require "ffi/fltk1/auto/pack"

  class Scroll < Group
    ffi_wrapper
  end

  require "ffi/fltk1/auto/scroll"

  class Window < Group

    ffi_wrapper :attach_new => false

    ffi_attach_function :ffi_window_new_xywhl,
    [ :int, :int, :int, :int, :string ], :pointer
    ffi_attach_function :ffi_window_new_whl,
    [ :int, :int, :string ], :pointer

    def ffi_pointer_new_method_args(args)
      if args.size < 4
        # only the width and height, just call the other constructor
        [ :ffi_window_new_whl, args ]
      else
        # process the args as normal and call the usual constructor 
        [ :ffi_window_new_xywhl, ffi_pointer_new_args(args) ]
      end
    end

    def ffi_pointer_new_args_size_check(size)
      raise ArgumentError,
      "wrong number of arguments (%d for 5)" % [ size ] if
        size > 5
      raise ArgumentError,
      "wrong number of arguments (%d for 2)" % [ size ] if
        size < 2
    end

    ffi_attach_function :ffi_window_show, [ :pointer ], :void
    ffi_attach_function :ffi_window_hide, [ :pointer ], :void

    def show ; ffi_send(:ffi_window_show) ; end
    def hide ; ffi_send(:ffi_window_hide) ; end

    ffi_attach_function :ffi_window_size_range,
    [ :pointer, :int, :int, :int, :int, :int, :int, :int ], :void

    def size_range(minw, minh, maxw=0, maxh=0, dw=0, dh=0, aspect=0)
      ffi_send(:ffi_window_size_range,
               minw, minh, maxw, maxh, dw, dh, aspect)
    end
  end

  class Menu < Widget

    def initialize(*args)
      super
      @ffi_menu_items = [ ]
    end

    def add(*args)
      item = MenuItem.new(self, *args)
      @ffi_menu_items << item
      return item
    end

    ffi_callback :ffi_menu_item_callback, [ ], :void

    # add(), with an "int" shortcut
    ffi_attach_function :ffi_menu_add_i,
    [ :pointer, :string, :int, :ffi_menu_item_callback, :int ],
    :int

    # add(), with a "const char *" shortcut
    ffi_attach_function :ffi_menu_add_s,
    [ :pointer, :string, :string, :ffi_menu_item_callback, :int ],
    :int
  end

  class MenuItem

    def initialize(widget, label, shortcut = nil,
                   callback = nil, userdata = nil, flags = nil)
      @ffi_ffi_callback = method(:ffi_ffi_callback)
      @ffi_widget = widget
      @ffi_callback = callback
      @ffi_userdata = userdata

      ffi_method = nil

      # coerce shortcut to something meaningful and set ffi_method
      begin
        shortcut = Integer(shortcut)
        ffi_method = :ffi_menu_add_i
      rescue ArgumentError
        begin
          shortcut = String(shortcut)
          ffi_method = :ffi_menu_add_s
        rescue ArgumentError
        end
      end

      # if ffi_method is still nil then we failed to coerce shortcut
      unless ffi_method
        raise ArgumentError,
        "shortcut must be an Integer or a String"
      end

      # tell the widget to add this item
      @ffi_widget.ffi_send(ffi_method,
                           String(label), shortcut,
                           @ffi_ffi_callback, Integer(flags))
    end

    def ffi_ffi_callback
      if @ffi_callback
        @ffi_callback.call(@ffi_widget, @ffi_userdata)
      end
    end
  end

  require "ffi/fltk1/auto/menuitem"

  class MenuBar < Menu
    ffi_wrapper
  end

  class Box < Widget
    ffi_wrapper
  end

  attach_function :ffi_fl_box_initialize, [ ], :void
  ffi_fl_box_initialize

  require "ffi/fltk1/auto/box"

  class Button < Widget
    ffi_wrapper
  end

  class CheckButton < Button
    ffi_wrapper
  end

  class LightButton < Button
    ffi_wrapper
  end

  class RepeatButton < Button
    ffi_wrapper
  end

  class ReturnButton < Button
    ffi_wrapper
  end

  class RoundButton < Button
    ffi_wrapper
  end

  class ToggleButton < Button
    ffi_wrapper
  end

  class Input < Widget

    ffi_attach_function :ffi_input_value,
    [ :pointer ], :string
    ffi_attach_function :ffi_input_value_set,
    [ :pointer, :string ], :void

    def value(*args)
      count = args.size
      case count
      when 0
        ffi_send(:ffi_input_value)
      when 1
        ffi_send(:ffi_input_value_set, String(args.first))
      else
        raise ArgumentError,
        "wrong number of arguments (%d for 1)" % [ count ]
      end
    end

    alias :value= :value

    ffi_wrapper
  end

  require "ffi/fltk1/auto/input"

  class SecretInput < Input
    ffi_wrapper
  end

  class IntInput < Input
    ffi_wrapper
  end

  class FloatInput < Input
    ffi_wrapper
  end

  class MultilineInput < Input
    ffi_wrapper
  end

  class FileInput < Input
    ffi_wrapper
  end

  class Output < Input
    ffi_wrapper
  end

  class MultilineOutput < Output
    ffi_wrapper
  end

  class Valuator < Widget

    [ :value, :minimum, :maximum ].each do |meth0|
      class_eval <<METHOD
    ffi_attach_function :ffi_valuator_#{meth0},
    [ :pointer ], :double
    ffi_attach_function :ffi_valuator_#{meth0}_set,
    [ :pointer, :double ], :void

    def #{meth0}(*args)
      count = args.size
      case count
      when 0
        ffi_send(:ffi_valuator_#{meth0})
      when 1
        ffi_send(:ffi_valuator_#{meth0}_set, Float(args.first))
      else
        raise ArgumentError,
        "wrong number of arguments (%d for 1)" % [ count ]
      end
    end
METHOD

      alias_method :"#{meth0}=", meth0
    end

    [ :range, :bounds ].each do |meth0|
      class_eval <<METHOD
    ffi_attach_function :ffi_valuator_#{meth0},
    [ :pointer, :double, :double ], :void

    def #{meth0}(minimum, maximum)
      ffi_send(:ffi_valuator_#{meth0}, minimum, maximum)
    end
METHOD
    end

    ffi_attach_function :ffi_valuator_step,
    [ :pointer ], :double
    ffi_attach_function :ffi_valuator_step_set_double,
    [ :pointer, :double ], :void
    ffi_attach_function :ffi_valuator_step_set_int_int,
    [ :pointer, :int, :int ], :void

    def step(*args)
      count = args.size
      case count
      when 0
        ffi_send(:ffi_valuator_step)
      when 1
        ffi_send(:ffi_valuator_step_set_double,
                 Float(args.first))
      when 2
        ffi_send(:ffi_valuator_step_set_int_int,
                 Integer(args[0]), Integer(args[1]))
      else
        raise ArgumentError,
        "wrong number of arguments (%d for 2)" % [ count ]
      end
    end

    alias_method :step=, :step

    ffi_attach_function :ffi_valuator_precision,
    [ :pointer, :int ], :void

    def precision(_precision)
      ffi_send(:ffi_valuator_precision, _precision)
    end

    alias_method :precision=, :precision

  end

  require "ffi/fltk1/auto/valuator"

  class Adjuster < Valuator
    ffi_wrapper
  end

  class Counter < Valuator
    ffi_wrapper
  end

  require "ffi/fltk1/auto/counter"

  class Dial < Valuator
    ffi_wrapper
  end

  require "ffi/fltk1/auto/dial"

  class Roller < Valuator
    ffi_wrapper
  end

  class Slider < Valuator
    ffi_wrapper
  end

  require "ffi/fltk1/auto/slider"

  class Scrollbar < Slider
    ffi_wrapper
  end

  class ValueSlider < Slider
    ffi_wrapper
  end

  class ValueInput < Valuator
    ffi_wrapper
  end

  class ValueOutput < Valuator
    ffi_wrapper
  end

end
