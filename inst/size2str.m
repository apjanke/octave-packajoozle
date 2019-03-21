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
## @deftypefn {Function File} {@code{out} =} size2str (sz)
## Format an array size for display.
##
## sz is an array of dimension sizes, in the format returned by @code{size}.
##
## Returns a char row vector.
##
## @end deftypefn

function out = size2str (sz)
  strs = cell (size (sz));
  for i = 1:numel (sz)
    strs{i} = sprintf ('%d', sz(i));
  endfor
  out = strjoin (strs, '-by-');
endfunction
