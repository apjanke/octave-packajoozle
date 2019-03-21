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
## @deftypefn {Class Constructor} {obj =} InstallDir ()
## A local directory where pkg package installations reside.
##
## An InstallDir is a local filesystem directory hierarchy where pkg-installed
## packages reside.
##
## An InstallDir is actually multiple directories, including a base prefix,
## an arch-specific prefix, and maybe more.
##
## @end deftypefn

## Author:  

classdef InstallDir

  properties
    
  endproperties

  methods

    function this = InstallDir ()
      if nargin == 0
        return
      endif
    endfunction

  endmethods

endclassdef