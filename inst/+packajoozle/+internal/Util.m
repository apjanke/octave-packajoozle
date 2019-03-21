## Copyright (C)  
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
## @deftypefn {Class Constructor} {obj =} Util ()
## Utility functions.
##
## Miscellaneous utility functions for Packajoozle.
##
## @end deftypefn

## Author:  

classdef Util

  methods (Static)

    function flush_diary
      if diary
        diary off
        diary on
      endif
    endfunction

    function filewrite (out_file, txt)
      [fid, msg] = fopen (out_file, 'w');
      if fid < 0
        error ('Failed opening file for writing:\n  File: %s\n  Error: %s', ...
          out_file, msg);
      endif
      fwrite (fid, txt);
      fclose (fid);
    endfunction

  endmethods

endclassdef