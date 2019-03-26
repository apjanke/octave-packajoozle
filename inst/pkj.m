## Copyright (C) 2019 Andrew Janke
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; If not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {} {} pkj @var{command} @var{pkg_name}
## @deftypefnx {} {} pkj @var{command} @var{option} @var{pkg_name}
## @deftypefnx {} {[@var{out1}, @dots{}] =} pkj (@var{command}, @dots{} )
## Manage or query packages (groups of add-on functions) for Octave.
##
## pkj is the main command interface for the Packajoozle package manager.
##
## Different actions are available depending on the value of @var{command},
## the additional options supplied, and the return arguments captured.
##
## Please note, pkj is a work in progress. Some of the commands listed 
## below will not actually work. If you have trouble with any of them, please
## post a bug report at https://github.com/apjanke/octave-packajoozle/issues.
##
## Available commands:
##
## @table @samp
##
## @item install
## Install named packages.  For example,
##
## @example
## pkj install image-1.0.0.tar.gz
## @end example
##
## @noindent
## installs the package found in the file @file{image-1.0.0.tar.gz}.  The
## file containing the package can be an url, e.g.
##
## @example
## pkj install 'http://somewebsite.org/image-1.0.0.tar.gz'
## @end example
##
## @noindent
## installs the package found in the given url.  This
## requires an internet connection and the cURL library.
##
## @noindent
## @emph{Security risk}: no verification of the package is performed
## before the installation.  It has the same security issues as manually
## downloading the package from the given url and installing it.
##
## @noindent
## @emph{No support}: the GNU Octave community is not responsible for
## packages installed from foreign sites.  For support or for
## reporting bugs you need to contact the maintainers of the installed
## package directly (see the @file{DESCRIPTION} file of the package).
##
## The @var{option} variable can contain options that affect the manner
## in which a package is installed.  These options can be one or more of:
##
## @table @code
## @item -nodeps
## The package manager will disable dependency checking.  With this option it
## is possible to install a package even when it depends on another package
## which is not installed on the system.  @strong{Use this option with care.}
##
## @item -local
## A local installation (package available only to current user) is forced,
## even if the user has system privileges.
##
## @item -global
## A global installation (package available to all users) is forced, even if
## the user doesn't normally have system privileges.
##
## @item -forge
## Install a package directly from the Octave Forge repository.  This
## requires an internet connection and the cURL library.
##
## @example
## pkj install -forge io
## pkj install -forge io@@2.4.9
## pkj install -forge symbolic@@<=2.6.5
## pkj install -forge io statistics financial@@0.5.1
## @end example
##
## @emph{Security risk}: no verification of the package is performed
## before the installation.  There are no signature for packages, or
## checksums to confirm the correct file was downloaded.  It has the
## same security issues as manually downloading the package from the
## Octave Forge repository and installing it.
##
## @item -verbose
## The package manager will print the output of all commands as
## they are performed.
## @end table
##
## @item update
## Check installed Octave Forge packages against repository and update any
## outdated items.  This requires an internet connection and the cURL library.
## Usage:
##
## @example
## pkg update
## @end example
##
## @noindent
## To update a single package use @code{pkj install -forge}.
##
## @item uninstall
## Uninstall named packages.  For example,
##
## @example
## pkj uninstall image
## @end example
##
## @noindent
## removes the @code{image} package from the system.  If another installed
## package depends on the @code{image} package an error will be issued.
## The package can be uninstalled anyway by using the @option{-nodeps} option.
##
## @item load
## Add named packages to the path.  After loading a package it is
## possible to use the functions provided by the package.  For example,
##
## @example
## pkg load image
## @end example
##
## @noindent
## adds the @code{image} package to the path.
##
## @item unload
## Remove named packages from the path.  After unloading a package it is
## no longer possible to use the functions provided by the package.
##
## @item list
## Show the list of currently installed packages.  For example,
##
## @example
## pkj list
## @end example
##
## @noindent
## will produce a short report with the package name, version, and installation
## directory for each installed package.  Supply a package name to limit
## reporting to a particular package.  For example:
##
## @example
## pkj list image
## @end example
##
## If a single return argument is requested then @code{pkj} returns a cell
## array where each element is a structure with information on a single
## package.
##
## @example
## installed_packages = pkj ("list")
## @end example
##
## If two output arguments are requested @code{pkj} splits the list of
## installed packages into those which were installed by the current user,
## and those which were installed by the system administrator.
##
## @example
## [user_packages, system_packages] = pkj ("list")
## @end example
##
## The @qcode{"-forge"} option lists packages available at the Octave Forge
## repository.  This requires an internet connection and the cURL library.
## For example:
##
## @example
## oct_forge_pkgs = pkj ("list", "-forge")
## @end example
##
## @item describe
## Show a short description of installed packages.  With the option
## @qcode{"-verbose"} also list functions provided by the package.  For
## example,
##
## @example
## pkj describe -verbose
## @end example
##
## @noindent
## will describe all installed packages and the functions they provide.
## Display can be limited to a set of packages:
##
## @example
## ## describe control and signal packages
## pkj describe control signal
## @end example
##
## If one output is requested a cell of structure containing the
## description and list of functions of each package is returned as
## output rather than printed on screen:
##
## @example
## desc = pkj ("describe", "secs1d", "image")
## @end example
##
## @noindent
## If any of the requested packages is not installed, @code{pkj} returns an
## error, unless a second output is requested:
##
## @example
## [desc, flag] = pkj ("describe", "secs1d", "image")
## @end example
##
## @noindent
## @var{flag} will take one of the values @qcode{"Not installed"},
## @qcode{"Loaded"}, or
## @qcode{"Not loaded"} for each of the named packages.
##
##
## @item contents
## List contents of named packages.  For example,
##
## @example
## pkj contents image
## @end example
##
## @item test
## Test the named packages
##
## @example
## pkj test io nan
## @end example
##
## @item prefix
## Set the installation prefix directory.  For example,
##
## @example
## pkj prefix ~/my_octave_packages
## @end example
##
## @noindent
## sets the installation prefix to @file{~/my_octave_packages}.
## Packages will be installed in this directory.
##
## It is possible to get the current installation prefix by requesting an
## output argument.  For example:
##
## @example
## pfx = pkj ("prefix")
## @end example
##
## The location in which to install the architecture dependent files can be
## independently specified with an addition argument.  For example:
##
## @example
## pkj prefix ~/my_octave_packages ~/my_arch_dep_pkgs
## @end example
##
## @item local_list
## Set the file in which to look for information on locally
## installed packages.  Locally installed packages are those that are
## available only to the current user.  For example:
##
## @example
## pkj local_list ~/.octave_packages
## @end example
##
## It is possible to get the current value of local_list with the following:
##
## @example
## pkj local_list
## @end example
##
## @item global_list
## Set the file in which to look for information on globally
## installed packages.  Globally installed packages are those that are
## available to all users.  For example:
##
## @example
## pkj global_list /usr/share/octave/octave_packages
## @end example
##
## It is possible to get the current value of global_list with the following:
##
## @example
## pkj global_list
## @end example
##
## @item build
## Build a binary form of a package or packages.  The binary file produced
## will itself be an Octave package that can be installed normally with
## @code{pkj}.  The form of the command to build a binary package is:
##
## @example
## pkj build builddir image-1.0.0.tar.gz @dots{}
## @end example
##
## @noindent
## where @code{builddir} is the name of a directory where the temporary
## installation will be produced and the binary packages will be found.
## The options @option{-verbose} and @option{-nodeps} are respected, while
## all other options are ignored.
##
## @item rebuild
## Rebuild the package database from the installed directories.  This can
## be used in cases where the package database has been corrupted.
##
##
## @item review
## Review a package distribution tarball to see if it meets Octave Forge's
## quality standards.
##
## @example
## pkj review strings-1.2.0.tar.gz
## pkj review /path/to/my/local/clone/of/octave-strings
## pkj review strings@@1.2.0
## pkj review -verbose strings-1.2.0.tar.gz
## # Abort on first error
## pkj review -verbose -fail-fast strings-1.2.0.tar.gz
## @end example
##
## @end table
## @seealso{ver, news}
## @end deftypefn


