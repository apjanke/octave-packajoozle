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

  properties (SetAccess = private)
    % The package name
		name
    % The version, as an Version object
    version
  endproperties

  methods (Static)

    function out = parse_str (pkg_ver_str)
      mustBeCharvec (pkg_ver_str);
      [ix, tok] = regexp (pkg_ver_str, '^(\S+)@(\S+)$', "start", "tokens");
      if isempty (ix)
        error ("Invalid pkgver string: '%s'", pkg_ver_str);
      endif
      tok = tok{1};
      [name, ver_str] = tok{:};
      out = packajoozle.internal.PkgVer (name, ver_str);
    endfunction

  endmethods

  methods

    function this = PkgVer (pkg_name, version)
      if nargin == 0
        return
      endif
      mustBeCharvec (pkg_name);
      if nargin == 1
        in_pkgver = packajoozle.internal.PkgVer.parse_str (pkg_name);
        this.name = in_pkgver.name;
        this.version = in_pkgver.version;
        return
      endif
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
      out = strjoin (dispstrs (this), ", ");
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
      vers = objvcat (vers{:});
      [newest_ver, ix] = max (vers);
      out = this(ix);
    endfunction

    function out = newest_of_each_package (this)
      % The newest of the pkgvers for each package in this array
      out = {};
      names = this.names;
      u_names = unique (names);
      for i_pkg = 1:numel (u_names)
        name = u_names(i_pkg);
        out{end+1} = newest (this(strcmp (name, names)));
      endfor
      out = objvcat (out{:});
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

    function [out,ix] = unique (this)
      if isempty (this)
        out = this;
        ix = [];
        return
      endif
      out = this(1);
      ix = 1;
      for i = 2:numel (this)
        if ! ismember (this(i), out)
          out = objvcat (out, this(i));
          ix(end+1) = i;
        endif
      endfor
    endfunction

    function out = setdiff (a, b)
      out = a;
      out = objdel (out, ismember (a, b));
    endfunction

    function out = intersect (a, b)
      out = a(ismember (a, b));
    endfunction

  endmethods

endclassdef
