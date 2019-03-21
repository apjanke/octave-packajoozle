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

    function out = packajoozle_data_dir
      out = fullfile (getenv("HOME"), "octave", "packajoozle");
    endfunction

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

    function out = basename (file)
      ix = find (file == filesep, 1, "last");
      if isempty (ix)
        out = file;
      else
        out = file(ix+1:end);
      endif
    endfunction

    function out = posixtime2datenum (posix_time)
      persistent unix_epoch_datenum = datenum('1/1/1970');
      out = (posix_time / (60 * 60 * 24)) + unix_epoch_datenum;
    endfunction

    function out = urlwrite (url, localfile)
      [f, ok, msg] = urlwrite (url, localfile);
      if ! ok
        error ("urlwrite: Failed downloading URL:\n  URL: %s\n  Error: %s", ...
          url, msg);
      endif
      fprintf ("urlwrite: Downloaded %s to %s\n", url, localfile);
    endfunction
  endmethods

endclassdef