function varargout = pkj (varargin)
  opts = parse_inputs (varargin);

  if opts.help || isequal (opts.command, "help")
    help ("pkj");
    return
  endif
  
  # Check requirements
  if opts.forge
    if (! __octave_config_info__ ("CURL_LIBS"))
      error ("pkj: can't download from Octave Forge without the cURL library");
    endif
  endif

  # Do something
  switch opts.command
    case "install"
      install_type = detect_install_type (opts);
      switch install_type
        case "forge"
          rslt = install_forge_packages (opts);
        case "file"
          rslt = install_files (opts);
        otherwise
          error ("pkj: internal error: invalid install_type: '%s'", install_type);
      endswitch
      varargout = {rslt};
    case "list"
      if opts.forge
        if nargout == 0
          list_forge_packages (opts);
        else
          varargout = {list_forge_packages(opts)};
        endif
      else
        pkg_list_descs = list_installed_packages (opts);
        if nargout == 0
          display_pkg_desc_list (pkg_list_descs);
          list_non_installed_packages_on_path (pkg_list_descs, opts);
        else
          varargout = {pkg_list_descs};
        endif
      endif
    case "load"
      load_packages (opts);
    case "unload"
      unload_packages (opts)
    case "uninstall"
      uninstall_packages (opts);
    case "contents"
      list_package_contents (opts);
    case "test"
      test_packages (opts);
    case "describe"
      describe_packages (opts);
    case "depdiagram"
      show_depdiagram (opts);
    case "review"
      review_package (opts);
    case ""
      error ("pkj: you must supply a command");
    otherwise
      error ("pkj: the %s command is not yet implemented", opts.command);
  endswitch
  
  if nargout == 0
    clear varargout
  endif
