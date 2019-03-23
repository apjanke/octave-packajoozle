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
## @deftypefn {Class Constructor} {obj =} NullPackageMetaSource ()
##
## A PackageMetaSource that contains no data
##
## This is a dummy "empty set" placeholder object for IPackageMetaSource
## clients.
##
## @end deftypefn


classdef NullPackageMetaSource < packajoozle.internal.IPackageMetaSource

  methods

    % List packages that are available in this source. "Available" may mean "installed"
    % or "published", or something else, depending on the context. All "available" packages
    % must be available to return description info via "get_package_description", though.
    % Returns an array of packajoozle.internal.PkgVer, or [].
    function out = list_available_packages (this)
      out = [];
    endfunction

    % Get the DESCRIPTION metadata for a single package/version.
    % Takes a scalar packajoozle.internal.PkgVer as input
    % Returns a scalar struct. Raises an error if pkgver is not available in this.
    function out = get_package_description_meta (this, pkgver)
      error ("NullPackageMetaSource: package not available: %s", char (pkgver));
    endfunction

  endmethods

endclassdef