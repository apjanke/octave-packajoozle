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
## @deftypefn {Class Constructor} {obj =} DependencyResolver ()
##
## Dependency resolution logic
##
## This class provides support for resolving dependencies between classes,
## given an external IPackageMetaSource from which to get their package
## metadata, including dependency declarations.
##
## @end deftypefn

classdef DependencyResolver

  properties
    verbose = false
    ignored_special_pseudopackages = {"octave"}
    meta_source = packajoozle.internal.NullPackageMetaSource
  endproperties

  methods

    function this = DependencyResolver (meta_source)
      if nargin == 0
        return
      endif
      mustBeA (meta_source, "packajoozle.internal.IPackageMetaSource");
      this.meta_source = meta_source;      
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
        out{i} = sprintf ("[%s: meta_source=%s, verbose=%d, ignored_special_pseudopackages=%s]", ...
          dispstr (this.meta_source), this.verbose, strjoin (this.ignored_special_pseudopackages, ", "));
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

    function out = resolve_deps (this, pkgvers, opts)
      %RESOLVE_DEPS Resolves dependencies for a set of packages
      %
      % Restrictions: this' meta_source must contain metadata for all the packages
      % in the original pkgvers, in addition to whater it may supply for
      % dependency resolution. This will cause a problem for trying to resolve
      % dependencies for packages installed from files.
      %
      % Returns a struct with fields
      %   ok - (logical) whether all dependencies were resolved successfully
      %   resolved - (PkgVer) resolved install/load order for all packages, including
      %        added dependencies
      %   added_deps - (PkgVer) packages that were not in the original list
      %        that were added due to dependencies
      %   error_msgs - (cellstr) list of messages describing resolution failures
      %   concrete_deps - (cell of [PkgVer, PkgVer]) - the concrete resolved dependencies
      %        in the solved graph.

      % This uses a naive algorithm that only considers dependencies one at a time,
      % and just picks the newest version of a package that satisfies a given dependency,
      % hoping that that will also satisfy subsequent dependencies on the same
      % package. Really what it ought to do is take all the dependencies together
      % as a whole, add resolved dependencies one at a time, incrementally adding _their_
      % dependencies to the entire dependency set, and re-evaluate, with possible
      % back-tracking on the resolved added dependencies, to handle the case of
      % an indirect dependency adding a more-restrictive version filter onto an already-
      % resolved dependency. That probably means creating a smart DependencySet object
      % that represents a set of PkgVerReqs, with subsumation and calculation of
      % outstanding dependencies. (Or maybe that just gets built into the state of
      % DependencyResolver.)

      narginchk (2, 3);
      if nargin < 3 || isempty (opts); opts = struct; endif
      pkgvers = makeItBeA (pkgvers, "packajoozle.internal.PkgVer");

      order = [];
      added_deps = [];
      error_msgs = {};
      concrete_deps = {};

      avail = this.meta_source.list_available_packages;
      to_go = pkgvers;
      dep_path = [];  % current path in the graph traversal we're doing

      function ok = step (p)
        if ismember (p, dep_path)
          cycle_path = objvcat (dep_path, p);
          this.emit ("dependency cycle detected: %s", dep_path_str (cycle_path));
          ok = false;
          error_msgs{end+1} = sprintf ("dependency cycle: %s", ...
            dep_path_str (cycle_path));
          return
        endif
        dep_path = objvcat (dep_path, p); % push
        unwind_protect
          desc = this.meta_source.get_package_description_meta (p);
          deps = get_deps_as_pkgreqs (desc);
          this.emit ("working %s (%s)\n  deps: %s", char (p), ...
            dep_path_str (dep_path), pkgreqs_to_char (deps));
          if ! isempty (order) && ismember (p, order)
            this.emit ("already in order: %s", char (p));
            ok = true;
            return
          endif
          for i = 1:numel (deps)
            dep = deps(i);
            this.emit ("  considering dep: %s", char (dep));
            % Ignore special dependencies
            if ismember (dep.package, this.ignored_special_pseudopackages)
              this.emit ("    ignoring pseudopackage dependency %s", char (dep));
              continue;
            endif
            % Already in resolved packages?
            ix = find (dep.matches (order));
            if ! isempty (ix)
              this.emit ("    already satisfied by already-resolved pkg order (%s)", ...
                dispstr (order(tf)));
              concrete_deps{end+1} = objvcat (p, order(ix(1)));
              continue;
            end
            % In our request list?
            ix = find (dep.matches (to_go));
            if ! isempty (ix)
              this.emit ("    satisfied by requested package %s; pulling that one up", ...
                char (to_go(ix(1))));
              do_this_next = to_go(ix(1));
              to_go = objdel (to_go, ix(1));
              concrete_deps{end+1} = objvcat (p, do_this_next);
              step (do_this_next);
              continue
            endif
            % Available in source?
            ix = find (dep.matches (avail));
            if ! isempty (ix)
              candidates = avail(ix);
              picked = newest (candidates);
              this.emit ("    satisfied by package found in source: %s; adding dep", char (picked));
              added_deps = objvcat (added_deps, picked);
              concrete_deps{end+1} = objvcat (p, picked);
              step (picked);
              continue
            endif
            % Couldn't satisfy
            this.emit ("    could not be satisfied!");
            error_msgs{end+1} = sprintf("unsatisfied dependency: %s, required by %s", ...
              char (dep), char (p));
            ok = false;
            return
          endfor
          order = objvcat (order, p);
          ok = true;
        unwind_protect_cleanup
          dep_path = dep_path(1:numel (dep_path)-1); % pop
        end_unwind_protect
      endfunction

      ok = true;
      while ! isempty (to_go)
        next_up = to_go(1);
        to_go = to_go(2:end);
        ok = step (next_up);
        if ! ok
          break
        endif
      endwhile

      out.ok = ok;
      out.resolved = order;
      out.added_deps = added_deps;
      out.error_msgs = error_msgs;
      out.concrete_deps = concrete_deps;
    endfunction

    function emit (this, fmt, varargin)
      if this.verbose
        fprintf (["DependencyResolver: " fmt "\n"], varargin{:});
      endif
    endfunction

  endmethods

endclassdef

function out = dep_path_str (dep_path)
  if isempty (dep_path)
    out = "[]";
  else
    out = ["[" strjoin(dispstrs(dep_path), " -> ") "]"];
  endif
endfunction

function out = get_deps_as_pkgreqs (desc)
  if ! isfield (desc, "depends")
    out = [];
    return
  endif
  if isempty (desc.depends)
    out = [];
    return
  endif
  out = {};
  for i = 1:numel (desc.depends)
    d = desc.depends{i};
    out{i} = packajoozle.internal.PkgVerReq (d.package, ...
      packajoozle.internal.VerFilter (d.version, d.operator));
  endfor 
  out = objvcat (out{:});
endfunction

function out = pkgreqs_to_char (pkgreqs)
  if isempty (pkgreqs)
    out = "<none>";
  else
    out = strjoin (dispstrs (pkgreqs), "; ");
  endif
endfunction

function out = objappend (list, varargin)
  if isempty (list)
    out = varargin{1};
  else
    out = list;
    out(end+1) = varargin{1};
  endif
  for i = 2:numel (varargin)
    out(end+1) = varargin{i};
  endfor
endfunction

