## Copyright (C) 2019 Andrew Janke
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
## @deftypefn {Class Constructor} {obj =} VerFilterSet ()
## A set of VerFilters that are considered together.
##
## A VerFilterSet is a set of VerFilters whose effect is considered in combination.
## This allows you to do things like specify version ranges or exclude known-bad
## particular versions. Examples:
##
##   > 1.2.3
##   > 1.2.3, <= 2.0
##   > 1.2.3, <= 2.0, != 1.4.12
##
## The different filters included in the set are always ANDed together.
##
## The empty filter set matches any version, and is equivalent to ">= 0.0.0".
##
## @end deftypefn

## Author:  

classdef VerFilterSet

  properties
    filters = [];
  endproperties

  methods

    function this = VerFilterSet (filters)
      if nargin == 0
        return
      endif
      if ischar (filters)
        filters = cellstr (filters);
      endif
      if iscellstr (filters)
        filters = packajoozle.internal.VerFilter.parse_ver_filter (filters);
      endif
      mustBeA (filters, "packajoozle.internal.VerFilter");
      this.filters = filters;
    endfunction

    function out = disp (this)
      if isscalar (this)
        strs = dispstrs (this);
        disp (strs{1});
      else
        disp (sprintf ("%s %s", size2str (size (this)), class (this)));
      endif
    endfunction

    function out = dispstrs (this)
      out = cell (size (this));
      for i = 1:numel (this)
        out{i} = strjoin (dispstrs (this(i).filters), ", ");
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

    function out = add_filter (this, filter)
      mustBeScalar (this);
      filter = makeItBeA (filter, "packajoozle.internal.VerFilter");
      for i_new = 1:numel (filter)
        for i_current = 1:numel (this.filters)
          subsumed = false;
          if this.filters(i).subsumes (filter(i_new))
            subsumed = true;
            break;
          endif
        endfor
        if ! subsumed
          this.filters = packajoozle.internal.Util.objcat (this.filters, filter(i_new));
        endif
      endfor
    endfunction

    function out = matches (this, vers)
      mustBeScalar (this);
      mustBeA (this, "packajoozle.internal.VerFilterSet");
      vers = makeItBeA (vers, "packajoozle.internal.Version");
      out = true (size (vers));
      for i_ver = 1:numel (vers)
        for i_filter = 1:numel (this.filters)
          if ! this.filters(i_filter).matches (vers(i_ver))
            out(i_ver) = false;
            break
          endif
        endfor
      endfor
    endfunction

  endmethods

endclassdef