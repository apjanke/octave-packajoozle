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
## @deftypefn {Class Constructor} {obj =} PkgManager ()
##
## Main package management object.
##
## All the top-level package management interaction logic goes in this class.
##
## @end deftypefn

% The implementation code here was grabbed from the "default" development
% branch for Octave 6.0 as of changeset 26929:3e6aa7c7bbbb on March 16,
% 2019. It may not be compatible with other versions of Octave.

classdef PkgManager

  properties
    forge = packajoozle.internal.OctaveForgeClient
    world = packajoozle.internal.InstallWorld.shared
    verbose = false
  endproperties

  methods (Static)
    function out = parse_forge_target (str)
      ix = regexp (str, '^[\w-]+$');
      if ! isempty (ix)
        out = packajoozle.internal.PkgVerReq (str);
        return
      endif
      ix = find (str == '@');
      if ! isempty (ix)
        if numel (ix) > 1
          error ("parse_forge_target: Too many @s in target: '%s'\n", str);
        endif
        pkg_name = str(1:ix-1);
        ver_filter_str = str(ix+1:end);
        ver_filter = packajoozle.internal.VerFilter.parse_ver_filter (ver_filter_str);
        out = packajoozle.internal.PkgVerReq (pkg_name, ver_filter);
        return
      endif
      error ("parse_forge_target: Invalid forge target string: '%s'\n", str);
    endfunction
  endmethods

  methods

    function this = PkgManager ()
      if nargin == 0
        return
      endif
    endfunction

    function out = default_installdir_tag (this)
      out = this.world.default_install_place;
    endfunction
    
    function out = resolve_installdir (this, inst_dir)
      if isempty (inst_dir)
        inst_dir = this.default_installdir_tag;
      endif
      if ischar (inst_dir)
        out = this.world.get_installdir_by_tag (inst_dir);
      else
        mustBeA (inst_dir, "packajoozle.internal.InstallPlace");
        out = inst_dir;
      endif
    endfunction

    function out = install_forge_pkgs_devel (this, pkgreqs, inst_dir, opts)
      % This is a separate method because we can't represent a devel/head
      % package with a Version object.
      if nargin < 3; inst_dir = []; endif
      if nargin < 4 || isempty (opts); opts = struct; endif
      opts = packajoozle.internal.Util.parse_options (opts, ...
        struct ("nodeps", false));
      inst_dir = this.resolve_installdir (inst_dir);

      # Ignore the versions in pkgreqs
      pkg_names = arrayfun (@(x) {x.package}, pkgreqs);
      tmp_dir = tempname (tempdir, "packajoozle/forge-devel-install/work-");
      repos_tmp_dir = fullfile (tmp_dir, "repos");
      tarballs_tmp_dir = fullfile (tmp_dir, "dist-tarballs");
      packajoozle.internal.Util.mkdir (repos_tmp_dir);
      packajoozle.internal.Util.mkdir (tarballs_tmp_dir);
      RAII.tmpdir = onCleanup (@() packajoozle.internal.Util.rm_rf (tmp_dir));

      # TODO: Resolve dependencies

      dist_files = {};
      for i = 1:numel (pkg_names)
        pkg_name = pkg_names{i};
        meta = this.forge.get_package_meta (pkg_name);
        clone_basename = meta.suggested_repo_local_name;
        local_repo_dir = fullfile (repos_tmp_dir, clone_basename);
        switch meta.repo_type
          case "hg"
            sc_opts = "";
          case "git"
            % This is failing, e.g. for doctest repo:
            %  error: Ambiguous option: shallow (could be --shallow-exclude or --shallow-submodules)
            %sc_opts = "--shallow";
            sc_opts = "";
          otherwise
            error ("PkgManager.install_forge_pkgs_devel: unsupported source control type: %s", ...
              meta.repo_type);
        endswitch
        clone_cmd = sprintf ("%s clone %s '%s' '%s'", ...
          meta.repo_type, sc_opts, meta.repo_url, local_repo_dir);
        packajoozle.internal.Util.system (clone_cmd);
        tar_file = fullfile (tarballs_tmp_dir, [pkg_name "-devel.tar"]);
        tgz_file = [tar_file ".gz"];
        orig_pwd = pwd;
        unwind_protect
          cd (repos_tmp_dir);
          tar (tar_file, clone_basename);
        unwind_protect_cleanup
          cd (orig_pwd);
        end_unwind_protect
        gzip (tar_file);
        dist_files{end+1} = tgz_file;
      endfor

      for i = 1:numel (dist_files)
        rslt = this.install_pkg_from_file_impl (dist_files{i}, inst_dir);
        if rslt.success
          printf ("Installed %s (DEVEL) from Octave Forge to %s pkg dir\n", ...
            char (rslt.pkgver), inst_dir.tag);
          this.display_user_messages (rslt);
        else
          printf ("Installation of %s (DEVEL) from Octave Forge failed: %s\n", ...
            pkg_names{i}, rslt.error_message);
        endif
        out{i} = rslt;
      endfor
      out = [out{:}];
    endfunction

    function out = install_forge_pkgs (this, pkgreqs, inst_dir, opts)
      if nargin < 3; inst_dir = []; endif
      if nargin < 4 || isempty (opts); opts = struct; endif
      opts = packajoozle.internal.Util.parse_options (opts, ...
        struct ("nodeps", false, ...
          "devel", false));

      inst_dir = this.resolve_installdir (inst_dir);

      # Resolve requests
      c = cell (size (pkgreqs));
      for i = 1:numel (pkgreqs)
        # For now, just install the latest version of each one
        req = pkgreqs(i);
        c{i} = this.forge.resolve_latest_version (req);
      endfor
      pkgvers = objvcat (c{:});

      # Resolve dependencies
      # Consider all packages to be installed

      if opts.nodeps
        # TODO: Maybe reorder these in dependency order
        need_installed = pkgvers;
      else
        dr = packajoozle.internal.DependencyResolver (this.forge);
        res = dr.resolve_deps (pkgvers);
        if ! res.ok
          error ("pkj: unsatisfiable dependencies: %s\n", strjoin (res.error_msgs));
        endif
        need_installed = res.resolved;
        if ! isempty (res.added_deps)
          printf ("pkj: picked up dependencies: %s\n", ...
            strjoin (dispstrs (res.added_deps), ", "));
        endif
      endif

      # Install selected packages
      tf_installed = this.world.is_installed (need_installed);
      to_install = need_installed(~tf_installed);
      printf ("pkj: installing: %s\n", strjoin (dispstrs (to_install), ", "));
      rslts = {};
      for i = 1:numel (to_install)
        pkgver = to_install(i);
        rslts{i} = this.install_forge_pkg_single (pkgver);
      endfor
      out = [rslts{:}];
    endfunction

    function out = install_file_pkgs (this, files, inst_dir)
      if nargin < 3; inst_dir = []; endif
      inst_dir = this.resolve_installdir (inst_dir);

      # TODO: Resolve dependencies
      # Consider all packages to be installed

      rslts = {};
      for i = 1:numel (files)
        file = files{i};
        rslts{i} = this.install_pkg_from_file (file, inst_dir);
      endfor
      out = [rslts{:}];
    endfunction

    function display_user_messages (this, rslt)
      for i = 1:numel (rslt.user_messages)
        printf ("%s\n", rslt.user_messages{i});
      endfor
    endfunction

    function out = install_forge_pkg_single (this, pkgver, inst_dir)
      if nargin < 3; inst_dir = []; endif
      inst_dir = this.resolve_installdir (inst_dir);
      mustBeA (pkgver, "packajoozle.internal.PkgVer");
      
      dist_tgz = this.forge.download_cached_pkg_distribution (pkgver);
      out = this.install_pkg_from_file_impl (dist_tgz);

      if out.success
        printf ("Installed %s from Octave Forge to %s pkg dir\n", ...
          char (pkgver), inst_dir.tag);
        this.display_user_messages (out);
      else
        printf ("Installation of %s from Octave Forge failed: %s\n", ...
          char (pkgver), out.error_message);
      endif
    endfunction

    function out = install_pkg_from_file (this, file, inst_dir)
      if nargin < 3; inst_dir = []; endif
      inst_dir = this.resolve_installdir (inst_dir);
      rslt = this.install_pkg_from_file_impl (file, inst_dir);
      printf ("Installed %s from %s to %s pkg dir\n", ...
        char (rslt.pkgver), file, inst_dir.tag);
      this.display_user_messages (rslt);
      out = rslt;
    endfunction

    function out = install_pkg_from_file_impl (this, file, inst_dir)
      if nargin < 3; inst_dir = []; endif
      inst_dir = this.resolve_installdir (inst_dir);

      # Remove existing installation of same pkg/ver
      info = packajoozle.internal.PkgDistUtil.get_pkg_description_from_pkg_archive_file (file);
      pkgver = packajoozle.internal.PkgVer (info.name, info.version);
      out.pkgver = pkgver;
      if inst_dir.is_installed (pkgver)
        error ("pkj: already installed: %s\n", char (pkgver));
      endif

      build_dir_parent = tempname (tempdir, ["packajoozle/packajoozle-build-" ...
        pkgver.name "-"]);
      packajoozle.internal.Util.mkdir (build_dir_parent);
      #RAII.build_dir_parent = onCleanup (@() rm_rf_safe (build_dir_parent));
      say("build temp dir: %s", build_dir_parent);
      files = unpack (file, build_dir_parent);
      kids = packajoozle.internal.Util.readdir (build_dir_parent);
      if numel (kids) > 1
        error ("pkj: bundles of packages are not allowed. bad file: %s\n", file);
      endif
      build_dir = fullfile (build_dir_parent, kids{1});

      # Inspect the package

      target = inst_dir.install_paths_for_pkg (pkgver);
      verify_directory (build_dir);
      desc_file = fullfile (build_dir, "DESCRIPTION");
      orig_desc = packajoozle.internal.PkgDistUtil.parse_pkg_description_file (desc_file);
      desc = orig_desc;
      # For back-compatibility with old pkg code
      desc.dir = target.dir;
      desc.archprefix = target.arch_dir;
      this.require_deps_installed_from_desc (desc);

      # Build the package

      prepare_installation (desc, build_dir);
      rslt = configure_make (desc, build_dir, this.verbose);
      out.success = true;
      out.error_message = [];
      out.log_dir = rslt.log_dir;
      out.user_messages = {};
      if ! rslt.success
        out.success = false;
        out.error_message = rslt.error_message;
        out.exception = rslt.exception;
        return
      endif
      copy_built_files (desc, build_dir, this.verbose);

      # TODO: Remove existing installation of same package down here

      # Install the built package

      packajoozle.internal.Util.mkdir (target.dir);
      packajoozle.internal.Util.mkdir (target.arch_dir);
      copy_files_from_build_to_inst (desc, target, build_dir);
      create_pkgadddel (desc, build_dir, "PKG_ADD", target);
      create_pkgadddel (desc, build_dir, "PKG_DEL", target);
      finish_installation (desc, build_dir, target);
      try
        generate_lookfor_cache (desc, target);
      catch err
        warning ("pkj: failed creating lookfor cache for %s: %s\n", ...
          desc.name, err.message);
      end_try_catch

      # Validate the installation

      if dirempty (target.dir, {"packinfo", "doc"}) ...
        && dirempty (target.arch_dir)
        warning ("empty package installation: %s\n", desc.name);
        rm_rf_safe (target.arch_dir);
        rm_rf_safe (target.dir);
        out.success = false;
        out.error_message = sprintf ("empty package installation: %s", desc.name);
        return
      endif

      # Save package metadata to installdir indexes

      try
        inst_dir.record_installed_package (desc, target);
      catch err
        rm_rf_safe (target.arch_dir);
        rm_rf_safe (target.dir);
        out.success = false;
        out.error_message = sprintf ("failed recording package in package list: %s", err.message);        
        fprintf ("pkj: Failed updating package index file: %s", err.message);
        return
      end_try_catch

      # Pick up user notifications

      news_file = fullfile (target.dir, "packinfo", "NEWS");
      if packajoozle.internal.Util.isfile (news_file)
        msg = sprintf (["For information about changes from previous versions " ...
                 "of the %s package, run 'news %s'."],
                desc.name, desc.name);
        out.user_messages{end+1} = msg;
      endif        

    endfunction

    function require_deps_installed_from_desc (this, desc)
      bad_deps = this.get_unsatisfied_deps_from_desc (desc);
      if ! isempty (bad_deps)
        error ("pkj: unsatisified dependencies: %s\n", ...
          strjoin (dispstrs (bad_deps), ", "));
      endif
    endfunction

    function out = get_unsatisfied_deps_from_desc (this, desc)
      bad_deps = {};
      installed = this.world.list_installed_packages;
      for i = 1:numel (desc.depends)
        dep = desc.depends{i};
        dep_req = packajoozle.internal.PkgVerReq (dep.package, ...
          packajoozle.internal.VerFilter (dep.version, dep.operator));
        if isequal (dep.package, "octave")
          if (! compare_versions (OCTAVE_VERSION, dep.version, dep.operator))
            bad_deps{end+1} = dep_req;
          endif
        else
          if isempty (installed) || ! any (dep_req.matches (installed))
            bad_deps{end+1} = dep_req;
          endif
        endif
      endfor
      out = objvcat (bad_deps{:});
    endfunction

    function uninstall_all_versions (this, pkg_name)
      error ("PkgManager.uninstall_all_versions: this is not yet implemented")
    endfunction

    function uninstall_packages (this, pkgreqs, inst_dir)
      if nargin < 3; inst_dir = []; endif
      inst_dir = this.resolve_installdir (inst_dir);

      # Find packages to uninstall
      pkgvers = inst_dir.list_packages_matching (pkgreqs);
      printf ("pkj: uninstalling: %s\n", strjoin (dispstrs (pkgvers), ", "));
      this.world.unload_packages (pkgvers);
      #TODO: Check that dependencies will still be satisfied after uninstallation

      # TODO: Check dependencies
      # Calculate remaining installed packages and see that their deps are still
      # satisfied

      # Uninstall the packages if we're clear to proceed
      for i = 1:numel (pkgvers)
        this.uninstall_one_package (pkgvers(i), inst_dir);
      endfor
      printf ("pkj: packages uninstalled\n");
    endfunction

    function uninstall_one_package (this, pkgver, inst_dir)
      %UNINSTALL_ONE Uninstall a package
      if nargin < 3; inst_dir = []; endif
      inst_dir = this.resolve_installdir (inst_dir);

      mustBeA (pkgver, "packajoozle.internal.PkgVer");
      mustBeScalar (pkgver);

      found = false;
      if ! inst_dir.is_installed (pkgver)
        error ("pkj: package %s is not installed\n", char (pkgver));
      endif
      
      #TODO: Get desc for installed package
      target = inst_dir.install_paths_for_pkg (pkgver);

      # Run pre-uninstall hooks
      if packajoozle.internal.Util.isfile (fullfile (target.dir, "packinfo", "on_uninstall.m"))
        orig_pwd = pwd;
        try
          cd (fullfile (target.dir, "packinfo"));
          on_uninstall (desc);
          cd (orig_pwd);
        catch err
          cd (orig_pwd);
          error ("pkj: error while running on_uninstall hook for %s: %s\n", ...
            char (pkgver), err.message);
        end_try_catch
      endif

      # Delete package installation directories
      if ! myisfolder (target.dir)
        warning ("pkj: directory %s previously lost; marking %s as uninstalled\n", ...
         target.dir, char (pkgver));
      endif
      packajoozle.internal.Util.rm_rf (target.arch_dir);
      packajoozle.internal.Util.rm_rf (target.dir);

      # Update package index
      inst_dir.record_uninstalled_package (pkgver);

    endfunction
    
    function out = load_packages (this, pkgver)
      # Resolve dependencies
      dr = packajoozle.internal.DependencyResolver (this.world);
      res = dr.resolve_deps (pkgver);
      if ! res.ok
        warning ("pkj: some dependencies are unmet: %s\n", ...
          strjoin (res.error_msgs, "; "));
      endif

      # Load packages and dependencies
      printf ("pkj: loading: %s\n", strjoin (dispstrs (res.resolved), ", "));
      for i = 1:numel (res.resolved)
        this.load_package (res.resolved(i));
      endfor
    endfunction

    function out = load_package (this, pkgver)
      inst_dirs = this.world.get_all_installdirs;
      for i = 1:numel (inst_dirs)
        inst_dir = inst_dirs(i);
        if inst_dir.is_installed (pkgver)
          inst_dir.load_package (pkgver);
          return
        endif
      endfor
      error ("pkj: package not installed: %s\n", char (pkgver));
    endfunction

    function rmpath_safe (this, varargin)
      % We have to do this because PKG_DEL might raise errors
      try
        rmpath (varargin{});
      catch err
        warning (["pkj: error (probably from PKG_DEL) when removing directory from path:\n" ...
          "  Dir: %s\n" ...
          "  Error: %s\n"], ...
          strjoin (varargin, ", "), err.message);
      end_try_catch
    endfunction

    function out = unload_packages (this, pkgreqs)
      descs = this.world.list_installed_packages ("desc");
      # TODO: Pick packages and then sort in reverse dependency order
      out = {};
      for i_req = 1:numel (pkgreqs)
        pkgreq = pkgreqs(i_req);
        for i_desc = 1:numel (descs)
          desc = descs{i_desc};
          pkgver = packajoozle.internal.PkgVer (desc.name, desc.version);
          if pkgreq.matches (pkgver)
            [is_loaded, dirs_on_path] = is_pkg_loaded_by_desc (desc);
            if is_loaded
              this.rmpath_safe (dirs_on_path{:});
              out{end+1} = pkgver;
            endif
          endif
        endfor
      endfor
      out = objvcat (out{:});
    endfunction

  endmethods

