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
## @deftypefn {Function File} {out = } pkj2 (command, ...)
## Main Packajoozle package management command
##
## This is the command interface for Packajoozle. Its various options let you
## do all common package management operations.
##
## @end deftypefn

function out = pkj2 (varargin)
  opts = parse_inputs (varargin);

  switch opts.command
    case "install"
      if opts.forge
        install_forge_packages (opts);
      else
        install_files (opts);
      endif
    case "list"
      if opts.forge
        error ("unimplemented")
      else
        pkg_list_descs = list_installed_packages (opts);
        if nargout == 0
          display_pkg_desc_list (pkg_list_descs);
        else
          out = pkg_list_descs;
        endif
      endif
    otherwise
      error ("pkj2: the %s command is not yet implemented", opts.command);
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

function descs = list_installed_packages (opts)
  pkgman = packajoozle.internal.PkgManager;
  descs = pkgman.all_installed_packages_descs;

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


function opts = parse_inputs (args_in)
  opts = struct;
  opts.forge = false;
  opts.nodeps = false;
  opts.local = false;
  opts.global = false;
  opts.verbose = false;
  opts.targets = {};

  valid_commands = {"install", "update", "uninstall", "load", "unload", "list", ...
    "describe", "prefix", "local_list", "global_list", "build", "rebuild"};
  valid_options = {"forge", "nodeps", "local", "global", "forge", "verbose"};
  opt_flags = strcat("-", valid_options);

  args = args_in;
  opts.command = args{1};
  args(1) = [];
  if ! ismember (opts.command, valid_commands)
    error ("pkj2: invalid command: %s", opts.command);
  endif

  for i = 1:numel (args)
    if ismember (args{i}, opt_flags)
      opt = args{i}(2:end);
      opts.(opt) = true;
    else
      if args{i}(1) == "-"
        error ("pkj2: invalid option: %s", args{i});
      endif
      opts.targets{end+1} = args{i};
    endif
  endfor
endfunction
