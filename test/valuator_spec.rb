
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


require "./lib/ffi/fltk1"

include FFI
include FFI::FLTK

describe Valuator do

  # Valuator is an abstract widget class, so we use an Adjuster.

  before do
    @valuator = Adjuster.new(0, 0, 0, 0)
  end

  # getters/setters
  [
   [ :value,   -1.0, -0.1, 0.0, +0.1, +1.0 ],
   [ :maximum, +0.1, +1.0, +2.0 ],
   [ :minimum, +0.1, +1.0, +2.0 ],
  ].each do |meth, *values|
    values.each do |value|
      [ meth, :"#{meth}=" ].each do |meth1|
        it "##{meth} should get the value set by ##{meth1}" do
          @valuator.send(meth1, value)
          @valuator.send(meth).should == value
        end
      end
    end
  end

  # #range and #bounds
  [ :range, :bounds ].each do |meth|
    [
     [ -1.0, +1.0 ],
     [ -0.1, +1.0 ],
     [ -1.0, +0.1 ],
    ].each do |min, max|

      it "##{meth} should set #minimum" do
        @valuator.send(meth, min, max)
        @valuator.minimum.should == min
      end

      it "##{meth} should set #maximum" do
        @valuator.send(meth, min, max)
        @valuator.maximum.should == max
      end
    end
  end

  # #step, (float) form
  [ 0.01, 0.1, 1.0 ].each do |value|
    it "#step= Float should set #step" do
      @valuator.step = value
      @valuator.step.should == value
    end
  end

  # #step(Int, Int)
  [
   [ 2, 1 ],
   [ 3, 2 ],
   [ 1, 5 ],
   [ 2, 7 ],
  ].each do |numerator, denominator|
    it "#step(Int, Int) should set #step" do
      @valuator.step(numerator, denominator)
      @valuator.step.should == Float(numerator) / Float(denominator)
    end
  end

  # #precision=
  (1..4).each do |precision|
    [ :precision, :precision= ].each do |meth|
      it "##{meth} should set #step" do
        @valuator.send(meth, precision)
        @valuator.step.should == 10 ** -precision
      end
    end
  end

end
