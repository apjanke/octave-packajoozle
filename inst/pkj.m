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
## package directly (see the @file{DESCRIPTION} file of the package)
##
## The @var{option} variable can contain options that affect the manner
## in which a package is installed.  These options can be one or more of
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
## pkj install -forge io@2.4.9
## pkj install -forge symbolic@<=2.6.5
## pkj install -forge io statistics financial@0.5.1
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
## To update a single package use @code{pkj install -forge}
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
## It is possible to get the current value of local_list with the following
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
## It is possible to get the current value of global_list with the following
##
## @example
## pkj global_list
## @end example
##
## @item build
## Build a binary form of a package or packages.  The binary file produced
## will itself be an Octave package that can be installed normally with
## @code{pkj}.  The form of the command to build a binary package is
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
## @end table
## @seealso{ver, news}
## @end deftypefn


function out = pkj (varargin)
  opts = parse_inputs (varargin);

  # Check requirements
  if opts.forge
    if (! __octave_config_info__ ("CURL_LIBS"))
      error ("pkj: can't download from Octave Forge without the cURL library");
    endif
  endif

  # Do something
  switch opts.command
    case "install"
      if opts.forge
        install_forge_packages (opts);
      else
        install_files (opts);
      endif
    case "list"
      if opts.forge
        if nargout == 0
          list_forge_packages (opts);
        else
          out = list_forge_packages (opts);
        endif
      else
        pkg_list_descs = list_installed_packages (opts);
        if nargout == 0
          display_pkg_desc_list (pkg_list_descs);
        else
          out = pkg_list_descs;
        endif
      endif
    case "load"
      load_packages (opts);
    case "unload"
      unload_packages (opts)
    case "uninstall"
      uninstall_packages (opts);
    otherwise
      error ("pkj: the %s command is not yet implemented", opts.command);
  endswitch
  
endfunction

function install_forge_packages (opts)
  reqs = parse_forge_targets (opts.targets);
  pkgman = packajoozle.internal.PkgManager;
  pkgman.install_forge_pkgs (reqs);
endfunction

function install_files (opts)
  files = opts.targets;
  pkgman = packajoozle.internal.PkgManager;
  pkgman.install_file_pkgs (files);
endfunction

function out = parse_forge_targets (targets)
  if isempty (targets)
    out = [];
    return
  endif
  for i = 1:numel (targets)
    req = packajoozle.internal.PkgManager.parse_forge_target (targets{i});
    if i == 1
      out = req;
    else
      out = packajoozle.internal.Util.objcat (out, req);
    endif
  endfor
endfunction

function uninstall_packages (opts)
  pkgman = packajoozle.internal.PkgManager;
  reqs = parse_forge_targets (opts.targets);
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

function descs = list_installed_packages (opts)
  pkgman = packajoozle.internal.PkgManager;
  descs = pkgman.all_installed_packages ("desc");

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
  names = cellfun (@(x) {x.name}, descs);
  num_packages = numel (names);
  h1 = "Package Name";
  h2 = "Version";
  h3 = "Installation directory";
  max_name_length = max ([numel(h1), cellfun(@numel, names)]);
  version_lengths = cellfun (@(x) numel (x.version), descs);
  max_version_length = max ([numel(h2), version_lengths]);
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
  tmp = sprintf (repmat ("-", 1, numel (header) - 1));
  tmp(numel(h1) + 2) = "+";
  tmp(numel(h1) + numel(h2) + 5) = "+";
  printf ("%s\n", tmp);

  ## Print the packages.
  format = sprintf ("%%%ds %%1s| %%%ds | %%s\n",
                    max_name_length, max_version_length);
  for i = 1:num_packages
    cur_name = descs{i}.name;
    cur_version = descs{i}.version;
    cur_dir = descs{i}.dir;
    if (numel (cur_dir) > max_dir_length)
      first_char = numel (cur_dir) - max_dir_length + 4;
      first_filesep = strfind (cur_dir(first_char:end), filesep ());
      if (! isempty (first_filesep))
        cur_dir = ["..." cur_dir((first_char + first_filesep(1) - 1):end)];
      else
        cur_dir = ["..." cur_dir(first_char:end)];
      endif
    endif
    if (descs{i}.loaded)
      cur_loaded = "*";
    else
      cur_loaded = " ";
    endif
    printf (format, cur_name, cur_loaded, cur_version, cur_dir);
  endfor

endfunction

function out = load_packages (opts)
  pkgman = packajoozle.internal.PkgManager;
  pkgreqs = parse_forge_targets (opts.targets);
  inst_descs = list_installed_packages (opts);
  inst_pkgvers = descs_to_pkgvers (inst_descs);
  picked = {};
  for i_pkgreq = 1:numel (pkgreqs)
    pkgreq = pkgreqs(i_pkgreq);
    tf = pkgreq.matches (inst_pkgvers);
    if ! any (tf)
      error ("pkj: no matching package installed: %s", char (pkgreq));
    endif
    picked{end+1} = inst_pkgvers(tf).newest;
  endfor
  picked = packajoozle.internal.Util.objcat (picked{:});
  for i = 1:numel (picked)
    pkgman.load_package (picked(i));
  endfor
  printf ("pkj: loaded packages: %s\n", strjoin (dispstrs (picked), " "));
endfunction


function out = unload_packages (opts)
  pkgman = packajoozle.internal.PkgManager;
  pkgreqs = parse_forge_targets (opts.targets);
  unloaded = pkgman.unload_packages (pkgreqs);
  if isempty (unloaded)
    printf ("pkj: no packages unloaded: no loaded packages matched request: %s\n", ...
      dispstr (pkgreqs));
  else
    printf ("pkj: unloaded: %s\n", strjoin (dispstrs (unloaded), ", "));
  endif
endfunction

function out = descs_to_pkgvers (descs)
  out = cell (size (descs));
  for i = 1:numel (descs)
    out{i} = packajoozle.internal.PkgVer (descs{i}.name, descs{i}.version);
  endfor
  out = packajoozle.internal.Util.objcat (out{:});
endfunction

function opts = parse_inputs (args_in)
  opts = struct;
  opts.command = [];
  opts.forge = false;
  opts.nodeps = false;
  opts.local = false;
  opts.global = false;
  opts.verbose = false;
  opts.targets = {};
  opts.listversions = false;

  valid_commands = {"install", "update", "uninstall", "load", "unload", "list", ...
    "describe", "prefix", "local_list", "global_list", "build", "rebuild"};
  valid_options = {"forge", "nodeps", "local", "global", "forge", "verbose", ...
    "listversions"};
  opt_flags = strcat("-", valid_options);

  args = args_in;

  command = [];
  for i = 1:numel (args)
    if ismember (args{i}, opt_flags)
      opt = args{i}(2:end);
      opts.(opt) = true;
    else
      if args{i}(1) == "-"
        error ("pkj: invalid option: %s", args{i});
      endif
      if isempty (command)
        # First non-option arg is command
        command = args{i};
      else
        # The rest are targets
        opts.targets{end+1} = args{i};
      endif
    endif
  endfor

  if ! ismember (command, valid_commands)
    error ("pkj: invalid command: %s. Valid commands are: %s", command, ...
      strjoin (valid_commands, ", "));
  endif
  opts.command = command;
endfunction
