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
## @deftypefn {Class Constructor} {obj =} IPackageMetaSource ()
##
## A source of package metadata for a particular world of packages
##
## This is an abstract interface for classes that represent sets of
## packages whose metadata is available through them. It is used for generically
## resolving dependencies in the different contexts of installation and
## loading.
##
## @end deftypefn

## Note: this is supposed to be an abstract class, but I couldn't get that to
## work in Octave 4.4.1

classdef IPackageMetaSource

  methods

    % List packages that are available in this source. "Available" may mean "installed"
    % or "published", or something else, depending on the context. All "available" packages
    % must be available to return description info via "get_package_description", though.
    % Returns an array of packajoozle.internal.PkgVer, or [].
    function out = list_available_packages (this)
      error ("IPackageMetaSource.list_available_packages: BUG: this is an abstract method.");
    endfunction

    % Get the DESCRIPTION metadata for a single package/version.
    % Takes a scalar packajoozle.internal.PkgVer as input
    % Returns a scalar struct. Raises an error if pkgver is not available in this.
    function out = get_package_description (this, pkgver)
      error ("IPackageMetaSource.get_package_description: BUG: this is an abstract method.");
    endfunction

    function [out, unmatched_reqs] = list_available_packages_matching (this, pkgreqs)
      pkgreqs = makeItBeA (pkgreqs, "packajoozle.internal.PkgVerReq");
      pkgreqs = condense (pkgreqs);
      available = this.list_available_packages;
      out = {};
      unmatched_reqs = emptyobj (packajoozle.internal.PkgVerReq);
      for i = 1:numel (pkgreqs)
        pkgreq = pkgreqs(i);
        out{end+1} = available(pkgreq.matches (available));
        if isempty (out{end})
          unmatched_reqs(end+1) = pkgreq;
        endif
      endfor
      out = unique (objvcat (out{:}));
    endfunction

    % Resolves a set of pkgreqs against this' packages, choosing the newest available
    % package that meets the reqs.
    % Returns a PkgVer array.
    function out = resolve_newest_packages_matching (this, pkgreqs)
      pkgreqs = makeItBeA (pkgreqs, "packajoozle.internal.PkgVerReq");
      pkgreqs = condense (pkgreqs);
      installed = this.list_available_packages_matching (pkgreqs);
      out = {};
      for i = 1:numel (pkgreqs)
        pkgreq = pkgreqs(i);
        ix = find (pkgreq.matches (installed))
        if isempty (ix)
          error ("no available package matching req %s", char (pkgreq));
        endif
        out{i} = installed(ix);
      endfor
      out = objvcat (out{:});
    endfunction

  endmethods

endclassdef