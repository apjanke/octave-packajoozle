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
    dot = "";
  endproperties

  methods

    function this = GraphVizDiagram (dot_txt)
      if nargin == 0
        return
      endif
      mustBeA (dot_txt, "char");
      this.dot = dot_txt;
    endfunction

    function out = view_in_figure (this)
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
      cmd = sprintf("dot -Tpng '%s' > '%s'", tmp_file, file);
      [status, output] = system (cmd);
      if status != 0
        error ("view_in_figure: error calling dot: %s\n", output);
      endif
    endfunction

  endmethods

endclassdef