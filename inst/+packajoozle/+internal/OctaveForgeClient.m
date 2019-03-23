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
## @deftypefn {Class Constructor} {obj =} OctaveForgeClient ()
## Octave Forge client.
##
## A client for getting directory info, package metadata, and package
## distribution downloads from Octave Forge.
##
## @end deftypefn

classdef OctaveForgeClient < packajoozle.internal.IPackageMetaSource

  properties
    % How long to keep cached metadata for, as datenum
    cached_meta_ttl = (1 * 60 * 60) / (60 * 60 * 24)
    % Download cache directory
    download_cache_dir = fullfile (packajoozle.internal.Util.packajoozle_data_dir, ...
      "download-cache", "octave-forge");
    % Base URL for Octave Forge
    forge_url = "https://packages.octave.org"
  endproperties

  methods

    function this = OctaveForgeClient ()
      if nargin == 0
        return
      endif
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
        out{i} = sprintf ("[%s: forge_url=%s, cached_meta_ttl=%.6f, download_cache_dir=%s]", ...
          class (this), this.forge_url, this.cached_meta_ttl, this.download_cache_dir);
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


    function out = get_cached_package_download (this, pkg_name)
      % Download package distribution file, caching downloads.
      % Returns path to the cached downloaded file.
      info = this.get_forge_download_info (pkg_name);
      [url, local_file] = deal (info.url, info.local_file);
      local_basename = packajoozle.internal.Util.basename (local_file);
      cached_file = fullfile (this.download_cache_dir, local_basename);
      out = cached_file;
      if exist (cached_file, "file")
        return
      endif
      say ("Downloading %s from %s to %s", pkg_name, url, cached_file);
      urlwrite (url, cached_file);
    endfunction

    function out = get_forge_download_info (this, pkg_name)
      [ver, url] = get_forge_pkg (pkg_name);
      out.version = ver;
      out.url = url;
      out.local_file = [pkg_name "-" ver ".tar.gz"];
    endfunction

    function out = get_package_list_info (this)
      [html, succ] = urlread ("https://packages.octave.org/list_packages.php");
      if (! succ)
        error ("get_forge_pkg: could not read URL, please verify internet connection");
      endif
      t = strsplit (html);
      file = this.download_cached_meta_file ("pkg_list",
        [this.forge_url "/list_packages.php"]);
      out = parse_forge_package_list (fileread (file));
    endfunction

    function cached_file = download_cached_meta_file (this, tag, url)
      cache_dir = fullfile (this.download_cache_dir, "meta");
      cached_file = fullfile (cache_dir, tag);
      if exist (cached_file, "file")
        [st, err, msg] = stat (cached_file);
        mtime = packajoozle.internal.Util.posixtime2datenum (st.mtime);
        expiry_time = mtime + this.cached_meta_ttl;
        if now < expiry_time
          # Cache hit
          out = cached_file;
          return
        else
          delete (cached_file);
        endif
      endif
      # Cache miss
      mkdir (cache_dir);
      packajoozle.internal.Util.urlwrite (url, cached_file);
    endfunction

    function cached_file = download_cached_pkg_distribution (this, pkgver)
      mustBeA (pkgver, "packajoozle.internal.PkgVer")
      tgz_file = sprintf ("%s-%s.tar.gz", pkgver.name, char (pkgver.version));
      url = [this.forge_url "/download/" tgz_file];
      cache_dir = fullfile (this.download_cache_dir, "distributions");
      packajoozle.internal.Util.mkdir (cache_dir);
      cached_file = fullfile (cache_dir, tgz_file);
      if exist (cached_file, "file")
        return
      endif
      tmp_file = [cached_file ".download.tmp"];
      packajoozle.internal.Util.urlwrite (url, tmp_file);
      packajoozle.internal.Util.movefile (tmp_file, cached_file);
    endfunction

    function out = get_current_pkg_version (this, pkg_name)
      mustBeCharVec (pkg_name);
      mustBeValidPkgName (pkg_name);
      name = tolower (pkg_name);

      url = sprintf ("%s/%s/index.html", this.forge_url, pkg_name);
      html = packajoozle.internal.Util.urlread (url);

      ## Remove blanks for simpler matching.
      html(isspace(html)) = [];
      ## Good.  Let's grep for the version.
      pat = "<tdclass=""package_table"">PackageVersion:</td><td>([\\d.]*)</td>";
      t = regexp (html, pat, "tokens");
      if (isempty (t) || isempty (t{1}))
        error ("get_current_pkg_version: version number not found in package page for: %s", ...
          pkg_name);
      else
        ver = t{1}{1};
      endif
      out = ver;
    endfunction

    function out = get_latest_matching_pkg_version (this, pkgreq)
      avail = this.list_all_releases;
      ix = strcmp (names (avail), pkgreq.package);
      vers = versions (avail);
      vers = vers(ix);
      tf = pkgreq.ver_filters.matches (vers);
      match_vers = vers(tf);
      if isempty (match_vers)
        out = [];
      else
        out = max (match_vers);
      endif
    endfunction
    
    function out = list_all_package_distribution_files (this)
      file = this.download_cached_meta_file ('package-file-download-page.html', ...
        'https://sourceforge.net/projects/octave/files/Octave%20Forge%20Packages/Individual%20Package%20Releases');
      html = fileread (file);
      # Here's a JSON representation of all the files, but we can't use it yet because Octave
      # doesn't have JSON support
      pat = '<script>\s+net\.sf\.files = (.*?)\s*net.sf.staging_days';
      [ix, str, tok] = regexp(html, pat, 'start', 'match', 'tokens');
      # So scrape the HTML itself
      pat = '<tr\s+title="(.*?gz)"\s+class="file';
      [ix, m, tok] = regexp(html, pat, 'start', 'match', 'tokens');
      if isempty (ix)
        error ("OctaveForgeClient: failed parsing file list web page");
      endif
      files = cat(1, tok{:});
      out = files;
    endfunction

    function out = list_versions_for_package (this, pkg_name)
      meta = this.list_all_releases;
      ix = strcmp (names (meta), pkg_name);
      vers = versions (meta);
      vers = vers(ix);
      out = vers;
    endfunction
    

    function out = resolve_latest_version (this, pkg_req)
      ver = this.get_latest_matching_pkg_version (pkg_req);
      out = packajoozle.internal.PkgVer (pkg_req.package, ver);
    endfunction

    function out = list_forge_package_names (this)
      # Just a name list, returned as a cellstr
      txt = packajoozle.internal.Util.urlread ([this.forge_url "/list_packages.php"]);
      out = ostrsplit (txt, " \n\t", true);
    endfunction

    function out = list_all_releases (this)
      dist_files = this.list_all_package_distribution_files;
      [ix, tok] = regexp (dist_files, '^(.*)-(.*)(\.tar\.gz|\.tgz)$', 'start', 'tokens');
      tok = cat(1, tok{:});
      tok = cat(1, tok{:});
      pkgs = tok(:,1);
      vers = tok(:,2);
      out = cell (size (pkgs));
      for i = 1:numel (out)
        ver = packajoozle.internal.Version(vers{i});
        out{i} = packajoozle.internal.PkgVer (pkgs{i}, ver);
      endfor
      out = packajoozle.internal.Util.objcatc (out);
      out = sort (out);
    endfunction

    function out = list_forge_packages_with_meta (this)
      # Returns a struct with at least fields: name, current_version
      pkg_names = this.list_forge_package_names;
      vers = cell (size (pkg_names));
      for i = 1:numel (pkg_names)
        vers{i} = this.get_current_pkg_version (pkg_names{i});
      endfor
      out.name = pkg_names;
      out.current_version = vers;
    endfunction

    % IPackageMetaSource implementation

    function out = list_available_packages (this)
      out = this.list_all_releases;
    endfunction

    function out = get_package_description_meta (this, pkgver)
      # Check cache
      pkg_meta_cache_dir = fullfile (this.download_cache_dir, ...
        "pkg-meta");
      cache_dir_for_this_pkgver = fullfile (pkg_meta_cache_dir, ...
        pkgver.name, sprintf ("%s-%s", pkgver.name, char (pkgver.version)));
      cached_file = fullfile (cache_dir_for_this_pkgver, "DESCRIPTION");
      if ! exist (cached_file, "file")
        dist_file = this.download_cached_pkg_distribution (pkgver);
        [out, descr_txt] = packajoozle.internal.PkgDistUtil.get_pkg_description_from_pkg_archive_file (dist_file);
        packajoozle.internal.Util.mkdir (cache_dir_for_this_pkgver);
        packajoozle.internal.Util.filewrite (cached_file, descr_txt);
      else
        out = packajoozle.internal.PkgDistUtil.parse_pkg_description_file (...
          packajoozle.internal.Util.fileread (cached_file));
      endif
    endfunction

  endmethods