endclassdef


function [out, pkg_dirs_on_path] = is_pkg_loaded_by_desc (desc)
  dirs = {desc.dir};
  if ! isempty (desc.archprefix)
    dirs{end+1} = desc.archprefix;
  endif
  dirs_on_path = strsplit (path, pathsep);
  tf = ismember (dirs, dirs_on_path);
  out = any (tf);
  pkg_dirs_on_path = unique(dirs(tf));
endfunction

function say (varargin)
  fprintf ("%s: %s\n", "pkj", sprintf (varargin{:}));
  packajoozle.internal.Util.flush_diary
endfunction

function out = chomp (str)
  out = regexprep (str, "\r?\n$", "");
endfunction

function rm_rf_safe (path)
  try
    packajoozle.internal.Util.rm_rf (path);
  catch err
    warning ("pkj: failed deleting directory: %s", err.message);
  end_try_catch
endfunction


% ======================================================
% My special functions


% ======================================================
%
% Functions copied from Octave's pkg/private/install.m


function pkg = extract_pkg (nm, pat)

  fid = fopen (nm, "rt");
  pkg = "";
  if (fid >= 0)
    while (! feof (fid))
      ln = fgetl (fid);
      if (ln > 0)
        t = regexp (ln, pat, "tokens");
        if (! isempty (t))
          pkg = [pkg "\n" t{1}{1}];
        endif
      endif
    endwhile
    if (! isempty (pkg))
      pkg = [pkg "\n"];
    endif
    fclose (fid);
  endif

