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
## @deftypefn {Function File} {out = } makeItBeA (x, type)
##
## Converts input to given type if it is not one already.
##
## Ensures that the input x is of the given type. If it is not already that
## type (as indicated by isa (x, type)), it is converted by calling
## the one-argument constructor for type.
##
## @end deftypefn

## Author:  

function x = makeItBeA (x, type)
  narginchk (2, 2);
  if ! isa (x, type)
    x = feval (type, x);
  endif
endfunction