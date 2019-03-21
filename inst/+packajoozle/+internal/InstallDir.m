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
## @deftypefn {Class Constructor} {obj =} InstallDir ()
## A local directory where pkg package installations reside.
##
## An InstallDir is a local filesystem directory hierarchy where pkg-installed
## packages reside.
##
## An InstallDir is actually multiple directories, including a base prefix,
## an arch-specific prefix, and maybe more.
##
## @end deftypefn

## Author:  

classdef InstallDir

  properties
    % A tag or name identifying this install dir
    tag
    % The main directory under which to install packages
    prefix
    % The architecture-dependent directory. May be the same as prefix.
    arch_prefix
    % Where pkg's metadata files are held
    meta_dir
    % The variable to save in the "octave_packages" file
    package_list_var_name = "octave_packages"
  endproperties

  methods (Static)

    function out = get_user_installdir ()
      [prefix, arch_prefix] = pkg ("prefix");
      meta_dir = fileparts (pkg ("local_list"));
      out = packajoozle.internal.InstallDir (meta_dir, prefix, arch_prefix, "user");
      out.package_list_var_name = "local_packages";
    endfunction

    function out = get_global_installdir ()
      [prefix, arch_prefix] = pkg ("prefix", "-global");
      meta_dir = fileparts (pkg ("global_list"));
      out = packajoozle.internal.InstallDir (prefix, arch_prefix, "global");
      out.package_list_var_name = "global_packages";
    endfunction

  endmethods

  methods

    function this = InstallDir (meta_dir, prefix, arch_prefix, tag)
      if nargin == 0
        return
      endif
      if nargin < 3 || isempty (arch_prefix)
        arch_prefix = prefix;
      endif
      if nargin < 4 || isempty (tag)
        tag = "unlabelled";
      endif
      this.tag = tag;
      this.prefix = prefix;
      this.arch_prefix = arch_prefix;
    endfunction

    function out = is_installed (this, pkgver)
      inst_dir = this.install_path_for_pkg (pkgver);
      out = isfolder (inst_dir);
    endfunction

    function out = install_paths_for_pkg (this, pkgver)
      ver = char (pkgver.version);
      name_ver = [pkgver.name "-" ver];
      out.dir = fullfile (this.prefix, name_ver);
      arch = packajoozle.internal.Util.get_system_arch;
      out.arch_dir = fullfile (this.arch_prefix, arch, name_ver);
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
        out{i} = sprintf(["InstallDir: %s\n" ...
          "Prefix:      %s\n" ...
          "Arch Prefix: %s"], ...
          this.tag, this.prefix, this.arch_prefix);
      endfor
    endfunction

    function out = get_package_list (this)
      pkg_list_file = fullfile (this.meta_dir, "octave_packages");
      out = load (pkg_list_file);
      out = out.(this.package_list_var_name);
    endfunction
    
    function record_installed_package (this, desc, target)
      pkg_list_file = fullfile (this.meta_dir, "octave_packages");
      desc.dir = target.dir;
      desc.archprefix = target.arch_dir;
      list = this.get_package_list;
      new_list = normalize_desc_save_order ([list desc]);
      s = struct (this.package_list_var_name, new_list);
      save (pkg_list_file, "-struct", "s");
    endfunction
  endmethods

endclassdef

function out = normalize_desc_save_order (descs)
  newdesc = {};
  for i = 1 : length (desc)
    deps = desc{i}.depends;
    if (isempty (deps)
        || (length (deps) == 1 && strcmp (deps{1}.package, "octave")))
      newdesc{end + 1} = desc{i};
    else
      tmpdesc = {};
      for k = 1 : length (deps)
        for j = 1 : length (desc)
          if (strcmp (desc{j}.name, deps{k}.package))
            tmpdesc{end+1} = desc{j};
            break;
          endif
        endfor
      endfor
      if (! isempty (tmpdesc))
        newdesc = {newdesc{:}, save_order(tmpdesc){:}, desc{i}};
      else
        newdesc{end+1} = desc{i};
      endif
    endif
  endfor

  ## Eliminate the duplicates.
  ## TODO: This currently ignores versions. When we add multi-version
  ## support, it should respect versions.
  idx = [];
  for i = 1 : length (newdesc)
    for j = (i + 1) : length (newdesc)
      if (strcmp (newdesc{i}.name, newdesc{j}.name))
        idx(end + 1) = j;
      endif
    endfor
  endfor
  newdesc(idx) = [];
endfunction