endfunction


## Make sure the package contains the essential files.
function verify_directory (dir)

  needed_files = {"COPYING", "DESCRIPTION"};
  for f = needed_files
    if (! packajoozle.internal.Util.isfile (fullfile (dir, f{1})))
      error ("pkj: package is missing file: %s\n", f{1});
    endif
  endfor

endfunction


function prepare_installation (desc, build_dir)

  ## Is there a pre_install to call?
  if (packajoozle.internal.Util.isfile (fullfile (build_dir, "pre_install.m")))
    wd = pwd ();
    try
      cd (build_dir);
      pre_install (desc);
      cd (wd);
    catch
      cd (wd);
      rethrow (lasterror ());
    end_try_catch
  endif

  ## If the directory "inst" doesn't exist, we create it.
  inst_dir = fullfile (build_dir, "inst");
  if (! myisfolder (inst_dir))
    [status, msg] = mkdir (inst_dir);
    if (status != 1)
      packajoozle.internal.Util.rm_rf (desc.dir);
      error ("pkj: the 'inst' directory did not exist and could not be created: %s\n",
             msg);
    endif
  endif

endfunction


function copy_built_files (desc, build_dir, verbose)
  % Copies built files from src/ to inst/ within a build dir

  src = fullfile (build_dir, "src");
  if (! myisfolder (src))
    return
  endif

  ## Copy files to "inst" and "inst/arch" (this is instead of 'make install').
  files = fullfile (src, "FILES");
  instdir = fullfile (build_dir, "inst");
  archdir = fullfile (build_dir, "inst", packajoozle.internal.Util.get_system_arch ());

  ## Get filenames.
  if (packajoozle.internal.Util.isfile (files))
    filenames = chomp (fileread (files));
    filenames = strtrim (ostrsplit (filenames, "\n"));
    delete_idx = [];
    for i = 1:length (filenames)
      if (! all (isspace (filenames{i})))
        filenames{i} = fullfile (src, filenames{i});
      else
        delete_idx(end+1) = i;
      endif
    endfor
    filenames(delete_idx) = [];
  else
    m = dir (fullfile (src, "*.m"));
    oct = dir (fullfile (src, "*.oct"));
    mex = dir (fullfile (src, "*.mex"));

    filenames = cellfun (@(x) fullfile (src, x),
                         {m.name, oct.name, mex.name},
                         "uniformoutput", false);
  endif

  ## Split into architecture dependent and independent files.
  if (isempty (filenames))
    idx = [];
  else
    idx = cellfun ("is_architecture_dependent", filenames);
  endif
  archdependent = filenames(idx);
  archindependent = filenames(! idx);

  ## Copy the files.
  if (! all (isspace ([filenames{:}])))
      if (! myisfolder (instdir))
        mkdir (instdir);
      endif
      if (! all (isspace ([archindependent{:}])))
        if (verbose)
          printf ("copyfile");
          printf (" %s", archindependent{:});
          printf ("%s\n", instdir);
        endif
        [status, output] = copyfile (archindependent, instdir);
        if (status != 1)
          packajoozle.internal.Util.rm_rf (desc.dir);
          error ("pkj: couldn't copy files from 'src' to 'inst': %s\n", output);
        endif
      endif
      if (! all (isspace ([archdependent{:}])))
        if (verbose)
          printf ("copyfile");
          printf (" %s", archdependent{:});
          printf (" %s\n", archdir);
        endif
        if (! myisfolder (archdir))
          mkdir (archdir);
        endif
        [status, output] = copyfile (archdependent, archdir);
        if (status != 1)
          packajoozle.internal.Util.rm_rf (desc.dir);
          error ("pkj: couldn't copy files from 'src' to 'inst': %s\n", output);
        endif
      endif
  endif

