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
    world = packajoozle.internal.InstallDirWorld.default
    default_installdir_tag = "user"
    verbose = false
  endproperties

  methods (Static)
    function out = parse_forge_target (str)
      ix = regexp (str, '^[\w]+$');
      if ! isempty (ix)
        out = packajoozle.internal.PkgVerReq (str);
        return
      endif
      ix = find (str == '@');
      if ! isempty (ix)
        if numel (ix) > 1
          error ("Too many @s in target: '%s'", str);
        endif
        pkg_name = str(1:ix);
        ver_filter_str = str(ix+1:end);
        ver_filter = packajoozle.internal.VerFilter.parse_ver_filter (ver_filter_str);
        out = packajoozle.internal.PkgVerReq (pkg_name, ver_filter);
        return
      endif
      error ("Invalid forge target string: '%s'", str);
    endfunction
  endmethods

  methods

    function this = PkgManager ()
      if nargin == 0
        return
      endif
    endfunction

    function valid = is_valid_pkg_version_string (this, str)
      ## We are limiting ourselves to this set of characters because the
      ## version will appear on the filepath.  The portable character, according to
      ## http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap03.html#tag_03_278
      ## is [A-Za-z0-9\.\_\-].  However, this is very limited.  We specially
      ## want to support a "+" so we can support "pkgname-2.1.0+" during
      ## development.  So we use Debian's character set for version strings
      ## https://www.debian.org/doc/debian-policy/ch-controlfields.html#s-f-Version
      ## with the exception of ":" (colon) because that's the PATH separator.
      ##
      ## Debian does not include "_" because it is used to separate the name,
      ## version, and arch in their deb files.  While the actual filenames are
      ## never parsed to get that information, it is important to have a unique
      ## separator character to prevent filename clashes.  For example, if we
      ## used hyhen as separator, "signal-2-1-rc1" could be "signal-2" version
      ## "1-rc1" or "signal" version "2-1-rc1".  A package file for both must be
      ## able to co-exist in the same directory, e.g., during package install or
      ## in a flat level package repository.
      valid = numel (regexp (str, '[^0-9a-zA-Z\.\+\-\~]')) == 0;
    endfunction

    function out = resolve_installdir (this, inst_dir)
      if isempty (inst_dir)
        inst_dir = this.default_installdir_tag;
      endif
      if ischar (inst_dir)
        out = this.world.get_installdir_by_tag (inst_dir);
      else
        mustBeA (inst_dir, "packajoozle.internal.InstallDir");
        out = inst_dir;
      endif
    endfunction

    function out = install_forge_pkgs (this, pkgreqs, inst_dir)
      if nargin < 3; inst_dir = []; endif
      inst_dir = this.resolve_installdir (inst_dir);

      # TODO: Resolve dependencies
      # Consider all packages to be installed

      for i = 1:numel (pkgreqs)
        # For now, just install the latest version of each one
        req = pkgreqs(i);
        #TODO: Actually respect the version filter
        pkgver = this.forge.resolve_latest_version (req.package);
        this.install_forge_pkg_single (pkgver);
      endfor
    endfunction

    function out = install_file_pkgs (this, files, inst_dir)
      if nargin < 3; inst_dir = []; endif
      inst_dir = this.resolve_installdir (inst_dir);

      # TODO: Resolve dependencies
      # Consider all packages to be installed

      for i = 1:numel (files)
        file = files{i};
        this.install_pkg_from_file (file, inst_dir);
      endfor
    endfunction
    

    function out = install_forge_pkg_single (this, pkgver, inst_dir)
      if nargin < 3; inst_dir = []; endif
      inst_dir = this.resolve_installdir (inst_dir);
      mustBeA (pkgver, "packajoozle.internal.PkgVer");
      
      dist_tgz = this.forge.download_cached_pkg_distribution (pkgver);
      this.install_pkg_from_file (dist_tgz);
    endfunction

    function out = install_pkg_from_file (this, file, inst_dir)
      if nargin < 3; inst_dir = []; endif
      inst_dir = this.resolve_installdir (inst_dir);

      # Remove existing installation of same pkg/ver
      info = this.get_pkg_description_from_pkg_file (file);
      pkgver = packajoozle.internal.PkgVer (info.name, info.version);
      if inst_dir.is_installed (pkgver)
        error ("PkgManager: already installed: %s", char (pkgver));
      endif


      build_dir_parent = tempname (tempdir, "packajoozle-build-");
      packajoozle.internal.Util.mkdir (build_dir_parent);
      #RAII.build_dir_parent = onCleanup (@() rm_rf_safe (build_dir_parent));
      files = unpack (file, build_dir_parent);
      kids = packajoozle.internal.Util.readdir (build_dir_parent);
      if numel (kids) > 1
        error ("PkgManager: bundles of packages are not allowed");
      endif
      build_dir = fullfile (build_dir_parent, kids{1});

      # Inspect the package

      target = inst_dir.install_paths_for_pkg (pkgver);
      verify_directory (build_dir);
      desc_file = fullfile (build_dir, "DESCRIPTION");
      orig_desc = this.parse_pkg_description_file (fileread (desc_file));
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
      finish_installation (desc, build_dir);
      try
        generate_lookfor_cache (desc, target);
      catch err
        warning ("PkgManager: failed creating lookfor cache for %s: %s", ...
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
        fprintf ("PkgManager: Failed updating package index file: %s", err.message);
        return
      end_try_catch

      # Give notifications to user

      printf ("Installed %s to %s / %s\n", desc.name, target.dir, target.arch_dir);
      news_file = fullfile (target.dir, "packinfo", "NEWS");
      if exist (news_file, "file")
        printf (["For information about changes from previous versions " ...
                 "of the %s package, run 'news %s'.\n"],
                desc.name, desc.name);
      endif        

    endfunction

    function require_deps_installed_from_desc (this, desc)
      bad_deps = this.get_unsatisfied_deps_from_desc (desc);
      if ! isempty (bad_deps)
        error ("PkgManager: unsatisified dependencies: %s", ...
          strjoin (dispstrs (bad_deps), ", "));
      endif
    endfunction

    function bad_deps = get_unsatisfied_deps_from_desc (this, desc)
      bad_deps = {};

      installed = this.all_installed_packages;
      for i = 1:numel (desc.depends)
        dep = desc.depends{i};
        dep_req = packajoozle.internal.PkgVerReq (dep.package, ...
          packajoozle.internal.VerFilter (dep.version, dep.operator));
        if isequal (dep.package, "octave")
          if (! compare_versions (OCTAVE_VERSION, dep.version, dep.operator))
            bad_deps{end+1} = dep_req;
          endif
        else
          if ! any (dep_req.matches (installed))
            bad_deps{end+1} = dep_req;
          endif
        endif
      endfor
    endfunction

    function out = get_pkg_description_from_pkg_file (this, file)
      tmp_dir = tempname (tempdir, "packajoozle-work-");
      packajoozle.internal.Util.mkdir (tmp_dir);
      untar (file, tmp_dir);
      kids = packajoozle.internal.Util.readdir (tmp_dir);
      if numel (kids) > 1
        error ("PkgManager: Multiple top-level directories found in pkg file: %s", file);
      endif
      subdir = fullfile (tmp_dir, kids{1});
      descr_file = fullfile (subdir, "DESCRIPTION");
      if ! exist (descr_file, "file")
        error ("PkgManager: Pkg file does not contain a DESCRIPTION file: %s", file);
      endif
      descr_txt = fileread (descr_file);
      out = this.parse_pkg_description_file (descr_txt);
    endfunction

    function out = parse_pkg_description_file (this, descr_txt)
      desc = struct ();

      lines = regexp (descr_txt, "\r?\n", "split");
      if isempty (lines{end})
        lines(end) = [];
      endif

      for i = 1:numel (lines)
        line = chomp (lines{i});
        if isempty (line)
          ## Ignore empty lines
        elseif (line(1) == "#")
          ## Comments, do nothing.
        elseif (isspace (line(1)))
          ## Continuation lines
          if (exist ("keyword", "var") && isfield (desc, keyword))
            desc.(keyword) = [desc.(keyword) " " deblank(line)];
          endif
        else
          ## Keyword/value pair
          colon = find (line == ":");
          if (length (colon) == 0)
            warning ("pkg: skipping invalid line %d in DESCRIPTION file: '%s'", i, line);
          else
            colon = colon(1);
            keyword = tolower (strtrim (line(1:colon-1)));
            value = strtrim (line (colon+1:end));
            if (length (value) == 0)
                fclose (fid);
                error ("PkgManager: The keyword '%s' of the package '%s' has an empty value",
                        keyword, desc.name);
            endif
            if (isfield (desc, keyword))
              warning ("PkgManager: duplicate keyword '%s' in DESCRIPTION, ignoring",
                       keyword);
            else
              desc.(keyword) = value;
            endif
          endif
        endif
      endfor

      ## Make sure all is okay.
      needed_fields = {"name", "version", "date", "title", ...
                       "author", "maintainer", "description"};
      for f = needed_fields
        if (! isfield (desc, f{1}))
          error ("PkgManager: DESCRIPTION is missing needed field %s", f{1});
        endif
      endfor

      if (! this.is_valid_pkg_version_string (desc.version))
        error ("PkgManager: invalid version string '%s'", desc.version);
      endif

      if (isfield (desc, "depends"))
        desc.depends = fix_depends (desc.depends);
      else
        desc.depends = "";
      endif
      desc.name = tolower (desc.name);
      out = desc;
    endfunction

    function out = all_installed_packages (this)
      # Returns list as PkgVers
      inst_dirs = this.world.get_all_installdirs;
      out = inst_dirs(1).installed_packages;
      for i = 2:numel (inst_dirs)
        out = packajoozle.internal.Util.objcat (out, inst_dirs(i).installed_packages);
      endfor
    endfunction

    function out = all_installed_packages_descs (this)
      inst_dirs = this.world.get_all_installdirs;
      out = {};
      for i = 1:numel (inst_dirs)
        out = [out inst_dirs(i).get_package_list];
      endfor
    endfunction
    
    function uninstall_all_versions (this, pkg_name)
      error ("this is not yet implemented")
    endfunction

    function uninstall (this, pkgvers)

      # TODO: Check dependencies
      # Calculate remaining installed packages and see that their deps are still
      # satisfied

      # If we're clear to proceed:
      for i = 1:numel (pkgvers)
        this.uninstall_one (pkgvers(i));
      endfor
    endfunction

    function uninstall_one (this, pkgver)
      %UNINSTALL_ONE Uninstall a package from wherever it is installed
      mustBeA (pkgver, "packajoozle.internal.PkgVer");
      mustBeScalar (pkgver);

      inst_dirs = packajoozle.internal.InstallDir.get_all_installdirs;

      found = false;
      for i_inst_dir = 1:numel (inst_dirs)
        inst_dir = inst_dirs(i);
        if inst_dir.is_installed (pkgver)
          #TODO: Get desc for installed package
          target = inst_dir.install_paths_for_pkg (pkgver);

          # Run pre-uninstall hooks
          if exist (fullfile (target.dir, "packinfo", "on_uninstall.m"), "file")
            orig_pwd = pwd;
            try
              cd (fullfile (target.dir, "packinfo"));
              on_uninstall (desc);
              cd (orig_pwd);
            catch err
              cd (orig_pwd);
              error ("Error while running on_uninstall hook for %s: %s", ...
                char (pkgver), err.message);
            end_try_catch
          endif

          # Delete package installation directories
          if ! isfolder (target.dir)
            warning ("PkgManager: directory %s previously lost; marking %s as uninstalled", ...
             target.dir, char (pkgver));
          endif
          packajoozle.internal.Util.rm_rf (target.arch_dir);
          packajoozle.internal.Util.rm_rf (target.dir);

          # Update package index
          inst_dir.record_uninstalled_package (pkgver);
        endif
      endfor

      if ! found
        error ("PkgManager: package %s is not installed", char (pkgver));
      endif
    endfunction
    
  endmethods

endclassdef

function say (varargin)
  fprintf ("%s: %s\n", "PkgManager", sprintf (varargin{:}));
  flush_diary
endfunction

function out = chomp (str)
  out = regexprep (str, "\r?\n$", "");
endfunction

function rm_rf_safe (path)
  try
    packajoozle.internal.Util.rm_rf (path);
  catch err
    warning ("failed deleting directory: %s", err.message);
  end_try_catch
endfunction

% ======================================================
%
% Code copied from Octave's pkg/pkg.m

## Make sure the depends field is of the right format.
## This function returns a cell of structures with the following fields:
##   package, version, operator
function deps_cell = fix_depends (depends)

  deps = strtrim (ostrsplit (tolower (depends), ","));
  deps_cell = cell (1, length (deps));
  dep_pat = ...
  '\s*(?<name>[-\w]+)\s*(\(\s*(?<op>[<>=]+)\s*(?<ver>\d+\.\d+(\.\d+)*)\s*\))*\s*';

  ## For each dependency.
  for i = 1:length (deps)
    dep = deps{i};
    [start, nm] = regexp (dep, dep_pat, 'start', 'names');
    ## Is the dependency specified
    ## in the correct format?
    if (! isempty (start))
      package = tolower (strtrim (nm.name));
      ## Does the dependency specify a version
      ## Example: package(>= version).
      if (! isempty (nm.ver))
        operator = nm.op;
        if (! any (strcmp (operator, {">", ">=", "<=", "<", "=="})))
          error ("PkgManager: unsupported operator in dependency: %s", operator);
        endif
        pkgman = packajoozle.internal.PkgManager;
        if (! pkgman.is_valid_pkg_version_string (nm.ver))
          error ("PkgManager: invalid version string in dependency: '%s'", nm.ver);
        endif
      else
        ## If no version is specified for the dependency
        ## we say that the version should be greater than
        ## or equal to "0.0.0".
        package = tolower (strtrim (dep));
        operator = ">=";
        nm.ver  = "0.0.0";
      endif
      deps_cell{i} = struct ("package", package,
                             "operator", operator,
                             "version", nm.ver);
    else
      error ("PkgManager: incorrect syntax for dependency '%s' in the DESCRIPTION file\n",
             dep);
    endif
  endfor

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
    if (! exist (fullfile (dir, f{1}), "file"))
      error ("package is missing file: %s", f{1});
    endif
  endfor

endfunction


function prepare_installation (desc, build_dir)

  ## Is there a pre_install to call?
  if (exist (fullfile (build_dir, "pre_install.m"), "file"))
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
  if (! isfolder (inst_dir))
    [status, msg] = mkdir (inst_dir);
    if (status != 1)
      rmdir (desc.dir, "s");
      error ("the 'inst' directory did not exist and could not be created: %s",
             msg);
    endif
  endif

endfunction


function copy_built_files (desc, build_dir, verbose)
  % Copies built files from src/ to inst/ within a build dir

  src = fullfile (build_dir, "src");
  if (! isfolder (src))
    return
  endif

  ## Copy files to "inst" and "inst/arch" (this is instead of 'make install').
  files = fullfile (src, "FILES");
  instdir = fullfile (build_dir, "inst");
  archdir = fullfile (build_dir, "inst", packajoozle.internal.Util.get_system_arch ());

  ## Get filenames.
  if (exist (files, "file"))
    [fid, msg] = fopen (files, "r");
    if (fid < 0)
      error ("couldn't open %s: %s", files, msg);
    endif
    filenames = char (fread (fid))';
    fclose (fid);
    if (filenames(end) == "\n")
      filenames(end) = [];
    endif
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
      if (! isfolder (instdir))
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
          rmdir (desc.dir, "s");
          error ("Couldn't copy files from 'src' to 'inst': %s", output);
        endif
      endif
      if (! all (isspace ([archdependent{:}])))
        if (verbose)
          printf ("copyfile");
          printf (" %s", archdependent{:});
          printf (" %s\n", archdir);
        endif
        if (! isfolder (archdir))
          mkdir (archdir);
        endif
        [status, output] = copyfile (archdependent, archdir);
        if (status != 1)
          rmdir (desc.dir, "s");
          error ("Couldn't copy files from 'src' to 'inst': %s", output);
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

  ## Create the installation directory.
  if (! isfolder (install_dir))
    [status, output] = mkdir (install_dir);
    if (status != 1)
      error ("couldn't create installation directory %s : %s",
      install_dir, output);
    endif
  endif


  ## Copy the files from "inst" to installdir.
  instdir = fullfile (build_dir, "inst");
  if (! dirempty (instdir))
    [status, output] = copyfile (fullfile (instdir, "*"), desc.dir);
    if (status != 1)
      rmdir (desc.dir, "s");
      error ("couldn't copy files to the installation directory");
    endif
    if (isfolder (fullfile (desc.dir, getarch ()))
        && ! strcmp (canonicalize_file_name (fullfile (desc.dir, getarch ())),
                     canonicalize_file_name (octfiledir)))
      if (! isfolder (octfiledir))
        ## Can be required to create up to three levels of dirs.
        octm1 = fileparts (octfiledir);
        if (! isfolder (octm1))
          octm2 = fileparts (octm1);
          if (! isfolder (octm2))
            octm3 = fileparts (octm2);
            if (! isfolder (octm3))
              [status, output] = mkdir (octm3);
              if (status != 1)
                rmdir (desc.dir, "s");
                error ("couldn't create installation directory %s : %s",
                       octm3, output);
              endif
            endif
            [status, output] = mkdir (octm2);
            if (status != 1)
              rmdir (desc.dir, "s");
              error ("couldn't create installation directory %s : %s",
                     octm2, output);
            endif
          endif
          [status, output] = mkdir (octm1);
          if (status != 1)
            rmdir (desc.dir, "s");
            error ("couldn't create installation directory %s : %s",
                   octm1, output);
          endif
        endif
        [status, output] = mkdir (octfiledir);
        if (status != 1)
          rmdir (desc.dir, "s");
          error ("couldn't create installation directory %s : %s",
          octfiledir, output);
        endif
      endif
      [status, output] = movefile (fullfile (desc.dir, getarch (), "*"),
                                   octfiledir);
      rmdir (fullfile (desc.dir, getarch ()), "s");

      if (status != 1)
        rmdir (desc.dir, "s");
        rmdir (octfiledir, "s");
        error ("couldn't copy files to the installation directory");
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
  if (exist (index_file, "file"))
    packinfo_copy_file ("INDEX", "required", build_dir, packinfo_dir);
  else
    generate_index (desc, fullfile (build_dir, "inst"), fullfile (packinfo, "INDEX"));
  endif

  ## Is there an 'on_uninstall.m' to install?
  packinfo_copy_file ("on_uninstall.m", "optional", build_dir, packinfo_dir);

  ## Is there a doc/ directory that needs to be installed?
  docdir = fullfile (build_dir, "doc");
  if (isfolder (docdir) && ! dirempty (docdir))
    [status, output] = copyfile (docdir, desc.dir);
  endif

  ## Is there a bin/ directory that needs to be installed?
  ## FIXME: Need to treat architecture dependent files in bin/
  bindir = fullfile (build_dir, "bin");
  if (isfolder (bindir) && ! dirempty (bindir))
    [status, output] = copyfile (bindir, desc.dir);
  endif

endfunction


function packinfo_copy_file (filename, requirement, build_dir, packinfo_dir)

  filepath = fullfile (build_dir, filename);
  if (! exist (filepath, "file") && strcmpi (requirement, "optional"))
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
    if (isfolder (class_dir))
      files2 = packajoozle.internal.Util.readdir (class_dir);
      files2 = strcat (class_name, filesep (), files2);
      files = [files; files2];
    endif
  endfor

  ## Check for architecture dependent files.
  arch_dir = desc.arch_dir;
  if (isfolder (tmpdir))
    files2 = packajoozle.internal.Util.readdir (arch_dir);
    files = [files; files2];
  endif

  functions = {};
  for i = 1:length (files)
    file = files{i};
    lf = length (file);
    if (lf > 2 && strcmp (file(end-1:end), ".m"))
      functions{end+1} = file(1:end-2);
    elseif (lf > 4 && strcmp (file(end-3:end), ".oct"))
      functions{end+1} = file(1:end-4);
    endif
  endfor

  ## Does desc have a categories field?
  if (! isfield (desc, "categories"))
    error ("PkgManager: the DESCRIPTION file must have a Categories field, when no INDEX file is given");
  endif
  categories = strtrim (strsplit (desc.categories, ","));
  if (length (categories) < 1)
    error ("PkgManager: the Category field in DESCRIPTION is empty");
  endif

  ## Write INDEX.
  fid = packajoozle.internal.Util.fopen (index_file);
  fprintf (fid, "%s >> %s\n", desc.name, desc.title);
  fprintf (fid, "%s\n", categories{1});
  fprintf (fid, "  %s\n", functions{:});
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
  if isfolder (archdir) && ! isequal (inst_dir, archdir)
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
    if (exist (build_dirnm, "file"))
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

  ## Is there a post-install to call?
  if (exist (fullfile (build_dir, "post_install.m"), "file"))
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
% Other functions copied from Octave's pkg/private


function out = configure_make (desc, build_dir, verbose)
  % Returns struct with fields:
  %  success (boolean)
  %  log_dir (char)
  %  error_message (char)
  %  exception (MException or [])
  %
  % log_dir will still be populated and valid even if success is false.

  timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
  tmp_dir_name = ['octave-packajoozle-PkgManager-' timestamp];
  log_dir = fullfile (tempdir, 'octave-packajoozle', tmp_dir_name);
  packajoozle.internal.Util.mkdir (log_dir);
  out.log_dir = log_dir;
  out.success = true;
  out.error_message = '';
  out.exception = [];
  
  ## Perform ./configure, make, make install in "src".
  if (isfolder (fullfile (build_dir, "src")))
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

    if (! exist (mkoctfile_program, "file"))
      __gripe_missing_component__ ("pkg", "mkoctfile");
    endif
    if (! exist (octave_config_program, "file"))
      __gripe_missing_component__ ("pkg", "octave-config");
    endif
    if (! exist (octave_binary, "file"))
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
    if (exist (fullfile (src, "configure"), "file"))
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
        rmdir (desc.dir, "s");
        disp (output);
        out.success = false;
        out.error_message = sprintf("pkg: error running the configure script for %s.", desc.name);
        return
      endif
    endif

    ## Make.
    if (ispc ())
      jobs = 1;
    else
      jobs = nproc ("overridable");
    endif

    if (exist (fullfile (src, "Makefile"), "file"))
      [status, output] = shell (sprintf ("%s make --jobs %i --directory '%s'",
                                         scenv, jobs, src), verbose);
      packajoozle.internal.Util.filewrite (fullfile (log_dir, 'make.log'), output);
      if (status != 0)
        rmdir (desc.dir, "s");
        disp (output);
        out.success = false;
        out.error_message = sprintf("pkg: error running `make' for the %s package.", desc.name);
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
      error ("pkg: unable to find the command shell.");
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
  if ! isfolder (path)
    tf = false;
    return;
  endif
  kids = packajoozle.internal.Util.readdir (path);
  found = setdiff (kids, ignore_files);
  tf = ! isempty (found);
endfunction