endfunction

function install_type = detect_install_type (opts)
  if opts.forge
    install_type = "forge";
  elseif opts.file
    install_type = "file";
  else
    install_type = "forge";
    for i = 1:numel (opts.targets)
      if packajoozle.internal.Util.isfile (opts.targets{i})
        install_type = "file";
      endif
    endfor
  endif
endfunction

function out = install_forge_packages (opts)
  reqs = packajoozle.internal.OctaveForgeClient.parse_forge_targets (opts.targets);
  pkgman = packajoozle.internal.PkgManager;
  pkgman_opts.nodeps = opts.nodeps;
  if opts.devel
    out = pkgman.install_forge_pkgs_devel (reqs, [], pkgman_opts);
  else
    out = pkgman.install_forge_pkgs (reqs, [], pkgman_opts);
  endif
endfunction

function out = install_files (opts)
  files = opts.targets;
  pkgman = packajoozle.internal.PkgManager;
  out = pkgman.install_file_pkgs (files);
endfunction


function uninstall_packages (opts)
  pkgman = packajoozle.internal.PkgManager;
  reqs = packajoozle.internal.OctaveForgeClient.parse_forge_targets (opts.targets);
  inst_dir = ifelse (opts.global, "global", "user");
  pkgman.uninstall_packages (reqs);
endfunction

function out = list_forge_packages (opts)
  forge = packajoozle.internal.OctaveForgeClient;

  if opts.listversions
    if isempty (opts.targets)
      error ("pkj: you must supply a package name with 'list -forge -listversions'");
    elseif numel (opts.targets) > 1
      error ("pkj: only a single package name with 'list -forge -listversions' is allowed");
    else
      vers = forge.list_versions_for_package (opts.targets{1});
      if nargout == 0
        printf (strjoin (dispstrs (vers), "\n"));
        printf ("\n");
      else
        out = dispstrs (vers);
      endif
    endif
  else
    if nargout == 0
      puts ("Octave Forge provides these packages:\n");
      p = forge.list_all_releases;
      # Pick the latest one for each release
      p_names = unique (names (p));
      for i = 1:numel (p_names)
        p_i = p(strcmp (p_names, p_names{i}));
        [newest_ver, ix] = max (versions (p_i));
        printf ("  %s %s\n", p_names{i}, char (newest_ver));
      endfor
    else
      out = forge.list_forge_package_names;
    endif
  endif
endfunction

