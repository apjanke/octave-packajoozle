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
  endproperties

  properties
    version
    operator
  endproperties

  methods

    function this = VerFilter (version, operator)
      if nargin == 0
        return
      endif
      version = packajoozle.internal.Version (version);
      mustBeCharVec (operator);
      if (! ismember (operator, packajoozle.internal.VerFilter.valid_operators))
        error ("VerFilter: invalid operator: %s", operator);
      endif
      this.version = version;
      this.operator = operator;
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
        out{i} = sprintf ("%s %s", this(i).operator, char (this(i).version));
      endfor
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
  endmethods

endclassdef