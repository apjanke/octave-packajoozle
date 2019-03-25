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
## @deftypefn {Class Constructor} {obj =} PkgReviewer ()
##
## Reviews packages to see if they're ready for Octave Forge release.
##
## This is the logic behind the `pkj review` command. It's for use by
## Octave Forge maintainers to quality-check packages before publishing
## them to Octave Forge.
##
## PkgReviewer is a one-shot object: create one and use it to review one
## package; then create a fresh one to review another package.
## @end deftypefn

classdef PkgReviewer < handle

  properties
    verbose = true
    fail_fast = false;

    forge = packajoozle.internal.OctaveForgeClient;
    pkg_spec = [];
    pkgver = [];
    tmp_dir = [];
    errors = {};
    warnings = {};
  endproperties

  properties (Dependent)
    ok
  endproperties

  methods

    function this = PkgReviewer ()
      if nargin == 0
        return
      endif
    endfunction

    function out = get.ok (this)
      out = isempty (this.errors);
    endfunction

    function out = review_package (this, pkg_spec)
      this.review_package_impl (pkg_spec);
      this.display_results;
      out.ok = this.ok;
      out.errors = this.errors;
    endfunction

    function bad (this, fmt, varargin)
      this.errors{end+1} = sprintf (fmt, varargin{:});
      if this.fail_fast
        this.display_results;
        error ("Package review failed");
      endif
    endfunction

    function so_so (this, fmt, varargin)
      this.warnings{end+1} = sprintf (fmt, varargin{:});
    endfunction

    function display_results (this)
      if this.ok
        fprintf ("Package review passed for %s.\n", char (this.pkg_spec));
        if ! isempty (this.warnings)
          fprintf ("But there were warnings:\n%s\n", strjoin (strcat ({"  "}, this.warnings), "\n"));
        endif
      else
        fprintf ("Package review failed for %s.\n", char (this.pkg_spec));
        fprintf ("Errors:\n%s\n", strjoin (strcat ({"  "}, this.errors), "\n"));
        if ! isempty (this.warnings)
          fprintf ("Warnings:\n%s\n", strjoin (strcat ({"  "}, this.warnings), "\n"));
        endif
      endif
    endfunction

    function [ok, tgz_file, dist_file] = make_dist_from_repo (this, repo_dir)
      orig_pwd = pwd;
      RAII.cd = onCleanup (@() cd (orig_pwd));
      ok = false;
      tgz_file = [];
      cd (repo_dir);
      this.say ("Creating distribution tarball from repo at %s", repo_dir);
      this.say ("make dist");
      [status, output] = system ("make dist");
      if status != 0
        this.bad("'make dist' failed. make output:\n%s", output);
        return
      endif
      desc_file = fullfile (repo_dir, "DESCRIPTION");
      desc = packajoozle.internal.PkgDistUtil.parse_pkg_description_file (desc_file);
      pkgver = packajoozle.internal.PkgVer (desc.name, desc.version);
      this.pkgver = pkgver;
      expected_tarball_basename = sprintf ("%s-%s.tar.gz", desc.name, desc.version);
      if exist (fullfile (repo_dir, expected_tarball_basename), "file")
        built_dist_file = fullfile (repo_dir, expected_tarball_basename);
      else
        this.so_so ("Expected dist file %s not created by 'make dist' in root of repo", ...
          expected_tarball_basename);
        legacy_tarball_dirs = {
          'target'
          'tmp'
          'build'
        };
        built_dist_file = [];
        for i = 1:numel (legacy_tarball_dirs)
          candidate = fullfile (legacy_tarball_dirs{i}, expected_tarball_basename);
          if exist (candidate, "file");
            built_dist_file = candidate;
            this.so_so ("Actual dist file was at %s", candidate);
            break
          endif
        endfor
        if isempty (built_dist_file)
          error ("Cannot locate tarball produced by 'make dist'. Cannot continue.\n");
        endif
      endif
      packajoozle.internal.Util.copyfile (built_dist_file, this.tmp_dir);
      tgz_file = fullfile (this.tmp_dir, expected_tarball_basename);
      dist_file = built_dist_file;
      ok = true;
    endfunction

    function review_package_impl (this, pkg_spec)
      tmp_dir = tempname (tempdir, "packajoozle/pkj-review/work-");
      this.tmp_dir = tmp_dir;
      packajoozle.internal.Util.mkdir (tmp_dir);
      RAII.tmp_dir = onCleanup (@() packajoozle.internal.Util.rm_rf (tmp_dir));
      orig_dir = pwd;
      RAII.pwd = onCleanup (@() cd(orig_dir));
      this.say ("Working dir: %s", tmp_dir);

      this.pkg_spec = pkg_spec;
      this.ok = false;
      this.errors = {};
      if exist (pkg_spec, "dir")
        # This should be a local repo clone. Create the dist file in it
        repo_dir = pkg_spec;
        [ok, tgz_file, dist_file] = this.make_dist_from_repo (repo_dir, tmp_dir);
        if ! ok
          error ("Failed creating distribution archive from repo. Cannot proceed.\n");
        endif
        pkgver = this.pkgver;
      elseif exist(pkg_spec, "file")
        dist_file = pkg_spec;
        desc = packajoozle.internal.PkgDistUtil.get_pkg_description_from_pkg_archive_file (dist_file);
        pkgver = packajoozle.internal.PkgVer (desc.name, desc.version);
        tgz_basename = my_basename (dist_file);
        packajoozle.internal.Util.copyfile (dist_file, tmp_dir);
        tgz_file = fullfile (tmp_dir, tgz_basename);
      else
        forge_target = packajoozle.internal.OctaveForgeClient.parse_forge_targets (pkg_spec);
        if ! isscalar (forge_target)
          error ("review_package: only a single target is allowed; got %d", numel (forge_target));
        endif
        pkgver = forge_target;
        dist_file = this.forge.download_cached_pkg_distribution (pkgver);
        [~, tgz_basename] = fileparts (dist_file);
        packajoozle.internal.Util.copyfile (dist_file, tmp_dir);
        tgz_file = fullfile (tmp_dir, tgz_basename);        
      endif
      this.say ("Reviewing %s from file %s", char (pkgver), dist_file);

      % We have a dist tarball staged in the temporary directory. Test it.
      cd (tmp_dir);
      mkdir ("extracted");

      % Examine distribution archive contents

      this.say ("Examining distribution file contents")
      files = unpack (tgz_file, "extracted");
      cd ("extracted");
      kids = packajoozle.internal.Util.readdir (".");
      if numel (kids) > 1
        this.bad ("Multiple top-level dirs in tarball: %s", strjoin (kids, ", "));
        return
      endif
      if isempty (kids)
        this.bad ("Distribution tarball was empty");
        return
      endif
      top_level = kids{1};

      [all_files, stats] = packajoozle.internal.Util.file_find (top_level, [], @stat);
      modestrs = cellfun (@(x) {x.modestr}, stats);
      modestrs = cat (1, modestrs{:});
      tf_readable = modestrs(:,5) == 'r' & modestrs(:,8) == 'r';
      ix_not_readable = find (! tf_readable);
      if ! isempty (ix_not_readable)
        this.bad ("Some files were not world-readable: %s", ...
          strjoin (all_files(ix_not_readable), ", "));
      endif
      # TODO: Do we need to check that all dirs are a+x?
      # TODO: Check that certain files are executable?
      # TODO: Check for hidden files. What did Olaf Till mean by that? Files starting with a "."?
      # Or with some "hidden" attribute?
      # http://lists.gnu.org/archive/html/octave-maintainers/2019-03/msg00156.html

      cd (top_level);
      lastwarn("");
      desc = packajoozle.internal.PkgDistUtil.parse_pkg_description_file ("DESCRIPTION");
      [msg, msgid] = lastwarn ();
      if ! isempty (msg)
        this.bad ("DESCRIPTION file has warnings: %s", msg);
      endif
      pkgver = packajoozle.internal.PkgVer (desc.name, desc.version);

      tgz_basename = my_basename (tgz_file);
      expect_tgz_basename = sprintf ("%s-%s.tar.gz", desc.name, desc.version);
      if ! isequal (tgz_basename, expect_tgz_basename);
        this.bad ("Dist file name '%s' doesn't match name/version from DESCRIPTION (should be %s)", ...
          tgz_basename, expect_tgz_basename);
      endif

      naughty_files = {
        "configure.log"
        "config.guess"
      };
      for i = 1:numel (naughty_files)
        if exist ([ "./" naughty_files{i}], "file")
          this.bad ("Bad file in dist tarball: %s", naughty_files{i});
        endif
      endfor

      if exist ("src/configure.ac", "file")
        config_ac_txt = fileread ("src/configure.ac");
        # TODO: Check for version definition
        ac_init_pat = '^AC_INIT\(\[(.*?)\], +\[(.*?)\]';
        [ix, tok] = regexp (config_ac_txt, ac_init_pat, 'start', 'tokens', 'lineanchors');
        if isempty (ix)
          this.bad ("Could not find valid AC_INIT(...) line in configure.ac");
        else
          tok = tok{1};
          [ac_name, ac_ver] = deal (tok{1}, tok{2});
          if ! isequal (ac_name, desc.name)
            # We don't enforce this.
            #this.bad ("Name in configure.ac AC_INIT(...) does not match DESCRIPTION");
          endif
          if ! isequal (ac_ver, desc.version)
            this.bad ("Version in configure.ac AC_INIT(...) does not match version in DESCRIPTION");
          endif
        endif
      endif

      # Install and BIST test it
      # TODO: Turn these pkj() calls into object calls

      this.say ("Installing package")
      pkgman = packajoozle.internal.PkgManager;
      pkgreq = packajoozle.internal.PkgVerReq (pkgver);
      if ! isempty (pkgman.world.list_installed_matching (pkgreq))
        error ("pkj: review: Cannot install %s: it is already installed\n", char (pkgver));
      endif
      lastwarn("");
      inst_rslt = pkj ("install", "-file", tgz_file);
      [msg, msgid] = lastwarn ();
      if ! isempty (msg)
        this.bad ("Warnings during package installation: %s", msg);
      endif
      if ! inst_rslt.success
        this.bad ("Installation failed: %s", err.message);
        return
      endif

      this.say ("Loading package");
      try
        lastwarn("");
        pkgman.load_packages (pkgver);
        [msg, msgid] = lastwarn ();
        if ! isempty (msg)
          this.bad ("Warnings during package loading: %s", msg);
        endif
      catch err
        this.bad ("Failed loading installed package: %s", err.message);
        return
      end_try_catch

      # TODO: run tests on the package
      # We can't use Testify, because Testify depends on Packajoozle, and that would
      # cause a dependency cycle.
      # Probably just call runtests() with evalc and parse its output

      # Test for clean unloading and uninstallation

      this.say ("Unloading package");
      try
        pkgman.unload_packages (pkgreq);
      catch err
        this.bad ("Error while unloading package: %s", err.message);
      end_try_catch

      #TODO: Implement this in PkgManager
      #loaded = pkgman.list_loaded_packages
      #if ismember (pkgver, loaded)
      #  out.errors{end+1} = sprintf ("Package did not unload cleanly");
      #endif

      this.say ("Uninstalling package");
      try
        pkgman.uninstall_one_package (pkgver);
      catch err
        this.bad ("Package failed uninstalling: %s", err.message);
      end_try_catch
      installed = pkgman.world.list_installed_matching (pkgreq);
      if ! isempty (installed)
        this.bad ("Package did not unload cleanly");
      endif

      # Ran all checks
      this.say ("All checks finished");
    endfunction

    function say (this, fmt, varargin)
      if this.verbose
        fprintf(["PkgReviewer: " fmt "\n"], varargin{:});
      endif
    endfunction

  endmethods

endclassdef

function out = my_basename (file)
  out = file;
  ix = find(out == filesep);
  if ! isempty (ix)
    out(1:ix(end)) = [];
  endif
endfunction

function out = strip_file_extension (file)
  if ! isempty (regexp (file, '\.tar\.gz$'))
    out = regexprep (file, '\.tar\.gz$', '');
  else
    [~, out, ~] = fileparts (file);
  endif
endfunction