function list_non_installed_packages_on_path (pkg_list_descs, opts)
  dirs = strsplit (path, pathsep);
  inst_pkg_dirs = {};
  for i = 1:numel (pkg_list_descs)
    inst_pkg_dirs{end+1} = pkg_list_descs{i}.dir;
    inst_pkg_dirs{end+1} = pkg_list_descs{i}.archprefix;
  endfor
  inst_pkg_dirs = unique(inst_pkg_dirs);
  s.Name = {};
  s.Version = {};
  s.Dir = {};
  s.Status = {};
  for i = 1:numel (dirs)
    d_on_path = dirs{i};
    if strncmp (d_on_path, matlabroot, numel (matlabroot)) ...
      || ismember (d_on_path, inst_pkg_dirs)
      continue
    endif
    [d, last_el] = fileparts (d_on_path);
    if ! isequal (last_el, "inst")
      continue
    endif
    [~, dir_name] = fileparts (d);
    desc_file = fullfile (d, "DESCRIPTION");
    if ! exist (desc_file, "file")
      continue
    endif
    is_repo = packajoozle.internal.DistScmClient.looks_like_repo (d);
    status_str = "";
    if is_repo
      scm = packajoozle.internal.DistScmClient.client_for (d);
      status = get_status (scm);
      status_str = status.status_display;
    endif
    try
      desc = packajoozle.internal.PkgDistUtil.parse_pkg_description_file (desc_file);
      name = desc.name;
      version = desc.version;
    catch err
      name = "???";
      version = "???";
    end_try_catch
    s.Name{end+1} = name;
    s.Version{end+1} = version;
    s.Dir{end+1} = abbreviate_dir_path (d);
    s.Status{end+1} = status_str;
  endfor

  if ! isempty (s.Name)
    tbl = packajoozle.internal.qtable (s);
    fprintf ("\nNon-installed packages on Octave load path:\n");
    prettyprint (tbl, "B");
  endif

endfunction


