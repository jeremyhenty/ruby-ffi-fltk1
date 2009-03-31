
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

describe Widget do

  before do
    @box = Box.new(0, 0, 0, 0)
  end

  # getters/setters
  [
   [ :callback,
     lambda { puts 5 },
     lambda { puts 3 } ],
   [ :userdata,
     4, :bar ],
   [ :widget_type,
     Pack::Type::VERTICAL, Pack::Type::HORIZONTAL ],
   [ :box,
     Box::Type::NO_BOX, Box::Type::FLAT_BOX ],
   [ :x, 3, 6 ],
   [ :y, 7, 4 ],
   [ :w, 2, 9 ],
   [ :x, 1, 2 ],
   [ :label, "foo", "bar" ],
  ].each do |meth, *values|
    values.each do |value|
      [ meth, :"#{meth}=" ].each do |meth1|
        it "##{meth} should get the value set by ##{meth1}" do
          @box.send(meth1, value)
          @box.send(meth).should == value
        end
      end
    end
  end

end

describe Widget do
  it "#parent should return the parent widget" do
    Group.new do |group|
      box = Box.new
      box.parent.should == group
    end
  end
end
