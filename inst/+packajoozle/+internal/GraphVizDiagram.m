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
## @deftypefn {Class Constructor} {obj =} GraphVizDiagram (dot_txt)
##
## A GraphViz diagram
##
## Holds a GraphViz diagram definition in the DOT language, and knows how to
## do some display and export of it. Requires GraphViz be installed on your
## machine.
##
## @end deftypefn

## Author:  Andrew Janke

classdef GraphVizDiagram

  properties
    % The graph definition, in GraphViz DOT language, as a char
    dot = "";

    layout = "dot";

  endproperties

  methods (Static)

    function out = graphviz_plugin_diagram ()
      dot = packajoozle.internal.Util.system ("dot -P -Tdot");
      dot = strrep (dot, 'rankdir=LR,', 'rankdir=LR, overlap=false,');
      out = packajoozle.internal.GraphVizDiagram (dot);
    endfunction

  endmethods

  methods

    function this = GraphVizDiagram (dot_txt)
      if nargin == 0
        return
      endif
      this.dot = dot_txt;
    endfunction

    function this = set.layout (this, layout)
      valid_layouts = {"dot" "neato" "twopi" "circo" "fdp" "sfdp" "patchwork" "osage"};
      if ! ismember (layout, valid_layouts)
        error ("GraphVizDiagram.set.layout: invalid layout: %s", layout);
      endif
      this.layout = layout;
    endfunction

    function this = set.dot (this, dot)
      mustBeCharVec (dot, "char");
      this.dot = dot;
    endfunction

    function disp (this)
      disp (dispstr (this));
    endfunction

    function out = dispstr (this)
      if isscalar (this)
        strs = dispstrs (this);
        out = strs{1};
      else
        out = sprintf ("%s %s", size2str (size (this)), class (this));
      endif
    endfunction

    function out = dispstrs (this)
      out = cell (size (this));
      for i = 1:numel (this)
        out{i} = sprintf ("%s: %d bytes of DOT, layout=%s", ...
          class (this), numel (this.dot), this.layout);
      endfor
    endfunction

    function out = char (this)
      if ! isscalar (this)
        error ("%s: char() only works on scalar %s objects; this is %s", ...
          class (this), class (this), size2str (size (this)));
      endif
      strs = dispstrs (this);
      out = strs{1};
    endfunction


    function out = imshow (this)
      tmp_file = [tempname(tempdir, "packajoozle/graphviz/work-") ".png"];
      # Can't do this? imshow is too slow on the uptake?
      RAII.tmp_file = onCleanup (@() packajoozle.internal.Util.rm_rf (tmp_file));
      this.export_to_file (tmp_file);
      out = imshow (tmp_file);
      if nargout == 0
        clear out
      endif
    endfunction

    function export_to_file (this, file)
      tmp_file = [tempname(tempdir, "packajoozle/graphviz/work-") ".gv"];
      RAII.tmp_file = onCleanup (@() packajoozle.internal.Util.rm_rf (tmp_file));
      packajoozle.internal.Util.filewrite (tmp_file, this.dot);
      cmd = sprintf("dot -K%s -Tpng '%s' > '%s'", this.layout, tmp_file, file);
      [status, output] = system (cmd);
      if status != 0
        error ("GraphVizDiagram.export_to_file: error calling dot: %s\n", output);
      endif
    endfunction

  endmethods

endclassdef