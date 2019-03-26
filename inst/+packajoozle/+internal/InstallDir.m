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
## @deftypefn {Class Constructor} {obj =} InstallDir ()
##
## A local directory where pkg package installations reside.
##
## An InstallDir is a local filesystem directory hierarchy where pkg-installed
## packages reside.
##
## An InstallDir is actually multiple directories, including a base prefix,
## an arch-specific prefix, and maybe more.
##
## @end deftypefn

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

  properties (Dependent)
    pkg_list_file
  endproperties

  methods

    function this = InstallDir (meta_dir, prefix, arch_prefix, tag)
      if nargin == 0
        return
      endif
      narginchk (2, 4);
      if nargin < 3 || isempty (arch_prefix)
        arch_prefix = prefix;
      endif
      if nargin < 4 || isempty (tag)
        tag = "unlabelled";
      endif
      this.tag = tag;
      this.meta_dir = meta_dir;
      this.prefix = prefix;
      this.arch_prefix = arch_prefix;
    endfunction

    function out = get.pkg_list_file (this)
      out = fullfile (this.meta_dir, "octave_packages");
    endfunction
    
    function out = install_paths_for_pkg (this, pkgver)
      ver = char (pkgver.version);
      name_ver = [pkgver.name "-" ver];
      out.dir = fullfile (this.prefix, name_ver);
      arch = packajoozle.internal.Util.get_system_arch;
      out.arch_dir = fullfile (this.arch_prefix, arch, name_ver);
    endfunction

    function disp (this)
      disp (dispstr (this));
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
        t = this(i);
        out{i} = sprintf(["InstallDir: %s\n" ...
          "prefix:      %s\n" ...
          "arch_prefix: %s\n" ...
          "package_list_var_name: %s"], ...
          t.tag, t.prefix, t.arch_prefix, t.package_list_var_name);
      endfor
    endfunction

    function out = get_package_list_descs (this)
      # Gets list of instlled packages as "descs"
      out = this.get_package_list ("desc");
    endfunction

    function out = get_package_list (this, format = "pkgver")
      # Gets list of instlled packages
      if ! exist (this.pkg_list_file, "file")
        out = [];
        return
      endif
      # Now, for some reason, a 0-byte octave_packages file is appearing, and I don't
      # know what's writing it there. Octave, not Packajoozle, seems to be dropping
      # them. But regardless, it breaks load().
      if file_is_zero_bytes (this.pkg_list_file)
        out = [];
        return
      endif
      s = load (this.pkg_list_file);
      # Hack: take any field
      fields = fieldnames (s);
      if numel (fields) > 1
        error ("Multiple fields in package list file: %s", this.pkg_list_file);
      endif
      descs = s.(fields{1});
      # Convert to output format
      switch format
        case "desc"
          out = descs;
        case "pkgver"
          out = descs_to_pkgvers (descs);
        otherwise
          error ("InstallDir.get_package_list: Invalid format: '%s'", format);
      endswitch
    endfunction

    function out = get_installed_package_desc (this, pkgver)
      descs = this.get_package_list_descs;
      for i = 1:numel (descs)
        pkgver_i = packajoozle.internal.PkgVer (descs{i}.name, descs{i}.version);
        if pkgver_i == pkgver
          out = descs{i};
          return
        endif
      endfor
      error ("Installed package not found: %s", char (pkgver));
    endfunction

    function record_installed_package (this, desc, target)
      desc.dir = target.dir;
      desc.archprefix = target.arch_dir;
      list = this.get_package_list_descs;
      if isempty (list)
        new_list = {desc};
      else
        new_list = normalize_desc_save_order ([list {desc}]);
      endif
      this.save_pkg_list_to_file (new_list);
    endfunction

    function record_uninstalled_package (this, pkgver)
      list = this.get_package_list_descs;
      ix_to_delete = [];
      for i = 1:numel (list)
        ref = packajoozle.internal.PkgVer (list{i}.name, list{i}.version);
        if ref == pkgver
          ix_to_delete(end+1) = i;
        endif
      endfor
      if ! isempty (ix_to_delete)
        list(ix_to_delete) = [];
        this.save_pkg_list_to_file (list);
      endif
    endfunction

    function save_pkg_list_to_file (this, list)
      eval (sprintf ("%s = list;", this.package_list_var_name));
      packajoozle.internal.Util.mkdir (this.meta_dir);
      save (this.pkg_list_file, this.package_list_var_name);
    endfunction

    function out = is_installed (this, pkgver)
      pkgver = makeItBeA (pkgver, "packajoozle.internal.PkgVer");
      mustBeScalar (pkgver);
      installed = this.get_package_list;
      out = ismember (pkgver, installed);
    endfunction
    
    function out = list_packages_matching (this, pkgreqs)
      all_pkgs = this.get_package_list ("pkgver");
      tf = false (size (all_pkgs));
      for i = 1:numel (pkgreqs)
        tf = tf | pkgreqs(i).matches (all_pkgs);
      endfor
      out = all_pkgs(tf);
    endfunction
    
    function out = loaded_packages (this)
      installed = this.get_package_list_descs;
      out = installed(this.isloaded_installed);
    endfunction

    function out = is_loaded (this, pkgvers)
      pkgvers = makeItBeA (pkgvers, "packajoozle.internal.PkgVer");
      load_path = strsplit (path, pathsep);
      out = false (size (pkgvers));
      for i = 1:numel (pkgvers)
        if ! this.is_installed (pkgvers(i))
          continue
        endif
        desc = this.get_installed_package_desc (pkgvers(i));
        out(i) = any (ismember ({desc.dir desc.darchprefix}, load_path));
      endfor
    endfunction

    function unload_packages (this, pkgvers)
      pkgvers = makeItBeA (pkgvers, "packajoozle.internal.PkgVer");
      objfun (@(x) this.unload_package (x), pkgvers);
    endfunction

    function out = unload_package (this, pkgver)
      out.status = true;
      out.message = [];
      pkgver = makeItBeA (pkgver, "packajoozle.internal.PkgVer");
      mustBeScalar (pkgver);
      if this.isloaded (pkgver)
        desc = this.get_installed_package_desc (pkgver);
        for the_dir = {desc.dir desc.archprefix}
          the_dir = the_dir{1};
          if is_on_octave_load_path (the_dir)
            # try/catch because PKG_DEL might misbehave
            try
              rmpath (the_dir);
            catch err
              error ("pkj: failed unloading package %s from %s: %s", ...
                char (pkgver), the_dir, err.message);
            end_try_catch
          endif
        endfor
      endif
    endfunction

  endmethods

