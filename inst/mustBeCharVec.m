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
## @deftypefn {Function File} {} mustBeScalar (x)
##
## Requires that input is a char row vector (Octave's normal string representation).
##
## Raises an error if the input @code{x} is not a char row vector.
##
## @end deftypefn

function mustBeCharVec (x)
  if ! (ischar (x) && isrow (x))
    name = inputname (1);
    if isempty (name)
      name = "input";
    endif
    error ("%s must be a char row vector; got a %s %s", ...
      name, size2str (size (x)), class (x));
  endif
endfunction