endfunction


function dep = is_architecture_dependent (file)
  persistent archdepsuffix = {".oct",".mex",".a",".lib",".so",".so.*",".dll","dylib"};

  dep = false;
  for i = 1 : length (archdepsuffix)
    ext = archdepsuffix{i};
    if (ext(end) == "*")
      isglob = true;
      ext(end) = [];
    else
      isglob = false;
    endif
    pos = strfind (file, ext);
    if (pos)
      if (! isglob && (length (file) - pos(end) != length (ext) - 1))
        continue;
      endif
      dep = true;
      break;
    endif
  endfor

endfunction


function out = getarch ()
  out = packajoozle.internal.Util.get_system_arch;
endfunction

function copy_files_from_build_to_inst (desc, target, build_dir)
  % Copy built files from the build dir (build_dir) to the final install_dir

  install_dir = target.dir;
  octfiledir = target.arch_dir;

  packajoozle.internal.Util.mkdir (install_dir);

  ## Copy the files from "inst" to installdir.
  instdir = fullfile (build_dir, "inst");
  if (! dirempty (instdir))
    [status, output] = copyfile (fullfile (instdir, "*"), desc.dir);
    if (status != 1)
      packajoozle.internal.Util.rm_rf (desc.dir);
      error ("pkj: couldn't copy files to the installation directory '%s': %s\n", ...
        desc.dir, output);
    endif
    if (myisfolder (fullfile (desc.dir, getarch ()))
        && ! strcmp (canonicalize_file_name (fullfile (desc.dir, getarch ())),
                     canonicalize_file_name (octfiledir)))
      packajoozle.internal.Util.mkdir (octfiledir)
      [ok, output] = movefile (fullfile (desc.dir, getarch (), "*"), octfiledir);
      packajoozle.internal.Util.rm_rf (fullfile (desc.dir, getarch ()));
      if ! ok
        packajoozle.internal.Util.rm_rf (desc.dir);
        packajoozle.internal.Util.rm_rf (octfiledir);
        error ("pkj: couldn't copy files to the installation oct-file directory '%s': %s\n", ...
          octfiledir, desc.dir);
      endif
    endif

  endif

  ## Create the "packinfo" directory.
  packinfo_dir = fullfile (desc.dir, "packinfo");
  packajoozle.internal.Util.mkdir (packinfo_dir);

  packinfo_copy_file ("DESCRIPTION", "required", build_dir, packinfo_dir);
  packinfo_copy_file ("COPYING", "required", build_dir, packinfo_dir);
  packinfo_copy_file ("CITATION", "optional", build_dir, packinfo_dir);
  packinfo_copy_file ("NEWS", "optional", build_dir, packinfo_dir);
  packinfo_copy_file ("ONEWS", "optional", build_dir, packinfo_dir);
  packinfo_copy_file ("ChangeLog", "optional", build_dir, packinfo_dir);

  ## Is there an INDEX file to copy or should we generate one?
  index_file = fullfile (build_dir, "INDEX");
  if (packajoozle.internal.Util.isfile (index_file))
    packinfo_copy_file ("INDEX", "required", build_dir, packinfo_dir);
  else
    generate_index (desc, fullfile (build_dir, "inst"), fullfile (packinfo_dir, "INDEX"));
  endif

  ## Is there an 'on_uninstall.m' to install?
  packinfo_copy_file ("on_uninstall.m", "optional", build_dir, packinfo_dir);

  ## Is there a doc/ directory that needs to be installed?
  docdir = fullfile (build_dir, "doc");
  if (myisfolder (docdir) && ! dirempty (docdir))
    [status, output] = copyfile (docdir, desc.dir);
  endif

  ## Is there a bin/ directory that needs to be installed?
  ## FIXME: Need to treat architecture dependent files in bin/
  bindir = fullfile (build_dir, "bin");
  if (myisfolder (bindir) && ! dirempty (bindir))
    [status, output] = copyfile (bindir, desc.dir);
  endif

