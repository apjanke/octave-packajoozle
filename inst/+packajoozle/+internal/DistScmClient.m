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
## @deftypefn {Class Constructor} {obj =} DistScmClient ()
##
## Abstract base class for distributed SCM (Source Control Management)
## tools. 
##
## This is designed based on Git and Mercurial's models; it may not
## be appropriate for other SCMs. This is a basic client; it only supports
## the operations needed for pkj's operation.
##
## @end deftypefn

## Author:  Andrew Janke

classdef DistScmClient

  properties
    
  endproperties

  methods (Static)

    function out = client_for (local_repo_path)
      if exist (fullfile (local_repo_path, ".git"), "dir")
        out = packajoozle.internal.GitClient (local_repo_path);
      elseif exist (fullfile (local_repo_path, ".hg"), "dir")
        out = packajoozle.internal.HgClient (local_repo_path);
      else
        error ("Dir is not a Git or Hg repo: %s", local_repo_path);
      endif
    endfunction

    function out = looks_like_repo (path)
      out = exist (fullfile (path, ".git"), "dir") || exist (fullfile (path, ".hg"), "dir");
    endfunction
    
  endmethods
  
  methods

    function this = DistScmClient ()
      if nargin == 0
        return
      endif
    endfunction

  endmethods

endclassdef