endclassdef

%==========================================================================
% Local functions

function say (varargin)
  fprintf ("%s: %s\n", "OctaveForgeClient", sprintf (varargin{:}));
  flush_diary
endfunction

function out = parse_forge_package_list (txt)
  out.name = regexp(txt, "\r?\n", "split");
endfunction

function mustBeValidPkgName (name)
  if (! all (isalnum (name) | name == "-" | name == "." | name == "_"))
    error ("OctaveForgeClient: invalid package NAME: %s", name);
  endif
endfunction

%==========================================================================
% Local functions
%
% These are mostly copied from pkg, and in the process of being refactored.

function out = find_pkgs_named_like (name)
  ## Try get the list of all packages.
  [html, succ] = urlread ("https://packages.octave.org/list_packages.php");
  if (! succ)
    error ("get_forge_pkg: could not read URL, please verify internet connection");
  endif
  t = strsplit (html);
  if (any (strcmp (t, name)))
    error ("get_forge_pkg: package NAME exists, but index page not available");
  endif
  ## Try a simplistic method to determine similar names.
  function d = fdist (x)
    len1 = length (name);
    len2 = length (x);
    if (len1 <= len2)
      d = sum (abs (name(1:len1) - x(1:len1))) + sum (x(len1+1:end));
    else
      d = sum (abs (name(1:len2) - x(1:len2))) + sum (name(len2+1:end));
    endif
  endfunction
  dist = cellfun ("fdist", t);
  [~, i] = min (dist);
  error ("get_forge_pkg: package not found: ""%s"".  Maybe you meant ""%s?""",
         name, t{i});
endfunction