endfunction


function packinfo_copy_file (filename, requirement, build_dir, packinfo_dir)

  filepath = fullfile (build_dir, filename);
  if (! packajoozle.internal.Util.isfile (filepath) && strcmpi (requirement, "optional"))
    ## do nothing, it's still OK
  else
    packajoozle.internal.Util.copyfile (filepath, packinfo_dir);
  endif

endfunction


## Create an INDEX file for a package that doesn't provide one.
##   'desc'  describes the package.
##   'dir'   is the 'inst' directory in temporary directory.
##   'index_file' is the name (including path) of resulting INDEX file.
function generate_index (desc, dir, index_file)

  ## Get names of functions in dir
  files = packajoozle.internal.Util.readdir (dir);

  ## Get classes in dir
  class_idx = find (strncmp (files, '@', 1));
  for k = 1:length (class_idx)
    class_name = files {class_idx(k)};
    class_dir = fullfile (dir, class_name);
    if (myisfolder (class_dir))
      files2 = packajoozle.internal.Util.readdir (class_dir);
      files2 = strcat (class_name, filesep (), files2);
      files = [files; files2];
    endif
  endfor

  ## Check for architecture dependent files.
  arch_dir = desc.archprefix;
  if (myisfolder (arch_dir))
    files2 = packajoozle.internal.Util.readdir (arch_dir);
    files = [files; files2];
  endif

  fcns = {};
  for i = 1:length (files)
    file = files{i};
    lf = length (file);
    if (lf > 2 && strcmp (file(end-1:end), ".m"))
      fcns{end+1} = file(1:end-2);
    elseif (lf > 4 && strcmp (file(end-3:end), ".oct"))
      fcns{end+1} = file(1:end-4);
    endif
  endfor

  ## Does desc have a categories field?
  if (! isfield (desc, "categories"))
    error ("pkj: the DESCRIPTION file must have a Categories field, when no INDEX file is given: %s\n", dir);
  endif
  categories = strtrim (strsplit (desc.categories, ","));
  if (length (categories) < 1)
    error ("pkj: the Category field in DESCRIPTION is empty: %s\n", dir);
  endif

  ## Write INDEX.
  fid = packajoozle.internal.Util.fopen (index_file, "w");
  fprintf (fid, "%s >> %s\n", desc.name, desc.title);
  fprintf (fid, "%s\n", categories{1});
  fprintf (fid, "  %s\n", fcns{:});
  fclose (fid);