endclassdef

function out = is_on_octave_load_path (dir)
  out = ismember (strsplit (path, pathsep));
endfunction

function out = descs_to_pkgvers (descs)
  c = cell (size (descs));
  for i = 1:numel (descs)
    c{i} = packajoozle.internal.PkgVer (descs{i}.name, descs{i}.version);
  endfor
  out = objvcat (c{:});
endfunction

function out = normalize_desc_save_order (descs)
  newdesc = {};
  for i = 1 : length (descs)
    desc = descs{i};
    deps = desc.depends;
    if (isempty (deps)
        || (length (deps) == 1 && strcmp (deps{1}.package, "octave")))
      newdesc{end + 1} = desc;
    else
      tmpdesc = {};
      for k = 1 : length (deps)
        for j = 1 : length (descs)
          if (strcmp (descs{j}.name, deps{k}.package))
            tmpdesc{end+1} = descs{j};
            break;
          endif
        endfor
      endfor
      if (! isempty (tmpdesc))
        newdesc = {newdesc{:}, normalize_desc_save_order(tmpdesc){:}, desc};
      else
        newdesc{end+1} = desc;
      endif
    endif
  endfor

  ## Eliminate the duplicates.
  idx = [];
  for i = 1 : length (newdesc)
    for j = (i + 1) : length (newdesc)
      if isequal (packajoozle.internal.PkgVer (newdesc{i}.name, newdesc{i}.version), ...
        packajoozle.internal.PkgVer (newdesc{j}.name, newdesc{j}.version))
        idx(end + 1) = j;
      endif
    endfor
  endfor
  newdesc(idx) = [];

  out = newdesc;
endfunction

function out = file_is_zero_bytes (file)
  st = stat (file);
  out = st.blocks == 0;
endfunction

