## Copyright (C) 2019 Andrew Janke
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; If not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {empty_obj = } emptyobj (obj)
##
## Create an empty object from a nonempty one.
##
## This is a hack to create an empty object, since @code{repmat(obj, [0 0])}
## doesn't work as of Octave 5.1. All it does is @code{obj([])}, but having
## a function that does this lets you use it inline in one-liner expressions.
## 
## @end deftypefn

## Author:  Andrew Janke

function empty_obj = emptyobj (obj)
  empty_obj = obj([]);
endfunction