endfunction


function create_pkgadddel (desc, build_dir, nm, target)

  inst_dir = target.dir;
  instpkg = fullfile (inst_dir, nm);
  instfid = fopen (instpkg, "at"); # append to support PKG_ADD at inst/
  ## If it exists, most of the PKG_* file should go into the
  ## architecture dependent directory so that the autoload/mfilename
  ## commands work as expected.  The only part that doesn't is the
  ## part in the main directory.
  archdir = target.arch_dir;
  if myisfolder (archdir) && ! isequal (inst_dir, archdir)
    archpkg = fullfile (archdir, nm);
    archfid = fopen (archpkg, "at");
  else
    archpkg = instpkg;
    archfid = instfid;
  endif

  if (archfid >= 0 && instfid >= 0)
    ## Search all dot-m files for PKG commands.
    lst = glob (fullfile (build_dir, "inst", "*.m"));
    for i = 1:length (lst)
      nam = lst{i};
      fwrite (instfid, extract_pkg (nam, ['^[#%][#%]* *' nm ': *(.*)$']));
    endfor

    ## Search all C++ source files for PKG commands.
    cc_lst = glob (fullfile (build_dir, "src", "*.cc"));
    cpp_lst = glob (fullfile (build_dir, "src", "*.cpp"));
    cxx_lst = glob (fullfile (build_dir, "src", "*.cxx"));
    lst = [cc_lst; cpp_lst; cxx_lst];
    for i = 1:length (lst)
      nam = lst{i};
      fwrite (archfid, extract_pkg (nam, ['^//* *' nm ': *(.*)$']));
      fwrite (archfid, extract_pkg (nam, ['^/\** *' nm ': *(.*) *\*/$']));
    endfor

    ## Add developer included PKG commands.
    build_dirnm = fullfile (build_dir, nm);
    if (packajoozle.internal.Util.isfile (build_dirnm))
      fid = fopen (build_dirnm, "rt");
      if (fid >= 0)
        while (! feof (fid))
          ln = fgets (fid);
          if (ln > 0)
            fwrite (archfid, ln);
          endif
        endwhile
        fclose (fid);
      endif
    endif

    ## If the files is empty remove it.
    fclose (instfid);
    t = dir (instpkg);
    if (t.bytes <= 0)
      unlink (instpkg);
    endif

    if (instfid != archfid)
      fclose (archfid);
      t = dir (archpkg);
      if (t.bytes <= 0)
        unlink (archpkg);
      endif
    endif
  endif

endfunction


