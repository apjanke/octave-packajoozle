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
## @deftypefn {Class Constructor} {obj =} DependencyDiagrammer ()
##
## Creates diagrams of dependency relationships.
##
## A class for generating diagrams of dependency relationships between 
## Octave packages. Can work on Octave Forge published releases, or locally
## installed packages.
##
## @end deftypefn

## Author:  Andrew Janke

classdef DependencyDiagrammer

  properties
    #meta_source
  endproperties

  methods

    function this = DependencyDiagrammer (meta_source)
      if nargin == 0
        return
      endif
      if nargin < 1; meta_source = [];  endif
      #if isempty (meta_source)
      #  pkgman = packajoozle.internal.PkgManager;
      #  meta_source = pkgman.world;
      #endif
      #this.meta_source = meta_source;
    endfunction

    function out = diagram_forge_deps (this, pkgreqs, opts)
      if nargin < 2; pkgreqs = []; endif
      if nargin < 3; opts = []; endif
      opts = packajoozle.internal.Util.parse_options (opts, struct(...
        "include_losers", false));

      forge = packajoozle.internal.OctaveForgeClient;
      if isempty (pkgreqs)
        pkgvers = forge.list_all_current_releases;
      else
        error ("Specifying pkgreqs is not supported yet.");
      endif

      % Get dependency graph
      nodes = {};
      graph = cell (0, 3);

      for i_pkg = 1:numel (pkgvers)
        pkgver = pkgvers(i_pkg);
        nodes{end+1} = pkgver.name;
        desc = forge.get_package_description (pkgver);
        reqs = packajoozle.internal.PkgVerReq.parse_desc_deps (desc.depends);
        for i_req = 1:numel (reqs)
          % Just ignore the versions for now
          if isequal (reqs(i_req).package, "octave")
            continue
          endif
          graph(end+1,:) = {pkgver.name, reqs(i_req).package, reqs(i_req)};
        endfor
      endfor

      % Generate DOT
      no_deps = setdiff (nodes, [graph(:,1); graph(:,2)]);
      dot = {};
      function d (varargin)
        dot{end+1} = sprintf(varargin{:});
      endfunction
      d ("digraph pkg_dependencies {")
      d ("graph [")
      d ('  label = "\n\nOctave Forge Dependencies\n%s",', datestr(now))
      d ('  overlap = false')
      d ("];")
      d ("node [")
      d ("  shape = box")
      d ("];")
      if opts.include_losers
        d ("  subgraph losers {")
        for i = 1:numel (no_deps)
          d ('    "%s";', no_deps{i})
        endfor
        d ("  }")
      endif
      for i = 1:size (graph, 1)
        d ('  "%s" -> "%s";', graph{i,1}, graph{i,2});
      endfor
      d ("}")

      dot = strjoin (dot, "\n");
      out = packajoozle.internal.GraphVizDiagram (dot);
      out.layout = "neato";

    endfunction
  endmethods

endclassdef