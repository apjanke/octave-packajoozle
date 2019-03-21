## Copyright (C) Andrew Janke
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
## @deftypefn {Function File} {} mustBeA (x, type)
## Requires that input is of a given type.
##
## Raises an error if the input @code{x} is not of the specified @code{type}
## or a subclass.
##
## @end deftypefn

function mustBeA (x, type)
  if ! isa (x, type)
    name = inputname (1);
    if isempty (name)
      name = "input";
    endif
    error ("%s must be of type %s; got a %s", name, type, class (x));
  endif
endfunction