function finish_installation (desc, build_dir, target)
  narginchk (3, 3);

  ## Is there a post-install to call?
  if (packajoozle.internal.Util.isfile (fullfile (build_dir, "post_install.m")))
    orig_pwd = pwd ();
    try
      cd (build_dir);
      # Pack input in form expected by post_install (based on pkg's behavior)
      desc2.dir = target.dir;
      desc2.archprefix = fileparts (target.arch_dir);
      post_install (desc);
      cd (orig_pwd);
    catch err
      cd (orig_pwd);
      rm_rf_safe (target.dir, "s");
      rm_rf_safe (target.arch_dir, "s");
      rethrow (err);
    end_try_catch
  endif

endfunction


function generate_lookfor_cache (desc, target)
  dirs = strtrim (ostrsplit (genpath (target.dir), pathsep ()));
  for i = 1 : length (dirs)
    doc_cache_create (fullfile (dirs{i}, "doc-cache"), dirs{i});
  endfor
endfunction

% ======================================================
%
% Other functions copied and adapted from Octave's pkg/private

function out = configure_make (desc, build_dir, verbose)
  % Returns struct with fields:
  %  success (boolean)
  %  log_dir (char)
  %  error_message (char)
  %  exception (MException or [])
  %
  % log_dir will still be populated and valid even if success is false.

  timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
  log_dir = fullfile (packajoozle.internal.Util.xdg_octave_cache_dir, ...
    "packajoozle", "build-logs", ["packajoozle-build-" desc.name "-" timestamp]);
  packajoozle.internal.Util.mkdir (log_dir);
  out.log_dir = log_dir;
  out.success = true;
  out.error_message = '';
  out.exception = [];
  
  ## Perform ./configure, make, make install in "src".
  if (myisfolder (fullfile (build_dir, "src")))
    src = fullfile (build_dir, "src");
    octave_bindir = __octave_config_info__ ("bindir");
    ver = version ();
    ext = __octave_config_info__ ("EXEEXT");
    mkoctfile_program = fullfile (octave_bindir, ...
                                  sprintf ("mkoctfile-%s%s", ver, ext));
    octave_config_program = fullfile (octave_bindir, ...
                                      sprintf ("octave-config-%s%s", ver, ext));
    if (ispc () && ! isunix ())
      octave_binary = fullfile (octave_bindir, sprintf ("octave-%s.bat", ver));
    else
      octave_binary = fullfile (octave_bindir, sprintf ("octave-%s%s", ver, ext));
    endif

    if (! packajoozle.internal.Util.isfile (mkoctfile_program))
      __gripe_missing_component__ ("pkg", "mkoctfile");
    endif
    if (! packajoozle.internal.Util.isfile (octave_config_program))
      __gripe_missing_component__ ("pkg", "octave-config");
    endif
    if (! packajoozle.internal.Util.isfile (octave_binary))
      __gripe_missing_component__ ("pkg", "octave");
    endif

    if (verbose)
      mkoctfile_program = [mkoctfile_program " --verbose"];
    endif

    cenv = {"MKOCTFILE"; mkoctfile_program;
            "OCTAVE_CONFIG"; octave_config_program;
            "OCTAVE"; octave_binary};
    scenv = sprintf ("%s='%s' ", cenv{:});

    ## Configure.
    if (packajoozle.internal.Util.isfile (fullfile (src, "configure")))
      flags = "";
      if (isempty (getenv ("CC")))
        flags = [flags ' CC="' mkoctfile("-p", "CC") '"'];
      endif
      if (isempty (getenv ("CXX")))
        flags = [flags ' CXX="' mkoctfile("-p", "CXX") '"'];
      endif
      if (isempty (getenv ("AR")))
        flags = [flags ' AR="' mkoctfile("-p", "AR") '"'];
      endif
      if (isempty (getenv ("RANLIB")))
        flags = [flags ' RANLIB="' mkoctfile("-p", "RANLIB") '"'];
      endif
      cmd = ["cd '" src "'; " scenv "./configure " flags];
      [status, output] = shell (cmd, verbose);
      packajoozle.internal.Util.filewrite (fullfile (log_dir, 'configure.log'), output);
      if (status != 0)
        packajoozle.internal.Util.rm_rf (desc.dir);
        disp (output);
        out.success = false;
        out.error_message = sprintf("pkj: error running the configure script for %s.", desc.name);
        return
      endif
    endif

    ## Make.
    if (ispc ())
      jobs = 1;
    else
      jobs = nproc ("overridable");
    endif

    if (packajoozle.internal.Util.isfile (fullfile (src, "Makefile")))
      [status, output] = shell (sprintf ("%s make --jobs %i --directory '%s'",
                                         scenv, jobs, src), verbose);
      packajoozle.internal.Util.filewrite (fullfile (log_dir, 'make.log'), output);
      if (status != 0)
        packajoozle.internal.Util.rm_rf (desc.dir);
        disp (output);
        out.success = false;
        out.error_message = sprintf("pkj: error running `make' for the %s package.", desc.name);
        return
      endif
    endif
  endif
endfunction

