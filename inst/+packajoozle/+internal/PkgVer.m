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
## @deftypefn {Class Constructor} {obj =} PkgVer (pkg_name, version)
## A specification of a package of a particular version.
##
## A PkgVer specifies a package by its name and an exact version.
##
## pkg_name is a valid package name, as a string.
## 
## version is a packajoozle.internal.Version object, or something that can
## be converted to one.
##
## @end deftypefn

## Author:	

classdef PkgVer

  properties
    % The package name
		name
    % The version, as an Version object
    version
  endproperties

  methods

    function this = PkgVer (pkg_name, version)
      if nargin == 0
        return
      endif
      mustBeCharVec (pkg_name);
      version = packajoozle.internal.Version (version);
    endfunction

    function out = eq (A, B)
      mustBeScalar (A);
      mustBeScalar (B);
      out = isequal (A, B);
    endfunction

  endmethods

endclassdef