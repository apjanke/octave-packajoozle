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
##
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
      this.name = pkg_name;
      this.version = version;
    endfunction

    function out = names (this)
      out = {this.name};
    endfunction

    function out = versions (this)
      out = out = packajoozle.internal.Util.objcatc ({this.version});
    endfunction
    
    function out = eq (A, B)
      mustBeScalar (A);
      mustBeScalar (B);
      out = isequal (A, B);
    endfunction

    function out = disp (this)
      disp (dispstr (this));
    endfunction

    function out = dispstr (this)
      out = strjoin (dispstrs (this), "; ");
    endfunction
    
    function out = dispstrs (this)
      out = cell (size (this));
      for i = 1:numel (this)
        out{i} = sprintf ("%s %s", this(i).name, char (this(i).version));
      endfor
    endfunction
    
    function out = char (this)
      if ! isscalar (this)
        error ("%s: char() only works on scalar %s objects; this is %s", ...
          class (this), class (this), size2str (size (this)));
      endif
      strs = dispstrs (this);
      out = strs{1};
    endfunction

    function out = ismember (a, b)
      out = false (size (a));
      for i_a = 1:numel (a)
        for i_b = 1:numel (b)
          if a(i_a) == b(i_b)
            out(i_a) = true;
            break;
          endif
        endfor
      endfor
    endfunction

    function out = newest (this)
      % The newest of these pkgvers, if they are all the same package
      u_names = unique ({this.name});
      if numel (u_names) > 1
        error ("PkgVer: cannot do newest(): multiple packages in list: %s", ...
          strjoin (u_names, ", "));
      endif
      vers = {this.version};
      vers = packajoozle.internal.Util.objcat (vers{:});
      [newest_ver, ix] = max (vers);
      out = this(ix);
    endfunction

    function [out,ix] = sort (this)
      %SORT Sorts by package name, and then by version
      # Radix sort!
      out = this;
      ver = packajoozle.internal.Util.objcatc ({out.version});
      ix = 1:numel(this);
      [~, ix1] = sort (ver);
      out = out(ix1);
      ix = ix(ix1);
      [~, ix2] = sort ({out.name});
      out = out(ix2);
      ix = ix(ix2);
    endfunction

  endmethods

endclassdef