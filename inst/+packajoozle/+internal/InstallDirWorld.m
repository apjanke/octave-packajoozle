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
## @deftypefn {Class Constructor} {obj =} InstallDirWorld ()
##
## A set of named InstallDirs.
##
## An InstallDirWorld represents the set of all InstallDirs known to an
## Octave installation/session, and the set of packages in this "world".
##
## @end deftypefn

classdef InstallDirWorld < packajoozle.internal.IPackageMetaSource

  properties (SetAccess = private)
    inst_dir_map = struct
    % Cellstr containing tags for this' instdirs
    search_order = {}
  endproperties

  methods (Static)
    function out = default ()
      % The default instdir world used by Octave; including "user" and "global"
      % InstallDirs. This is the world seen by the original `pkg` utility.
      out = packajoozle.internal.InstallDirWorld;

      [prefix, arch_prefix] = pkg ("prefix");
      meta_dir = fileparts (pkg ("local_list"));
      user_dir = packajoozle.internal.InstallDir (meta_dir, prefix, arch_prefix, "user");
      user_dir.package_list_var_name = "local_packages";
      out = out.register_installdir ("user", user_dir);

      [prefix, arch_prefix] = pkg ("prefix", "-global");
      meta_dir = fileparts (pkg ("global_list"));
      global_dir = packajoozle.internal.InstallDir (meta_dir, prefix, arch_prefix, "global");
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

    function out = disp (this)
      if isscalar (this)
        str = {sprintf("%s: %s", class(this), strjoin(this.search_order, ", "))};
        for i_tag = 1:numel (this.search_order)
          tag = this.search_order{i_tag};
          inst_dir = this.get_installdir_by_tag (tag);
          str = [str; {
            ["  " tag ":"]
            sprintf("    meta_dir: %s", inst_dir.meta_dir)
            sprintf("    prefix: %s", inst_dir.prefix)
            sprintf("    arch_prefix: %s", inst_dir.arch_prefix)
            sprintf("    package_list_var_name: %s", inst_dir.package_list_var_name)
          }];
        endfor
        printf("%s", strjoin (str, "\n"));
      else
        disp (dispstr (this));
      endif
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
        o = this(i);
        out{i} = sprintf("[%s: %s]", class (o), strjoin (o.tags, ", "));
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

    function this = register_installdir (this, tag, inst_dir)
      mustBeA (inst_dir, "packajoozle.internal.InstallDir");
      if ismember (tag, this.search_order)
        warning ("InstallDirWorld.register_installdir: replacing existing instdir '%s'", tag);
      else
        this.search_order{end+1} = tag;
      endif
      this.inst_dir_map.(tag) = inst_dir;
    endfunction

    function out = tags (this)
      out = this.search_order;
    endfunction

    function out = get_installdir_by_tag (this, tag)
      if ! ismember (tag, this.search_order)
        error ("InstallDirWorld.get_installdir_by_tag: no such instdir: '%s'", tag);
      endif
      out = this.inst_dir_map.(tag);
    endfunction

    function out = get_all_installdirs (this)
      c = {};
      for i = 1:numel (this.search_order)
        c{i} = this.inst_dir_map.(this.search_order{i});
      endfor
      out = objvcat (c{:});
    endfunction

    function out = list_all_installed_packages (this, format = "pkgver")
      # Returns list as PkgVers
      inst_dirs = this.get_all_installdirs;
      switch format
        case "pkgver"
          out = inst_dirs(1).get_package_list;
          for i = 2:numel (inst_dirs)
            out = objvcat (out, inst_dirs(i).get_package_list);
          endfor
        case "desc"
          out = inst_dirs(1).get_package_list_descs;
          for i = 2:numel (inst_dirs)
            out = [out inst_dirs(i).get_package_list_descs];
          endfor
        otherwise
          error ("InstallDirWorld.list_all_installed_packages: invalid format: '%s'", format);
      endswitch
    endfunction

    function out = descs_for_installed_package (this, pkgver)
      descs = this.list_all_installed_packages ("desc");
      out = {};
      for i = 1:numel (descs)
        desc = descs{i};
        desc_pkgver = packajoozle.internal.PkgVer (desc.name, desc.version);
        if desc_pkgver == pkgver
          out{end+1} = desc;
        endif
      endfor
    endfunction

    function out = is_installed (this, pkgvers)
      pkgver = makeItBeA (pkgvers, "packajoozle.internal.PkgVer");
      out = false (size (pkgvers));
      installdirs = this.get_all_installdirs;
      for i_pkg = 1:numel (pkgvers)
        pkgver = pkgvers(i_pkg);
        for i_dir = 1:numel (installdirs)
          if installdirs(i_dir).is_installed (pkgver)
            out(i_pkg) = true;
            break;
          endif
        endfor
      endfor
    endfunction

    function out = list_installed_matching (this, pkgreqs)
      mustBeA (pkgreqs, "packajoozle.internal.PkgVerReq");
      installed = this.list_all_installed_packages;
      out = {};
      for i = 1:numel (pkgreqs)
        tf = pkgreqs(i).matches (installed);
        if any (tf)
          out{end+1} = installed(tf);
        endif
      endfor
      out = objvcat (out{:});
      out = unique (out);
    endfunction

    % IPackageMetaSource implementation

    function out = list_available_packages (this)
      out = this.list_all_installed_packages;
    endfunction

    function out = get_package_description (this, pkgver)
      pkgver = makeItBeA(pkgver, "packajoozle.internal.PkgVer");
      descs = this.descs_for_installed_package (pkgver);
      if isempty (descs)
        error ("InstallDirWorld.get_package_description: package not installed: %s", ...
          char (pkgver));
      endif
      out = descs{1};
    endfunction

    function out = loaded_packages (this)
      inst_dirs = this.get_all_installdirs;
      out = {};
      for i = 1:numel (inst_dirs)
        inst_dir = inst_dirs(i);
        out{i} = inst_dir.loaded_packages;
      endfor
      out = unique (objvcat (out{:}));
    endfunction

    function out = unload_packages (this, pkgvers)
      unloaded = {};
      inst_dirs = this.get_all_installdirs;
      for i = 1:numel (inst_dir)
        inst_dir = inst_dirs(i);
        tf = inst_dir.is_loaded (pkgvers);
        inst_dir.unload_packages (pkgvers(tf));
        unloaded{end+1} = pkgvers(tf);
      endfor
      unloaded = unique(objvcat (unloaded{:}));
      out.unloaded = unloaded;
      out.not_loaded_in_the_first_place = setdiff (pkgvers, unloaded);
    endfunction

  endmethods

endclassdef