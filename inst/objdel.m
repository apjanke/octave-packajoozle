
## Copyright (C) 2019 Andrew Janke
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; If not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {@var{obj} =} objdel (@var{obj}, @var{ix})
##
## Deletes selected elements from an object array.
##
## This function just papers over the fact that Octave does not support
## the @code{obj(ix) = []} element deletion syntax for objects.
##
## @var{ix} may be a logical or numeric index.
##
## @end deftypefn

function out = objdel (x, ix)
  % Delete selected indexes from object vector
  %
  % This is a hack that exists only because Octave does not support the
  % `x(ix) = []` element deletion syntax for objects.
  
  if islogical (ix)
    ix = find (ix);
  endif
  out = [];
  for i = 1:numel (x)
    if ! ismember (i, ix)
      if isempty (out)
        out = x(i);
      else
        out(end+1) = x(i);
      endif
    endif
  endfor
endfunction
