## Copyright (C)  
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; If not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Class Constructor} {obj =} PkgVerSpec (pkg_name, version)
## A specification of a package of a particular version.
##
## A PkgVerSpec specifies a package by its name and an exact version.
##
## version is a packajoozle.internal.OctVer object, or something that can
## be converted to one.
##
## @end deftypefn

## Author:	

classdef PkgVerSpec

  properties
    % The package name
		name
    % The version, as an OctVer object
    version
  endproperties

  methods

    function this = PkgVerSpec (pkg_name, version)
      if nargin == 0
        return
      endif
      mustBeCharVec (pkg_name);
      version = packajoozle.internal.OctVer (version);
    endfunction

    function out = eq (A, B)
      mustBeScalar (A);
      mustBeScalar (B);
      out = isequal (A, B);
    endfunction

  endmethods

endclassdef