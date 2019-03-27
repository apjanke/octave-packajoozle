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
## @deftypefn {Function File} {@var{strs} =} dispstrs (@var{x})
##
## Create display strings for arbitrary array.
##
## @code{dispstrs} converts arbitrary inputs to displayable strings
## suitable for user presentation. Each element of the input array
## is converted to one string in the output, which is returned as a
## cellstr the same size as the input.
##
## Many programming languages provide general, polymorphic string 
## conversion operations, so you can call them on any input and expect
## to get something useful. For example, @code{toString} in Java
## or @code{str} in Python. Octave lacks that. dispstrs
## intends to fill that gap. It provides useful conversion implementations
## for many of Octave's built-in types, and the intention is that
## user-defined classes can provide their own @code{dispstrs}
## methods to override it.
##
## Returns a cellstr the same size as x. Note that this is strictly
## true: if you pass in a string as a char row vector, you will get
## back each individual character as a separate string.
##
## @end deftypefn

function out = dispstrs (x)
  % Display strings for arbitrary array
  if isnumeric (x) || islogical (x)
    out = reshape (strtrim (cellstr (num2str (x(:)))), size (x));
  elseif iscellstr (x) || isa (x, 'string')
    out = cellstr (x);
  elseif isa (x, 'datetime')
    out = datestrs (x);    
  elseif ischar (x)
    out = num2cell (x);
  else
    out = repmat ({sprintf('1-by-1 %s', class(x))}, size (x));
  endif
endfunction
