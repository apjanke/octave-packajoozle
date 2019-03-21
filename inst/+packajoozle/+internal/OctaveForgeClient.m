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
## @deftypefn {Class Constructor} {obj =} OctaveForgeClient ()
## Octave Forge client.
##
## A client for getting directory info, package metadata, and package
## distribution downloads from Octave Forge.
##
## @end deftypefn

## Author:  

classdef OctaveForgeClient

  properties
    
  endproperties

  methods

    function this = OctaveForgeClient ()
      if nargin == 0
        return
      endif
    endfunction

  endmethods

endclassdef