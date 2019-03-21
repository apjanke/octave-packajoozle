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
## @deftypefn {Class Constructor} {obj =} OctaveForgeClient ()
## Octave Forge client.
##
## A client for getting directory info, package metadata, and package
## distribution downloads from Octave Forge.
##
## @end deftypefn

## Author:  

classdef OctaveForgeClient

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
      cache_dir = fullfile (this.download_cache_dir, "forge", "meta");
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

%==========================================================================
% Local functions
%
% These are mostly copied from pkg, and in the process of being refactored.

function ver = get_current_pkg_version (name)
  ## Verify that name is valid.
  if (! (ischar (name) && rows (name) == 1 && ndims (name) == 2))
    error ("get_forge_pkg: package NAME must be a string");
  elseif (! all (isalnum (name) | name == "-" | name == "." | name == "_"))
    error ("get_forge_pkg: invalid package NAME: %s", name);
  endif

  name = tolower (name);

  ## Try to download package's index page.
  [html, succ] = urlread (sprintf ("https://packages.octave.org/%s/index.html",
                                   name));
  if (succ)
    ## Remove blanks for simpler matching.
    html(isspace(html)) = [];
    ## Good.  Let's grep for the version.
    pat = "<tdclass=""package_table"">PackageVersion:</td><td>([\\d.]*)</td>";
    t = regexp (html, pat, "tokens");
    if (isempty (t) || isempty (t{1}))
      error ("get_forge_pkg: could not read version number from package's page");
    else
      ver = t{1}{1};
    endif
  else
    ## This block is just error handling to produce nicer messages
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
  endif
endfunction

function [ver, url] = get_forge_pkg (name)

  ## Verify that name is valid.
  if (! (ischar (name) && rows (name) == 1 && ndims (name) == 2))
    error ("get_forge_pkg: package NAME must be a string");
  elseif (! all (isalnum (name) | name == "-" | name == "." | name == "_"))
    error ("get_forge_pkg: invalid package NAME: %s", name);
  endif

  name = tolower (name);

  ## Try to download package's index page.
  [html, succ] = urlread (sprintf ("https://packages.octave.org/%s/index.html",
                                   name));
  if (succ)
    ## Remove blanks for simpler matching.
    html(isspace(html)) = [];
    ## Good.  Let's grep for the version.
    pat = "<tdclass=""package_table"">PackageVersion:</td><td>([\\d.]*)</td>";
    t = regexp (html, pat, "tokens");
    if (isempty (t) || isempty (t{1}))
      error ("get_forge_pkg: could not read version number from package's page");
    else
      ver = t{1}{1};
      if (nargout > 1)
        ## Build download string.
        pkg_file = sprintf ("%s-%s.tar.gz", name, ver);
        url = ["https://packages.octave.org/download/" pkg_file];
        ## Verify that the package string exists on the page.
        if (isempty (strfind (html, pkg_file)))
          warning ("get_forge_pkg: download URL not verified");
        endif
      endif
    endif
  else
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
  endif

endfunction
