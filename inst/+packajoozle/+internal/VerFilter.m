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
## @deftypefn {Class Constructor} {obj =} VerFilter (version, operator)
##
## A filter that compares versions
##
## A VerFilter specifies a version comparison that is done based on
## a reference version and an operator. The operator can be one of
## "<", "<=", "==", "!=", "~=" ">=", or ">". (These are the same operations
## that the @code{compare_versions} function supports.)
##
## @end deftypefn

## Author:  

classdef VerFilter

  properties (Constant, Hidden)
    valid_operators = { "<", "<=", "==", "!=", "~=" ">=", ">" }
    ver_filter_pat = ['^\s*(<|<=|=|==|\!=|~=|>|>=)\s*(' ...
      packajoozle.internal.Version.version_regexp_pat ')\s*$']
  endproperties

  properties
    version = packajoozle.internal.Version ("0.0.0")
    operator = ">="
  endproperties

  methods (Static)

    function out = looks_like_ver_filter_str (strs)
      strs = cellstr (strs);
      [ix, tok] = regexp (strs, packajoozle.internal.VerFilter.ver_filter_pat);
      out = ! cellfun (@(x) isempty(x), ix);
    endfunction

    function out = parse_ver_filter (strs)
      strs = cellstr (strs);
      if isempty (strs)
        out = [];
        return
      endif
      c = cell (size (strs));
      for i = 1:numel (strs)
        str = strs{i};
        if ! isempty (regexp (str, '^[\d\.]+$'))
          out = packajoozle.internal.VerFilter (str);
          return
        endif
        [ix, tok] = regexp (str, packajoozle.internal.VerFilter.ver_filter_pat, ...
          "start", "tokens");
        if isempty (ix)
          error ("VerFilter: invalid version filter string: '%s'", str);
        endif
        tok = tok{1};
        c{i} = packajoozle.internal.VerFilter (tok{2}, tok{1});
      endfor
      out = objvcat (c{:});
    endfunction

    function out = canonicalize_operator (operator)
      switch operator
        case { "<" "<=" "==" "!=" ">" ">=" }
          out = operator;
        case "~="
          out = "!=";
        case "="
          out = "==";
        otherwise
          error ("VerFilter: invalid operator: '%s'", operator);
      end
    endfunction
    
  endmethods

  methods

    function this = VerFilter (arg, operator = "==")
      if nargin == 0
        return
      elseif nargin == 1
        if isa (arg, "packajoozle.internal.Version")
          mustBeScalar (arg);
          this.version = arg;
          this.operator = '==';
        elseif ischar (arg)
          str = mustBeCharvec (arg);
          if packajoozle.internal.VerFilter.looks_like_ver_filter_str (str)
            obj = packajoozle.internal.VerFilter.parse_ver_filter (str);
            this.version = obj.version;
            this.operator = obj.operator;
          else
            this.version = packajoozle.internal.Version (str);
            this.operator = '==';   
          endif
        else
          error ("Invalid arg: Expecting char or packajoozle.internal.Version, got a %s", ...
            class (arg));
        endif
      else
        this.version = makeItBeA (arg, "packajoozle.internal.Version");
        mustBeCharvec (operator);
        this.operator = packajoozle.internal.VerFilter.canonicalize_operator (operator);
      endif
    endfunction

    function this = set.operator (this, operator)
      this.operator = packajoozle.internal.VerFilter.canonicalize_operator (operator);
    endfunction

    function this = set.version (this, version)
      this.version = makeItBeA (version, "packajoozle.internal.Version");
    endfunction

    function disp (this)
      disp (dispstr (this));
    endfunction

    function out = dispstr (this)
      if (isscalar (this))
        s = this.dispstrs;
        out = s{1};
      else
        out = sprintf ("%s %s", size2str (size (this)), class (this));
      endif
    endfunction

    function out = dispstrs (this)
      out = cell (size (this));
      for i = 1:numel (this)
        out{i} = sprintf ("%s %s", this(i).operator, char (this(i).version));
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

    function out = matches (this, ver)
      %MATCHES True if given version matches this filter
      mustBeScalar (this);
      ver = packajoozle.internal.Version (ver);
      out = false (size (ver));
      for i = 1:numel (ver)
        out(i) = compare_versions (char (ver(i)), char (this(i).version), this.operator);
      endfor
    endfunction

    function out = subsumes (a, b)
      mustBeScalar (a);
      mustBeScalar (b);
      a = makeItBeA (a, "packajoozle.internal.VerFilter");
      b = makeItBeA (b, "packajoozle.internal.VerFilter");
      switch a.operator
        case "<"
          out = (isequal (b.operator, "<") && a.version <= b.version) ...
            || (isequal (b.operator, "<=") && a.version < b.version);
        case "<="
          out = (isequal (b.operator, "<") && a.version < b.version) ...
            || (isequal (b.operator, "<=") && a.version <= b.version);
        case "=="
          out = isequal (b.operator, "==") && isequal (a.version, b.version);
        case "!="
          out = isequal (b.operator, "1=") && isequal (a.version, b.version);
        case ">="
          out = (isequal (b.operator, ">=") && a.version >= b.version) ...
            || (isequal (b.operator, ">") && a.version > b.version);
        case ">"
          out = (isequal (b.operator, ">") && a.version >= b.version) ...
            || (isequal (b.operator, ">=") && a.version > b.version);
        otherwise
          error ("internal error: BUG: unexpected operator: %s", a.operator);
      endswitch
      fprintf ("%s subsumes %s: %d\n", char(a), char(b), out);
    endfunction

    function out = to_filter_set (this)
      out = packajoozle.internal.VerFilterSet;
      for i = 1:numel (this)
        out.add_filter (this(i));
      endfor
    endfunction
    
  endmethods

endclassdef