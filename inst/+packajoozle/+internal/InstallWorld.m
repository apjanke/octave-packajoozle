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
## @deftypefn {Class Constructor} {obj =} InstallWorld ()
##
## A set of named InstallPlaces.
##
## An InstallWorld represents the set of all InstallPlaces known to an
## Octave installation/session, and the set of packages in this "world".
##
## @end deftypefn

classdef InstallWorld < packajoozle.internal.IPackageMetaSource & handle

  properties (SetAccess = private)
    place_map = struct
    % Cellstr containing tags for this' instdirs
    search_order = {}
  endproperties

  properties
    % Default location for install/uninstall operations
    default_install_place = "user"
  endproperties

  methods (Static)

    function out = shared
      persistent instance = packajoozle.internal.InstallWorld.default;
      out = instance;
    endfunction

    function out = default ()
      % The default instdir world used by Octave; including "user" and "global"
      % InstallPlaces. This is the world seen by the original `pkg` utility.
      out = packajoozle.internal.InstallWorld;

      paths = packajoozle.internal.InstallWorld.default_paths;

      # Standard user place
      user_dir = packajoozle.internal.InstallPlace ("user", ...
        paths.user.prefix, paths.user.arch_prefix, paths.user.index_file);
      user_dir.package_list_var_name = "local_packages";
      out = out.register_install_place ("user", user_dir);

      # Standard global place
      global_dir = packajoozle.internal.InstallPlace ("global", ...
        paths.global.prefix, paths.global.arch_prefix, paths.global.index_file);
      #TODO: If global install location has been aliased to user install location,
      # this will break. Probably need to probe the package index file to see
      # what's there.
      global_dir.package_list_var_name = "global_packages";
      out = out.register_install_place ("global", global_dir);

      # User-defined custom place, if set in this Octave session
      [pfx,arch_pfx] = pkg('prefix');
      if ! ismember (pfx, {user_dir.prefix global_dir.prefix})
        # There's no `pkg` query to tell which index file is being used with the
        # custom prefix. I guess it'd be the local one?
        custom_dir = packajoozle.internal.InstallPlace ("custom", ...
          pfx, arch_pfx, paths.user.index_file);
        out = out.register_install_place ("custom", custom_dir);
        out.default_install_place = "custom";
      endif
    endfunction

    function out = default_paths
      out.global.prefix = fullfile (OCTAVE_HOME (), "share", "octave", "packages");
      out.global.arch_prefix = fullfile (__octave_config_info__ ("libdir"), "octave",
                             "packages");
      out.global.index_file = fullfile (OCTAVE_HOME (), "share", "octave",
                                     "octave_packages");
      out.user.prefix = tilde_expand (fullfile ("~", "octave"));
      out.user.arch_prefix = out.user.prefix;
      out.user.index_file = tilde_expand (fullfile ("~", ".octave_packages"));
    endfunction
  endmethods

  methods

    function this = InstallWorld ()
      if nargin == 0
        return
      endif
    endfunction

    function set.default_install_place (this, place)
      if ! ismember (place, this.tags)
        error ("InstallWorld: set.default_install_place: not a defined place: %s", place);
      endif
      this.default_install_place = place;
    endfunction

    function out = disp (this)
      if isscalar (this)
        str = {sprintf("%s: %s (default=%s)", class(this), ...
          strjoin(this.search_order, ", "), this.default_install_place)};
        for i_tag = 1:numel (this.search_order)
          tag = this.search_order{i_tag};
          place = this.get_installdir_by_tag (tag);
          str = [str; {
            ["  " tag ":"]
            sprintf("    prefix: %s", place.prefix)
            sprintf("    arch_prefix: %s", place.arch_prefix)
            sprintf("    index_file: %s", place.index_file)
            sprintf("    default package_list_var_name: %s", place.package_list_var_name)
            sprintf("    actual package_list_var_name: %s", place.actual_package_list_var_name)
          }];
        endfor
        printf("%s\n", strjoin (str, "\n"));
      else
        disp (dispstr (this));
      endif
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
        o = this(i);
        out{i} = sprintf("[%s: %s]", class (o), strjoin (o.tags, ", "));
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

    function this = register_install_place (this, tag, place)
      mustBeA (place, "packajoozle.internal.InstallPlace");
      if ! isequal (tag, place.tag)
        error ("inconsistent tags: %s vs %s", tag, place.tag);
      endif
      if ismember (tag, this.search_order)
        warning ("pkj: replacing existing install place '%s' with %s\n", ...
          tag, place.prefix);
      else
        this.search_order{end+1} = tag;
      endif
      this.place_map.(tag) = place;
    endfunction

    function out = tags (this)
      out = this.search_order;
    endfunction

    function out = get_installdir_by_tag (this, tag)
      if ! ismember (tag, this.search_order)
        error ("InstallWorld.get_installdir_by_tag: no such instdir: '%s'", tag);
      endif
      out = this.place_map.(tag);
    endfunction

    function out = get_all_installdirs (this)
      c = {};
      for i = 1:numel (this.search_order)
        c{i} = this.place_map.(this.search_order{i});
      endfor
      out = objvcat (c{:});
    endfunction

    function out = list_installed_packages (this, format = "pkgver")
      # Returns list as PkgVers
      places = this.get_all_installdirs;
      switch format
        case "pkgver"
          out = places(1).get_package_list;
          for i = 2:numel (places)
            out = objvcat (out, places(i).get_package_list);
          endfor
        case "desc"
          out = places(1).get_package_list_descs;
          out = this.decorate_descs (out, places(1).tag);
          for i = 2:numel (places)
            descs = places(i).get_package_list_descs;
            descs = this.decorate_descs (descs, places(i).tag);
            out = [out descs];
          endfor
        otherwise
          error ("InstallWorld.list_installed_packages: invalid format: '%s'", format);
      endswitch
    endfunction
    
    function descs = decorate_descs (this, descs, place)
      for i = 1:numel (descs)
        descs{i}.place = place;
      endfor      
    endfunction

    function out = descs_for_installed_package (this, pkgver)
      descs = this.list_installed_packages ("desc");
      out = {};
      for i = 1:numel (descs)
        desc = descs{i};
        desc_pkgver = packajoozle.internal.PkgVer (desc.name, desc.version);
        if desc_pkgver == pkgver
          out{end+1} = desc;
        endif
      endfor
    endfunction

    function out = is_installed (this, pkgvers)
      pkgver = makeItBeA (pkgvers, "packajoozle.internal.PkgVer");
      out = false (size (pkgvers));
      installdirs = this.get_all_installdirs;
      for i_pkg = 1:numel (pkgvers)
        pkgver = pkgvers(i_pkg);
        for i_dir = 1:numel (installdirs)
          if installdirs(i_dir).is_installed (pkgver)
            out(i_pkg) = true;
            break;
          endif
        endfor
      endfor
    endfunction

    function [out, unmatched_reqs] = list_installed_matching (this, pkgreqs)
      [out, unmatched_reqs] = this.list_available_packages_matching (pkgreqs);
    endfunction

    % IPackageMetaSource implementation

    function out = list_available_packages (this)
      out = this.list_installed_packages;
    endfunction

    function out = get_package_description (this, pkgver)
      pkgver = makeItBeA(pkgver, "packajoozle.internal.PkgVer");
      descs = this.descs_for_installed_package (pkgver);
      if isempty (descs)
        error ("InstallWorld.get_package_description: package not installed: %s", ...
          char (pkgver));
      endif
      out = descs{1};
    endfunction

    function out = loaded_packages (this)
      places = this.get_all_installdirs;
      out = {};
      for i = 1:numel (places)
        place = places(i);
        out{i} = place.loaded_packages;
      endfor
      out = unique (objvcat (out{:}));
    endfunction

    function out = is_loaded (this, pkgvers)
      pkgvers = makeItBeA ("packajoozle.internal.PkgVer");
      out = false (size (pkgvers));
      places = this.get_all_installdirs;
      for i = 1:numel (places)
        out = out | places(i).is_loaded (pkgvers);
      endfor
    endfunction

    function out = load_packages (this, pkgvers)
      mustBeA (pkgvers, "packajoozle.internal.PkgVer");
      installed = this.list_installed_packages;
      missing = setdiff (pkgvers, installed);
      if ! isempty (missing)
        error ("pkj: cannot load packages: not installed: %s\n", dispstr (missing));
      endif
      # TODO: Resolve dependencies, add deps, and choose a load order based on dependencies
      fprintf ("pkj: loading: %s\n", dispstr (pkgvers));
      places = this.get_all_installdirs;
      for i_pkg = 1:numel (pkgvers)
        pkgver = pkgvers(i_pkg);
        found = false;
        for i_place = 1:numel (places)
          if places(i_place).is_installed (pkgver)
            places(i_place).load_package (pkgver);
            found = true;
            break
          endif
        endfor
        if ! found
          error ("pkj: internal error: couldn't actually find installation for %s", pkgver);
        endif
      endfor
    endfunction

    function [out, unmatched_reqs] = load_packages_matching (this, pkgreqs)
      pkgreqs = makeItBeA (pkgreqs, "packajoozle.internal.PkgVerReq");
      printf ("pkj: load: looking for packages matching: %s\n", dispstr (pkgreqs));
      # TODO: Handle dependencies
      [pkgvers, unmatched_reqs] = this.list_installed_matching (pkgreqs);
      if ! isempty (unmatched_reqs)
        error ("pkj: load: no matching packages installed: %s\n", ...
          strjoin (dispstrs (unmatched_reqs), ", "));
      endif
      this.load_packages (pkgvers);
      out = pkgvers;
    endfunction

    function out = unload_packages (this, pkgvers)
      # TODO: Handle dependencies. Packages should be unloaded in reverse
      # dependency order.
      unloaded = {};
      places = this.get_all_installdirs;
      for i = 1:numel (place)
        place = places(i);
        tf = place.is_loaded (pkgvers);
        place.unload_packages (pkgvers(tf));
        unloaded{end+1} = pkgvers(tf);
      endfor
      unloaded = unique(objvcat (unloaded{:}));
      printf ("pkj: unloaded: %s", dispstr (unloaded));
      out.unloaded = unloaded;
      out.not_loaded_in_the_first_place = setdiff (pkgvers, unloaded);
    endfunction

    function out = unload_matching (this, pkgreqs)
      installed = this.list_installed_matching (pkgreqs);
      loaded = installed(this.is_loaded (installed));
      out = this.unload_packages (loaded);
    endfunction

    function out = uninstall_packages_matching (this, pkgreqs, place_name)
      # This method lives on World, and not InstallPlace, so it can detect dependency
      # breakage considering packages left in all places, not just the one where
      # uninstallation is happening.
      # TODO: Support uninstallation across multiple places at the same time
      # TODO: Dependency ordering.
      narginchk(3, 3);
      pkgreqs = makeItBeA (pkgreqs, "packajoozle.internal.PkgVerReq");
      place = this.get_installdir_by_tag (place_name);
      pkgvers = place.list_packages_matching (pkgreqs);
      if any (place.is_loaded (pkgvers))
        place.unload_packages (pkgvers);
      endif
      place.uninstall_packages (pkgvers);
    endfunction

  endmethods

endclassdef