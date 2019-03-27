## Copyright (C) 2019 Andrew Janke
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
## @deftypefn {Class Constructor} {obj = } Version (ver_str)
##
## An Octave-style version.
##
## An Version is an Octave-style version. This is a version in the form
## "1.2.3" or "1.2.3+suffix": a dot-separated list of numeric elements,
## followed by an optional suffix. It is similar to a SemVer version.
##
## A version with any "+" suffix is considered to be strictly greater than
## the "base" version with the same elements but no suffix. Suffixes
## themselves are compared asciibetically.
##
## @end deftypefn

## Note: Keep in mind that Versions can only be row vectors, because Octave
## doesn't support reshape() or repmat() for objects.

classdef Version

  properties (Constant)
    version_regexp_pat = '[\d\.]+(?=\+\S*)?'
  endproperties

  properties (SetAccess = private)
    % The full string that represents this version
		string = ""
    % The numeric elements in this version (double vector)
    elements = 0
    % The suffix (char)
    suffix = ""
  endproperties

  methods (Static)
    function out = parse_versions (ver_strs)
      ver_strs = cellstr (ver_strs);
      out = packajoozle.internal.Util.repmat_object_to_vector (packajoozle.internal.Version, numel (ver_strs));
      for i = 1:numel (ver_strs)
        out(i) = packajoozle.internal.Version (ver_strs{i});
      endfor
    endfunction
  endmethods

  methods

    function this = Version (ver_str)
      if nargin == 0
        return
      endif
      if isequal (class (ver_str), "packajoozle.internal.Version")
        this = ver_str;
        return;
      endif
      s = packajoozle.internal.Version.parse_version_str (ver_str)
      this.string = ver_str;
      this.elements = s.elements;
      this.suffix = s.suffix;
    endfunction

    function disp (this)
      disp (dispstr (this));
    endfunction

    function out = dispstr (this)
      if isscalar (this)
        out = char (this);
      else
        out = sprintf ("%s %s", size2str (size (this)), class (this));
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
        error ("Version: char() only works on scalar Version objects");
      endif
      out = sprintf ("%s (%s %s)", this.string, mat2str(this.elements), this.suffix);
    endfunction

    function out = cmp (A, B)
      %CMP Compare values, returning -1, 0, or 1 to indicate ordering
      [A, B] = promote (A, B);
      packajoozle.internal.Util.mustBeCompatibleSizes (A, B);

      [keys_a, keys_b] = proxykeys (A, B)
      tf_lt = keys_a < keys_b;
      tf_eq = keys_a == keys_b;
      tf_gt = keys_a > keys_b;
      out = NaN (size (tf_lt));
      out(tf_lt) = -1;
      out(tf_eq) = 0;
      out(tf_gt) = 1;
      fprintf("cmp (%s, %s) => %d\n", char (A), char (B), out);
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
      if ! isa(A, "packajoozle.internal.Version")
        A = packajoozle.internal.Version (A);
      endif
      if ! isa(B, "packajoozle.internal.Version")
        B = packajoozle.internal.Version (B);
      endif      
    endfunction

    function [out, ix] = sort (this)
      keys = proxykeys (this);
      [~, ix] = sort (keys);
      out = this(ix);
    endfunction

    function [out, ix, jx] = unique (this)
      keys = proxykeys (this);
      [~, ix, jx] = unique (keys);
      out = this(ix);
    endfunction

    function [out, ix] = max (this)
      [~, ix] = max (proxykeys (this));
      out = this(ix);
    endfunction
    
    function [out, ix] = min (this)
      [~, ix] = min (proxykeys (this));
      out = this(ix);
    endfunction

    function [keys_A, keys_B] = proxykeys (A, B)
      if nargin == 1
        this = A;
        this = normalize_elements (this(:));
        el_keys = { this.elements };
        el_keys = cat (1, el_keys{:});
        [~, ~, suffix_keys] = unique ({this.suffix}');
        key_rows = [el_keys suffix_keys];
        [~, ~, keys_A] = unique (key_rows, "rows");
      else
        [A, B] = normalize_elements (A, B);
        el_keys_a = { A.elements };
        el_keys_a = cat (1, el_keys_a{:});
        el_keys_b = { B.elements };
        el_keys_b = cat (1, el_keys_b{:});
        [suffix_keys_a, suffix_keys_b] = packajoozle.internal.Util.proxy_keys_unique_trick (...
          {A.suffix}', {B.suffix}');
        key_rows_a = [el_keys_a suffix_keys_a];
        key_rows_b = [el_keys_b suffix_keys_b];
        n_a = numel (A);
        all_key_rows = [key_rows_a; key_rows_b];
        [~, ~, jx] = unique (all_key_rows, "rows");
        keys_A = jx(1:n_a);
        keys_B = jx(n_a+1:end);
      endif
    endfunction

    function [A, B] = normalize_elements (A, B)
      if nargin == 1
        a_els = { A.elements };
        all_els = a_els;
        max_n_els = -1;
        for i = 1:numel (all_els)
          max_n_els = max (max_n_els, numel (all_els{i}));
        endfor
        for i = 1:numel (A)
          A(i).elements(end+1:max_n_els) = 0;
        endfor
      else
        a_els = { A.elements };
        b_els = { B.elements };
        all_els = [a_els b_els];
        max_n_els = -1;
        for i = 1:numel (all_els)
          max_n_els = max (max_n_els, numel (all_els{i}));
        endfor
        for i = 1:numel (A)
          A(i).elements(numel(A(i).elements)+1:max_n_els) = 0;
        endfor
        for i = 1:numel (B)
          B(i).elements(numel(B(i).elements)+1:max_n_els) = 0;
        endfor
      endif
    endfunction
  endmethods

  methods (Static = true)
    function out = parse_version_str (ver_str)
      pat = '([\d\.]+)(\+\w*)?';
      [ix, tok] = regexp (ver_str, pat, "start", "tokens");
      if isempty (ix)
        error ("Version: invalid version string: %s", ver_str);
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

  endmethods

endclassdef