function descs = list_installed_packages (opts)
  pkgman = packajoozle.internal.PkgManager;
  descs = pkgman.world.list_all_installed_packages ("desc");

  ## Add loaded state info
  p = strrep (path (), '\', '/');
  for i = 1:numel (descs)
    if (strfind (p, strrep (descs{i}.dir, '\', '/')))
      descs{i}.loaded = true;
    else
      descs{i}.loaded = false;
    endif
  endfor
endfunction

function display_pkg_desc_list (descs)
  if isempty (descs)
    printf ("pkj: no packages installed\n");
    return
  endif

  ## Compute the maximal lengths of name, version, and dir.
  name = cellfun (@(x) {x.name}, descs);
  name_with_load_indicator = name;
  for i = 1:numel (name)
    if descs{i}.loaded
      name_with_load_indicator{i} = [name_with_load_indicator{i} " *"];
    endif
  endfor
  s.PackageName = name_with_load_indicator;
  s.Version = cellfun (@(x) {x.version}, descs);
  s.InstallationDir = cellfun (@(x) {x.dir}, descs);

  s.InstallationDir = abbreviate_dir_path (s.InstallationDir);
  tbl = packajoozle.internal.qtable (s);
  tbl = sortrecords (tbl, [1 2]);
  tbl = tbl.remove_successive_duplicates;
  prettyprint (tbl, "B");
endfunction

function out = abbreviate_dir_path (dir)
  persistent home_dir = getenv("HOME");
  out = regexprep (dir, ["^" home_dir], "~");
  out = strrep (out, matlabroot, "<OCTAVE>");
endfunction

function out = load_packages (opts)
  pkgman = packajoozle.internal.PkgManager;
  pkgreqs = packajoozle.internal.OctaveForgeClient.parse_forge_targets (opts.targets);
  inst_descs = list_installed_packages (opts);
  inst_pkgvers = descs_to_pkgvers (inst_descs);
  matched = {};
  for i_pkgreq = 1:numel (pkgreqs)
    pkgreq = pkgreqs(i_pkgreq);
    tf = pkgreq.matches (inst_pkgvers);
    if ! any (tf)
      error ("pkj: no matching package installed: %s", char (pkgreq));
    endif
    matched{end+1} = inst_pkgvers(tf).newest;
  endfor
  matched = objvcat (matched{:});
  pkgman.load_packages (matched);
  # TODO: Different output and return value for packages that are already
  # loaded. The operation is idempotent, but the path taken may be relevant.
  printf ("pkj: loaded packages: %s\n", strjoin (dispstrs (matched), " "));
endfunction

function out = unload_packages (opts)
  pkgman = packajoozle.internal.PkgManager;
  pkgreqs = packajoozle.internal.OctaveForgeClient.parse_forge_targets (opts.targets);
  if isempty (pkgreqs)
    error ("pkj: unload: no packages specified\n");
  endif
  unloaded = pkgman.unload_packages (pkgreqs);
  if isempty (unloaded)
    printf ("pkj: no packages unloaded: no loaded packages matched request: %s\n", ...
      dispstr (pkgreqs));
  else
    printf ("pkj: unloaded: %s\n", strjoin (dispstrs (unloaded), ", "));
  endif
endfunction

function list_package_contents (opts)
  pkgreqs = packajoozle.internal.OctaveForgeClient.parse_forge_targets (opts.targets);
  pkgvers = installed_packages_matching (pkgreqs, opts);
  for i = 1:numel (pkgvers)
    list_package_contents_single (pkgvers(i), opts);
  endfor
endfunction

function list_package_contents_single (pkgver, opts)
  printf ("Package %s provides:\n", char (pkgver));
  pkgman = packajoozle.internal.PkgManager;
  descs = pkgman.world.descs_for_installed_package (pkgver);
  desc = descs{1};
  install_dir = desc.dir;
  index_file = fullfile (install_dir, "packinfo", "INDEX");
  disp (fileread (index_file));
endfunction

function test_packages (opts)
  #TODO: What to do about package loading? e.g. if io 2.3.1 is installed and loaded,
  # but a test of io 2.2.0 is requested?
  pkgman = packajoozle.internal.PkgManager;
  pkgreqs = packajoozle.internal.OctaveForgeClient.parse_forge_targets (opts.targets);
  pkgvers = installed_packages_matching (pkgreqs, opts);
  if isempty (pkgvers)
    error ("pkj: no matching packages installed");
  endif
  for i = 1:numel (pkgvers)
    pkgver = pkgvers(i);
    printf ("pkj: testing package %s\n", char (pkgver));
    descs = pkgman.world.descs_for_installed_package (pkgver);
    if isempty (descs)
      error ("pkj: not installed: %s", char (pkgver));
    endif
    if numel (descs) > 1
      # I just don't want to handle this case
      fprintf ("pkj: multiple installs exist of package %s; just testing the one in %s\n", ...
        char (pkgver), descs{1}.dir);
    endif
    desc = descs{1};
    # TODO: Check if package (and its dependencies) is loaded
    # Actual test code here
    dirs_to_test = {desc.dir};
    if ! isequal (desc.archprefix, desc.dir)
      dirs_to_test{end+1} = desc.archprefix;
    endif
    for i = 1:numel (dirs_to_test)
      runtests (dirs_to_test{i});
      # TODO: Add doctest support
    endfor
  endfor
endfunction

function review_package (opts)
  reviewer = packajoozle.internal.PkgReviewer;
  reviewer.verbose = opts.verbose;
  reviewer.fail_fast = opts.fail_fast;
  if ! isscalar (opts.targets)
    error ("pkj: review command takes exactly 1 target; got %d", ...
      numel (opts.targets));
  endif
  reviewer.review_package (opts.targets{1});
endfunction

function describe_packages (opts)
  if opts.forge
    describe_forge_packages (opts);
    return
  endif

  pkgman = packajoozle.internal.PkgManager;
  pkgreqs = packajoozle.internal.OctaveForgeClient.parse_forge_targets (opts.targets);
  if isempty (pkgreqs)
    pkgvers = pkgman.world.list_all_installed_packages;
  else
    pkgvers = installed_packages_matching (pkgreqs, opts);
  endif

  for i = 1:numel (pkgvers)
    pkgver = pkgvers(i);
    descs = pkgman.world.descs_for_installed_package (pkgver);
    desc = descs{1}; % aww, screw it
    display_package_description (desc);
  endfor
endfunction

function describe_forge_packages (opts)
  forge = packajoozle.internal.OctaveForgeClient;

  pkgreqs = packajoozle.internal.OctaveForgeClient.parse_forge_targets (opts.targets);
  pkgvers = latest_forge_packages_for_reqs (pkgreqs, opts);

  for i = 1:numel (pkgvers)
    pkgver = pkgvers(i);
    desc = forge.get_package_description (pkgver);
    display_package_description (desc);
  endfor
endfunction

function out = latest_forge_packages_for_reqs (pkgreqs, opts)
  c = {};
  for i = 1:numel (pkgreqs)
    ver = forge.get_latest_matching_pkg_version (pkgreqs(i));
    pkgver = packajoozle.internal.PkgVer (pkgreqs(i).package, ver);
    c{end+1} = pkgver;
  endfor
  out = objvcat (c{:});
endfunction

function display_package_description (desc)
  printf ("---\n");
  printf ("Package name:\n\t%s\n", desc.name);
  printf ("Version:\n\t%s\n", desc.version);
  printf ("Short description:\n%s\n", desc.description);
  printf ("\n");
endfunction

function show_depdiagram (opts)
  if opts.forge
    show_forge_depdiagram (opts);
  else
    error ("unimplemented");
    show_installed_depdiagram (opts);
  endif
endfunction

function out = show_forge_depdiagram (opts)
  forge = packajoozle.internal.OctaveForgeClient;
  pkgreqs = packajoozle.internal.OctaveForgeClient.parse_forge_targets (opts.targets);
  if isempty (pkgreqs)
    % That means everything!
    pkgvers = forge.list_all_current_releases;
  else
    pkgvers = latest_forge_packages_for_reqs (pkgreqs, opts);
  endif

  resolver = packajoozle.internal.DependencyResolver (forge);
  res = resolver.resolve_deps (pkgvers);
  dot = concrete_deps_to_dot (pkgvers, res.concrete_deps);
  printf ("DOT diagram:\n");
  printf ("%s\n", dot);
endfunction

function out = concrete_deps_to_dot (pkgvers, deps)
  nodes = {};
  edges = {};

  % Make sure each package is a node
  for i = 1:numel (pkgvers)
    nodes{end+1} = ['"' char (pkgvers(i)) '"'];
  endfor
  % Put in all the edges
  for i = 1:numel (deps)
    [a, b] = deal (deps{i}(1), deps{i}(2));
    edges{end+1} = sprintf ("\"%s\" -> \"%s\"", ...
      char (a), char (b));
  endfor
  % And make the file
  dot = ["digraph D {\n" ...
    strjoin(nodes, "\n") ...
    "\n" ...
    strjoin(edges, "\n") ...
    "\n"
  "}\n"];

  out = dot;
endfunction

function out = installed_packages_matching (pkgreqs, opts)
  pkgman = packajoozle.internal.PkgManager;
  inst_descs = list_installed_packages (opts);
  inst_pkgvers = descs_to_pkgvers (inst_descs);
  matched = {};
  for i_pkgreq = 1:numel (pkgreqs)
    pkgreq = pkgreqs(i_pkgreq);
    tf = pkgreq.matches (inst_pkgvers);
    if any (tf)
      matched{end+1} = inst_pkgvers(tf).newest;
    endif
  endfor
  matched = objvcat (matched{:});
  out = matched;
endfunction

function out = descs_to_pkgvers (descs)
  out = cell (size (descs));
  for i = 1:numel (descs)
    out{i} = packajoozle.internal.PkgVer (descs{i}.name, descs{i}.version);
  endfor
  out = objvcat (out{:});
endfunction

function opts = parse_inputs (args_in)
  opts = struct;
  opts.command = [];
  opts.targets = {};
  opts.forge = false;
  opts.file = false;
  opts.nodeps = false;
  opts.local = false;
  opts.global = false;
  opts.verbose = false;
  opts.devel = false;
  opts.listversions = false;
  opts.help = false;
  opts.fail_fast = false;

  valid_commands = {"install", "update", "uninstall", "load", "unload", "list", ...
    "describe", "prefix", "local_list", "global_list", "build", "rebuild", ...
    "help", "test", "contents", "depdiagram", "review"};
  valid_options = {"forge", "file", "nodeps", "local", "global", "forge", "verbose", ...
    "listversions", "help", "devel", "fail-fast"};
  aliases = {
    "ls"      "list"
    "rm"      "uninstall"
    "remove"  "uninstall"
    "-v"      "-verbose"
  };
  opt_flags = strcat("-", valid_options);

  args = args_in;

  command = [];
  for i = 1:numel (args)
    arg = args{i};
    [tf, loc] = ismember (arg, aliases(:,1));
    if tf
      arg = aliases{loc,2};
    endif
    if ismember (arg, opt_flags)
      opt = strrep (arg(2:end), "-", "_");
      opts.(opt) = true;
    else
      if arg(1) == "-"
        error ("pkj: invalid option: %s", args{i});
      endif
      if isempty (command)
        # First non-option arg is command
        command = arg;
      else
        # The rest are targets
        opts.targets{end+1} = arg;
      endif
    endif
  endfor

  if ! isempty (command) && ! ismember (command, valid_commands)
    error ("pkj: invalid command: %s. Valid commands are: %s", command, ...
      strjoin (valid_commands, ", "));
  endif
  opts.command = command;
endfunction
