
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

function out = objvcat (varargin)
  # Hack to concatenate object vectorss because Octave doesn't support it as of 5.1
  #
  # The "v" in "objvcat" is for "vector" concatenation, not "vertical".
  out = [];
  for i_arg = 1:numel (varargin)
    B = varargin{i_arg};
    if isempty (out)
      out = B;
    else
      for i_B = 1:numel (B)
        out(end+1) = B(i_B);
      endfor
    endif
  endfor
endfunction
