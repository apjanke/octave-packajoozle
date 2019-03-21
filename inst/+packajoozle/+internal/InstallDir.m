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
  endproperties

  methods (Static)

    function out = get_user_installdir ()
      [prefix, arch_prefix] = pkg ("prefix");
      out = packajoozle.internal.InstallDir (prefix, arch_prefix, "user");
    endfunction

    function out = get_global_installdir ()
      [prefix, arch_prefix] = pkg ("prefix", "-global");
      out = packajoozle.internal.InstallDir (prefix, arch_prefix, "global");
    endfunction
    
  endmethods

  methods

    function this = InstallDir (prefix, arch_prefix, tag)
      if nargin == 0
        return
      endif
      if nargin < 2 || isempty (arch_prefix)
        arch_prefix = prefix;
      endif
      if nargin < 3 || isempty (tag)
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

    function out = install_path_for_pkg (this, pkgver)
      ver = char (pkgver.version);
      out.dir = fullfile (this.prefix, pkgver.name, ver);
      arch = packajoozle.internal.Util.get_system_arch;
      out.arch_dir = fullfile (this.arch_prefix, arch, pkgver.name, ver);
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

            
    
  endmethods

endclassdef