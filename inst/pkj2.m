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
    otherwise
      error ("pkj2: the %s command is not yet implemented", opts.command);
  endswitch
  
endfunction

function install_forge_packages (opts)
  reqs = parse_forge_targets (opts.targets);
  pkgman = packajoozle.internal.PkgManager;
  pkgman.install_forge_pkgs (reqs);
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