## Executes a shell command.
## In the end it calls system(), but in the case of MS Windows it will first
## check if sh.exe works.
##
## If VERBOSE is true, it will prints the output to STDOUT in real time and
## the second output argument will be an empty string.  Otherwise, it will
## contain the output of the execeuted command.
function [status, output] = shell (cmd, verbose)
  persistent have_sh;

  cmd = strrep (cmd, '\', '/');
  if (ispc () && ! isunix ())
    if (isempty (have_sh))
      if (system ('sh.exe -c "exit"'))
        have_sh = false;
      else
        have_sh = true;
      endif
    endif
    if (have_sh)
      cmd = ['sh.exe -c "' cmd '"'];
    else
      error ("pkj: unable to find the command shell.");
    endif
  endif
  if isunix
    cmd = [cmd ' 2>&1'];
  endif
  ## TODO: Figure out how to capture stderr on Windows
  [status, output] = system (cmd);
endfunction

function [out1, out2] = installed_packages (local_list, global_list, pkgname = {})

  ## Get the list of installed packages.
  try
    local_packages = load (local_list).local_packages;
  catch
    local_packages = {};
  end_try_catch
  try
    global_packages = load (global_list).global_packages;
  catch
    global_packages = {};
  end_try_catch
  installed_pkgs_lst = {local_packages{:}, global_packages{:}};

  ## Eliminate duplicates in the installed package list.
  ## Locally installed packages take precedence.
  installed_names = cellfun (@(x) x.name, installed_pkgs_lst,
                             "uniformoutput", false);
  [~, idx] = unique (installed_names, "first");
  installed_names = installed_names(idx);
  installed_pkgs_lst = installed_pkgs_lst(idx);

  ## Check whether info on a particular package was requested
  if (! isempty (pkgname))
    idx = find (strcmp (pkgname{1}, installed_names));
    if (isempty (idx))
      installed_names = {};
      installed_pkgs_lst = {};
    else
      installed_names = installed_names(idx);
      installed_pkgs_lst = installed_pkgs_lst(idx);
    endif
  endif

  ## Now check if the package is loaded.
  ## FIXME: Couldn't dir_in_loadpath() be used here?
  tmppath = strrep (path (), '\', '/');
  for i = 1:numel (installed_pkgs_lst)
    if (strfind (tmppath, strrep (installed_pkgs_lst{i}.dir, '\', '/')))
      installed_pkgs_lst{i}.loaded = true;
    else
      installed_pkgs_lst{i}.loaded = false;
    endif
  endfor
  for i = 1:numel (local_packages)
    if (strfind (tmppath, strrep (local_packages{i}.dir, '\', '/')))
      local_packages{i}.loaded = true;
    else
      local_packages{i}.loaded = false;
    endif
  endfor
  for i = 1:numel (global_packages)
    if (strfind (tmppath, strrep (global_packages{i}.dir, '\', '/')))
      global_packages{i}.loaded = true;
    else
      global_packages{i}.loaded = false;
    endif
  endfor

  ## Should we return something?
  if (nargout == 1)
    out1 = installed_pkgs_lst;
  elseif (nargout > 1)
    out1 = local_packages;
    out2 = global_packages;
  else
    ## Don't return anything, instead we'll print something.
    num_packages = numel (installed_pkgs_lst);
    if (num_packages == 0)
      if (isempty (pkgname))
        printf ("no packages installed.\n");
      else
        printf ("package %s is not installed.\n", pkgname{1});
      endif
      return;
    endif

    ## Compute the maximal lengths of name, version, and dir.
    h1 = "Package Name";
    h2 = "Version";
    h3 = "Installation directory";
    max_name_length = max ([length(h1), cellfun(@length, installed_names)]);
    version_lengths = cellfun (@(x) length (x.version), installed_pkgs_lst);
    max_version_length = max ([length(h2), version_lengths]);
    ncols = terminal_size ()(2);
    max_dir_length = ncols - max_name_length - max_version_length - 7;
    if (max_dir_length < 20)
      max_dir_length = Inf;
    endif

    h1 = postpad (h1, max_name_length + 1, " ");
    h2 = postpad (h2, max_version_length, " ");;

    ## Print a header.
    header = sprintf ("%s | %s | %s\n", h1, h2, h3);
    printf (header);
    tmp = sprintf (repmat ("-", 1, length (header) - 1));
    tmp(length(h1)+2) = "+";
    tmp(length(h1)+length(h2)+5) = "+";
    printf ("%s\n", tmp);

    ## Print the packages.
    format = sprintf ("%%%ds %%1s| %%%ds | %%s\n",
                      max_name_length, max_version_length);
    for i = 1:num_packages
      cur_name = installed_pkgs_lst{i}.name;
      cur_version = installed_pkgs_lst{i}.version;
      cur_dir = installed_pkgs_lst{i}.dir;
      if (length (cur_dir) > max_dir_length)
        first_char = length (cur_dir) - max_dir_length + 4;
        first_filesep = strfind (cur_dir(first_char:end), filesep ());
        if (! isempty (first_filesep))
          cur_dir = ["..." cur_dir((first_char + first_filesep(1) - 1):end)];
        else
          cur_dir = ["..." cur_dir(first_char:end)];
        endif
      endif
      if (installed_pkgs_lst{i}.loaded)
        cur_loaded = "*";
      else
        cur_loaded = " ";
      endif
      printf (format, cur_name, cur_loaded, cur_version, cur_dir);
    endfor
  endif

endfunction

function tf = dirempty (path, ignore_files = {})
  if ! myisfolder (path)
    tf = false;
    return;
  endif
  kids = packajoozle.internal.Util.readdir (path);
  found = setdiff (kids, ignore_files);
  tf = isempty (found);
endfunction

function out = myisfolder (path)
  out = packajoozle.internal.Util.isfolder (path);
endfunction

