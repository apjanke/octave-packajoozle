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
## @deftypefn {Class Constructor} {obj =} PkgVerReq (pkg_name, ver_filters)
## A package version "request" or filter.
##
## Specifies a request or filter for a given package with version filtering
## conditions. This allows you to specify something like "symbolic version 1.2"
## or "io version >= 1.2 and < 2.0".
##
## pkg_name (char) is the name of the package.
##
## ver_filters (packajoozle.internal.VerFilter) is an array of version filters.
## May be empty, in which case it defaults to ">= 0.0.0", and all versions are
## considered to match.
##
## @end deftypefn

## Author:  

classdef PkgVerReq

  properties
    package
    ver_filters
  endproperties

  methods

    function this = PkgVerReq (pkg_name, ver_filters)
      if nargin == 0
        return
      endif
      mustBeCharVec (pkg_name);
      if nargin < 2
        ver_filters = packajoozle.internal.VerFilter ("0.0.0", ">=");
      endif
      ver_filters = packajoozle.internal.VerFilter (ver_filters);
      this.ver_filters = ver_filters;
    endfunction

    function disp (this)
      if (isscalar (this))
        s = this.dispstrs;
        disp (["  " s{1}]);
      else
        disp (sprintf ("%s %s", size2str (size (this)), class (this)));
      endif
    endfunction

    function out = dispstrs (this)
      out = cell (size (this));
      for i = 1:numel (this)
        ver_filter_str = strjoin (dispstrs (this(i).ver_filters, ", "));
        out{i} = sprintf ("%s %s", this(i).package, ver_filter_str));
      endfor
    endfunction

    function out = matches (this, pkg_specs)
      mustBeScalar (this);
      out = false (size (pkg_specs));
      for i = 1:numel (pkg_specs)
        p = pkg_specs(i);
        if isequal (this.package, p.package)
          all_filters_matched = true;
          for i = 1:numel (this.ver_filters)
            if ! this.ver_filters(i).matches (p.version)
              all_filters_matched = false;
              break;
            endif
          endfor
          out(i) = all_filters_matched;
        endif
      endfor
    endfunction

  endmethods

endclassdef