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
##
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
      if isa (filters, "packajoozle.internal.Version")
        mustBeScalar (filters);
        filters = packajoozle.internal.VerFilter(filters.version, "==");
      endif
      mustBeA (filters, "packajoozle.internal.VerFilter");
      #TODO: Should we actually add them incrementally to check for subsumation instead
      #of just assigning a list?
      this.filters = filters;
    endfunction

    function out = disp (this)
      disp (disptr (this));
    endfunction

    function out = dispstr (this)
      if isscalar (this)
        strs = dispstrs (this);
        out = strs{1};
      else
        out = sprintf ("%s %s", size2str (size (this)), class (this));
      endif
    endfunction

    function out = dispstrs (this)
      out = cell (size (this));
      for i = 1:numel (this)
        #TODO: Can this be eliminated by making the base filter set ">= 0.0.0"?
        if isempty (this(i).filters)
          out{i} = "[]";
        else
          out{i} = strjoin (dispstrs (this(i).filters), ", ");
        endif
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
        new_filter = filter(i_new);
        tf_subsumed_by_new = [];
        new_is_subsumed = false;
        for i_current = 1:numel (this.filters)
          if this.filters(i).subsumes (new_filter)
            new_is_subsumed = true;
            #TODO: Check for subsumation going the other wah
          endif
          if new_filter.subsumes (this.filters(i))
            tf_subsumed_by_new(i) = true;
          endif
        endfor
        if new_is_subsumed && ! any (tf_subsumed_by_new)
          error (["VerFilterSet.add_filter: new filter both subsumes and is subsumed. " ...
            "I don't know how to handle that situation.\n" ...
            "New filter: %s\n" ...
            "Existing filters: %s"], ...
            char (new_filter), strjoin (dispstrs (this.filters), ", "));
        endif
        if any (tf_subsumed_by_new)
          this.filters = this.filters(~tf_subsumed_by_new);
        endif
        if ! new_is_subsumed
          this.filters = objvcat (this.filters, new_filter);
        endif
      endfor
    endfunction

    function out = combine (a, b)
      narginchk (2, 2);
      out = a;
      for i_b = 1:numel (b)
        for i_filter_b = 1:numel (b(i_b).filters)
          out.add_filter (b(i_b).filters(i_filter_b));
        endfor
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