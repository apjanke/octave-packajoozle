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
## @deftypefn {Class Constructor} {obj =} InstallDirWorld ()
## A set of InstallDirs
##
## An InstallDirWorld represents the set of all InstallDirs known to an
## Octave installation/session.
##
## @end deftypefn

## Author:  

classdef InstallDirWorld

  properties
    inst_dir_map = struct
  endproperties

  methods (Static)
    function out = default ()
      out = packajoozle.internal.InstallDirWorld;

      [prefix, arch_prefix] = pkg ("prefix");
      meta_dir = fileparts (pkg ("local_list"));
      user_dir = packajoozle.internal.InstallDir (meta_dir, prefix, arch_prefix, "user");
      user_dir.package_list_var_name = "local_packages";
      out = out.register_installdir ("user", user_dir);

      [prefix, arch_prefix] = pkg ("prefix", "-global");
      meta_dir = fileparts (pkg ("global_list"));
      global_dir = packajoozle.internal.InstallDir (prefix, arch_prefix, "global");
      #TODO: If global install location has been aliased to user install location,
      # this will break. Probably need to probe the package index file to see
      # what's there
      global_dir.package_list_var_name = "global_packages";
      out = out.register_installdir ("global", global_dir);
    endfunction
  endmethods

  methods

    function this = InstallDirWorld ()
      if nargin == 0
        return
      endif
    endfunction

    function this = register_installdir (this, tag, inst_dir)
      mustBeA (inst_dir, "packajoozle.internal.InstallDir");
      this.inst_dir_map.(tag) = inst_dir;
    endfunction

    function out = tags (this)
      out = fieldnames (this.inst_dir_map);
    endfunction

    function out = get_installdir_by_tag (this, tag)
      out = this.inst_dir_map.(tag);
    endfunction

    function out = get_all_installdirs (this)
      c = struct2cell (this.inst_dir_map);
      if isempty (c)
        out = [];
      else
        out = packajoozle.internal.Util.objcat (c{:});
      endif
    endfunction

  endmethods

endclassdef