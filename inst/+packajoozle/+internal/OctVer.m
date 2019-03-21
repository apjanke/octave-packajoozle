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
## @deftypefn {Class Constructor} {obj = } OctVer (ver_str)
## An Octave-style version.
##
## An OctVer is an Octave-style version. This is a version in the form
## "1.2.3" or "1.2.3+suffix": a dot-separated list of numeric elements,
## followed by an optional suffix. It is similar to a SemVer version.
##
## A version with any "+" suffix is considered to be strictly greater than
## the "base" version with the same elements but no suffix. Suffixes
## themselves are compared asciibetically.
##
## @end deftypefn

## Author:	

classdef OctVer

  properties
    % The full string that represents this version
		string
    % The numeric elements in this version (double vector)
    elements
    % The suffix (char)
    suffix
  endproperties

  methods

    function this = OctVer (ver_str)
      if nargin == 0
        return
      endif
      if isequal (class (ver_str), "packajoozle.internal.OctVer")
        this = ver_str;
        return;
      endif
      s = packajoozle.internal.OctVer.parse_version_str (ver_str);
      this.string = ver_str;
      this.elements = s.elements;
      this.suffix = s.suffix;
    endfunction

    function disp (this)
      if isscalar (this)
        disp (char (this));
      else
        disp (sprintf ("%s %s"), size2str (this), class (this));
      endif
    endfunction

    function out = dispstrs (this)
      out = cell (size (this));
      for i = 1:numel (this)
        out{i} = char (this(i));
      endfor
    endfunction

    function out = char (this)
      if ! isscalar (this)
        error ("OctVer: char() only works on scalar OctVer objects");
      endif
      els_strs = arrayfun (@(x) {num2str(x)}, this.elements);
      out = [strjoin(els_strs, ".") this.suffix];
    endfunction

    function out = cmp (A, B)
      %CMP Compare values, returning -1, 0, or 1 to indicate ordering
      [A, B] = promote (A, B);
      # TODO: Implement nonscalar array support
      mustBeScalar (A);
      mustBeScalar (B);
      a_els = A.elements;
      b_els = B.elements;
      if numel (a_els) < numel (b_els)
        a_els(end:numel (b_els)) = 0;
      endif
      if numel (b_els) < numel (a_els)
        b_els(end:numel (a_els)) = 0;
      endif
      [a_suffix_proxy, b_suffix_proxy] = packajoozle.internal.OctVer.string_proxy_keys (...
        A.suffix, B.suffix);
      a_vals = [a_els a_suffix_proxy];
      b_vals = [b_els b_suffix_proxy];
      if isequal (a_vals, b_vals)
        out = 0;
        return
      endif
      [~, ix] = sortrows ([a_vals; b_vals]);
      if ix(1) == 1
        out = -1;
      else
        out = 1;
      endif
    endfunction

    function out = lt (A, B)
      x = cmp (A, B);
      out = x == -1;
    endfunction

    function out = le (A, B)
      x = cmp (A, B);
      out = x == -1 || x == 0;
    endfunction

    function out = eq (A, B)
      x = cmp (A, B);
      out = x == 0;
    endfunction

    function out = ne (A, B)
      x = cmp (A, B);
      out = x != 0;
    endfunction

    function out = gt (A, B)
      x = cmp (A, B);
      out = x == 1;
    endfunction

    function out = ge (A, B)
      x = cmp (A, B);
      out = x == 0 || x == 1;
    endfunction

    function [A, B] = promote (A, B)
      if ! isa(A, "packajoozle.internal.OctVer")
        A = packajoozle.internal.OctVer (A);
      endif
      if ! isa(B, "packajoozle.internal.OctVer")
        B = packajoozle.internal.OctVer (B);
      endif      
    endfunction

  endmethods

  methods (Static = true)
    function out = parse_version_str (ver_str)
      pat = '([\d\.]+)(\+\w*)?';
      [ix, tok] = regexp (ver_str, pat, "start", "tokens");
      if isempty (ix)
        error ("OctVer: invalid version string: %s", ver_str);
      endif
      tok = tok{1};
      els_str = tok{1};
      if (numel (tok) > 1)
        out.suffix = tok{2};
      else
        out.suffix = "";
      endif
      out.elements = str2double (strsplit (els_str, "."));
    endfunction

    function [A_keys, B_keys] = string_proxy_keys (A, B)
      A = cellstr (A);
      B = cellstr (B);
      n_a = numel (A);
      both = [A(:); B(:)];
      [u, ix, jx] = unique (both);
      A_keys = jx(1:n_a);
      B_keys = jx(2:end);
      A_keys = reshape (A_keys, size (A));
      B_keys = reshape (B_keys, size (B));
    endfunction
  endmethods

endclassdef

