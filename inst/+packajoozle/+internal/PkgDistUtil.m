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
## @deftypefn {Class Constructor} {obj =} PkgDistUtil ()
##
## Package distribution utilities
##
## This class contains methods that know how to work with an Octave pkg
## formatted package distribution archive.
##
## @end deftypefn

## Author:  

classdef PkgDistUtil

  methods (Static)

    function [out, descr_txt] = get_pkg_description_from_pkg_archive_file (file)
      % Extracts the DESCRIPTION info from a package distro tarball file
      tmp_dir = tempname (tempdir, "packajoozle/PkgDistUtil/pkg-archive-work-");
      RAII.tmp_dir = onCleanup (@() packajoozle.internal.Util.rm_rf (tmp_dir));
      packajoozle.internal.Util.mkdir (tmp_dir);
      unpack (file, tmp_dir);
      kids = packajoozle.internal.Util.readdir (tmp_dir);
      if numel (kids) > 1
        error ("pkj: Multiple top-level directories found in pkg file: %s", file);
      endif
      subdir = fullfile (tmp_dir, kids{1});
      descr_file = fullfile (subdir, "DESCRIPTION");
      if ! packajoozle.internal.Util.isfile (descr_file)
        error ("pkj: Pkg file does not contain a DESCRIPTION file: %s", file);
      endif
      out = packajoozle.internal.PkgDistUtil.parse_pkg_description_file (descr_file);
      if nargout > 1
        descr_txt = fileread (descr_file);
      endif
    endfunction

    function out = parse_pkg_description_file (descr_source, format = "file")
      % Returns a struct with standard packge description fields
      switch format
        case "file"
          descr_txt = fileread (descr_source);
          file = descr_source;
        case "string"
          descr_txt = descr_source;
          file = "<string>";
        otherwise
          error ("PkgDistUtil.parse_pkg_description_file: invalid format: %s", format);
      end
      desc = struct ();

      lines = regexp (descr_txt, "\r?\n", "split");
      if isempty (lines{end})
        lines(end) = [];
      endif

      for i = 1:numel (lines)
        line = chomp (lines{i});
        if isempty (line)
          ## Ignore empty lines
        elseif (line(1) == "#")
          ## Comments, do nothing.
        elseif (isspace (line(1)))
          ## Continuation lines
          if (exist ("keyword", "var") && isfield (desc, keyword))
            desc.(keyword) = [desc.(keyword) " " deblank(line)];
          endif
        else
          ## Keyword/value pair
          colon = find (line == ":");
          if (length (colon) == 0)
            warning (["pkj: skipping invalid line %d in DESCRIPTION:\n" ...
              "  File: %s\n  Line: %s\n"], i, file, line);
          else
            colon = colon(1);
            keyword = tolower (strtrim (line(1:colon-1)));
            value = strtrim (line (colon+1:end));
            if (length (value) == 0)
                fclose (fid);
                error ("pkj: The keyword '%s' of the package '%s' DESCRIPTION has an empty value\n",
                        keyword, desc.name);
            endif
            if (isfield (desc, keyword))
              warning (["pkj: duplicate keyword '%s' in DESCRIPTION, ignoring\n" ...
                "  File %s\n  Line number: %d\n"], ...
                       keyword, file, i);
            else
              desc.(keyword) = value;
            endif
          endif
        endif
      endfor

      ## Make sure all is okay.
      needed_fields = {"name", "version", "date", "title", ...
                       "author", "maintainer", "description"};
      for f = needed_fields
        if (! isfield (desc, f{1}))
          error (["pkj: DESCRIPTION is missing needed field %s\n" ...
            "  File: %s\n"], f{1}, file);
        endif
      endfor

      if (! packajoozle.internal.Util.is_valid_pkg_version_string (desc.version))
        error (["pkj: invalid version string in DESCRIPTION: '%s'\n" ...
          "  File: %s\n"], desc.version, file);
      endif

      if (isfield (desc, "depends"))
        desc.depends = fix_depends (desc.depends);
      else
        desc.depends = "";
      endif
      desc.name = tolower (desc.name);
      out = desc;
    endfunction

  endmethods

endclassdef

function out = chomp (str)
  out = regexprep (str, "\r?\n$", "");
endfunction

## This is copied from the original pkg implementation.
##
## Make sure the depends field is of the right format.
## This function returns a cell of structures with the following fields:
##   package, version, operator
function deps_cell = fix_depends (depends)

  deps = strtrim (ostrsplit (tolower (depends), ","));
  deps_cell = cell (1, length (deps));
  dep_pat = ...
  '\s*(?<name>[-\w]+)\s*(\(\s*(?<op>[<>=]+)\s*(?<ver>\d+\.\d+(\.\d+)*)\s*\))*\s*';

  ## For each dependency.
  for i = 1:length (deps)
    dep = deps{i};
    [start, nm] = regexp (dep, dep_pat, 'start', 'names');
    ## Is the dependency specified
    ## in the correct format?
    if (! isempty (start))
      package = tolower (strtrim (nm.name));
      ## Does the dependency specify a version
      ## Example: package(>= version).
      if (! isempty (nm.ver))
        operator = nm.op;
        if (! any (strcmp (operator, {">", ">=", "<=", "<", "=="})))
          error ("pkj: unsupported operator in dependency: %s", operator);
        endif
        if (! packajoozle.internal.Util.is_valid_pkg_version_string (nm.ver))
          error ("pkj: invalid version string in dependency: '%s'", nm.ver);
        endif
      else
        ## If no version is specified for the dependency
        ## we say that the version should be greater than
        ## or equal to "0.0.0".
        package = tolower (strtrim (dep));
        operator = ">=";
        nm.ver  = "0.0.0";
      endif
      deps_cell{i} = struct ("package", package,
                             "operator", operator,
                             "version", nm.ver);
    else
      error ("pkj: incorrect syntax for dependency '%s' in the DESCRIPTION file\n",
             dep);
    endif
  endfor

endfunction

