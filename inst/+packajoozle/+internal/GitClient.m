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
## @deftypefn {Class Constructor} {obj =} GitClient (local_repo_path)
##
## A client for the git SCM.
##
## 
##
## @end deftypefn

## Author:  Andrew Janke

classdef GitClient

  properties
    repo_path
  endproperties

  methods

    function this = GitClient (local_repo_path)
      if nargin == 0
        return
      endif
      if ! exist (fullfile (local_repo_path, ".git"))
        error ("Not a git repo: %s", local_repo_path);
      endif
      this.repo_path = local_repo_path;
    endfunction

    function pull (this)
      RAII.cd = packajoozle.internal.Util.local_cd_change (this.repo_path);
      packajoozle.internal.Util.system ("git pull");
    endfunction

    function out = get_status (this)
      cmd = sprintf ("git -C '%s' status --porcelain", this.repo_path);
      [exit_code, txt] = system (cmd); % Non-zero exit status does not mean error!
      lines = regexp (txt, "\r?\n", "split");
      out.file = {};
      out.status = {};
      out.status_display = "";
      if ! isempty (txt)
        for i = 1:numel (lines)
          line = lines{i};
          if isempty (line)
            continue
          endif
          out.file{i} = line(4:end);
          out.status{i} = line(1:2);
        endfor
      endif
      out.status_display = status_display_str (out.status);
    endfunction
  endmethods

endclassdef

function out = status_display_str (status)
  out = "";
  if ismember (" M", status)
    out(end+1) = "*";
  endif
  if ismember ("??", status)
    out(end+1) = "+";
  endif
  others = setdiff(status, {" M", "??"});
  if ! isempty (others)
    out(end+1) = "?";
  endif
endfunction
