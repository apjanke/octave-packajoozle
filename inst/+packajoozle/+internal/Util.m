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
## @deftypefn {Class Constructor} {obj =} Util ()
##
## Utility functions.
##
## Miscellaneous utility functions for Packajoozle.
##
## @end deftypefn

classdef Util

  methods (Static)

    function out = isfileorfolder (path)
      %ISFOLDER True if path exists and is a file or directory of any type
      path = cellstr (path);
      out = false (size (path));
      for i = 1:numel (path)
        st = stat (path{i});
        out(i) = ! isempty (st);
      endfor
    endfunction

    function out = isfile (path)
      %ISFILE True if path exists and is a plain file (or at least not a directory)
      path = cellstr (path);
      out = false (size (path));
      for i = 1:numel (path)
        st = stat (path{i});
        out(i) = (! isempty (st)) && st.modestr(1) != 'd';
      endfor
    endfunction

    function out = isfolder (path)
      %IFILE True if file exists and is a directory
      path = cellstr (path);
      out = false (size (path));
      for i = 1:numel (path)
        st = stat (path{i});
        out(i) = (! isempty (st)) && st.modestr(1) == 'd';
      endfor
    endfunction

    function out = parse_options (options, defaults)
      opts = defaults;
      if isempty (options)
        options = {};
      endif
      if iscell (options)
        s = struct;
        for i = 1:2:numel (options)
          s.(options{i}) = options{i+1};
        endfor
        options = s;
      endif
      if (! isstruct (options))
        error ("parse_options: options must be a struct or name/val cell vector");
      endif
      opt_fields = fieldnames (options);
      for i = 1:numel (opt_fields)
        opts.(opt_fields{i}) = options.(opt_fields{i});
      endfor
      out = opts;
    endfunction

    function out = packajoozle_data_dir
      out = fullfile (getenv("HOME"), "octave", "packajoozle");
    endfunction

    function flush_diary
      if diary
        diary off
        diary on
      endif
    endfunction

    function fid = fopen (file, varargin)
      [fid, msg] = fopen (file, varargin{:});
      if fid < 0
        error ("fopen: could not open file %s: %s", file, msg);
      endif
    endfunction
    
    function filewrite (out_file, txt)
      [fid, msg] = fopen (out_file, 'w');
      if fid < 0
        error ("filewrite: Failed opening file for writing:\n  File: %s\n  Error: %s", ...
          out_file, msg);
      endif
      fwrite (fid, txt);
      fclose (fid);
    endfunction

    function out = fileread (file)
      % This method just exists because I keep calling it out of habit. -apjanke
      out = fileread (file);
    endfunction

    function out = basename (file)
      ix = find (file == filesep, 1, "last");
      if isempty (ix)
        out = file;
      else
        out = file(ix+1:end);
      endif
    endfunction

    function out = posixtime2datenum (posix_time)
      persistent unix_epoch_datenum = datenum('1/1/1970');
      out = (posix_time / (60 * 60 * 24)) + unix_epoch_datenum;
    endfunction

    function out = urlwrite (url, localfile)
      [f, ok, msg] = urlwrite (url, localfile);
      if ! ok
        error ("urlwrite: Failed downloading URL:\n  URL: %s\n  Error: %s", ...
          url, msg);
      endif
    endfunction

    function out = urlread (url)
      [out, ok, msg] = urlread (url);
      if ! ok
        error ("urlread: Failed downloading URL:\n  URL: %s\n  Error: %s", ...
          url, msg);
      endif
    endfunction

    function movefile (f1, f2, varargin)
      [ok, msg, msgid] = movefile (f1, f2, varargin{:});
      if ! ok
        error ("movefile: Failed moving '%s' to '%s': %s", f1, f2, msg);
      endif
    endfunction

    function mkdir (path)
      [ok, msg] = mkdir (path);
      if ! ok
        error ("mkdir: Could not create directory %s: %s", path, msg);
      endif
    endfunction

    function out = readdir (path)
      [out, err, msg] = readdir (path);
      if err
        error ("readdir: Could not read directory '%s': %s", path, msg);
      endif
      out(ismember (out, {'.', '..'})) = [];
    endfunction

    function rm_rf (path)
      #TODO: Should this actually error if it fails, instead of just warn?
      # Maybe a "strict" option for it?
      if exist (path, "dir")
        confirm_recursive_rmdir (0, "local");
        [ok, msg, msgid] = rmdir (path, "s");
        if ! ok
          error ("rm_rf: Failed deleting dir %s: %s", path, msg);
        endif
      elseif packajoozle.internal.Util.isfile (path)
        lastwarn("");
        delete (path);
        [w, w_id] = lastwarn;
        if ! isempty (w)
          error ("rm_rf: Failed deleting file %s: %s", path, w);
        endif
      else
        % NOP
      endif
    endfunction

    function arch = get_system_arch ()
      persistent _arch = sprintf ("%s-%s", ...
        __octave_config_info__("canonical_host_type"), ...
        __octave_config_info__("api_version"));

      arch = _arch;
    endfunction

    function copyfile (source, destination)
      [ok, msg] = copyfile (source, destination);
      if ! ok
        error ("copyfile: couldn't copy file %s to %s: %s", source, destination, msg);
      endif
    endfunction
    
    function out = repmat_object_to_vector (x, n)
      # This exists becaue repmat doesn't work on objects, at least in Octave 4.4 or 5.1
      out = x;
      for i = 2:n
        out(i) = x;
      endfor
    endfunction

    function out = objcatc (c)
      %OBJCATC Hack to allow one-liners like objcatc({myobj.propname})
      mustBeA (c, "cell");
      out = objvcat (c{:});
    endfunction

    function mustBeCompatibleSizes (a, b)
      if ! isscalar (a) && ! isscalar (b)
        if ! isequal (size (a), size (b))
          error ("dimension mismatch: %s vs %s", size2str (size (a)), size2str (size (b)));
        endif
      endif
    endfunction
    
    function [A_keys, B_keys] = proxy_keys_unique_trick (A, B)
      n_a = numel (A);
      both = [A(:); B(:)];
      [u, ix, jx] = unique (both);
      A_keys = jx(1:n_a);
      B_keys = jx(n_a+1:end);
      A_keys = reshape (A_keys, size (A));
      B_keys = reshape (B_keys, size (B));
    endfunction

    function valid = is_valid_pkg_version_string (str)
      ## We are limiting ourselves to this set of characters because the
      ## version will appear on the filepath.  The portable character, according to
      ## http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap03.html#tag_03_278
      ## is [A-Za-z0-9\.\_\-].  However, this is very limited.  We specially
      ## want to support a "+" so we can support "pkgname-2.1.0+" during
      ## development.  So we use Debian's character set for version strings
      ## https://www.debian.org/doc/debian-policy/ch-controlfields.html#s-f-Version
      ## with the exception of ":" (colon) because that's the PATH separator.
      ##
      ## Debian does not include "_" because it is used to separate the name,
      ## version, and arch in their deb files.  While the actual filenames are
      ## never parsed to get that information, it is important to have a unique
      ## separator character to prevent filename clashes.  For example, if we
      ## used hyhen as separator, "signal-2-1-rc1" could be "signal-2" version
      ## "1-rc1" or "signal" version "2-1-rc1".  A package file for both must be
      ## able to co-exist in the same directory, e.g., during package install or
      ## in a flat level package repository.
      valid = numel (regexp (str, '[^0-9a-zA-Z\.\+\-\~]')) == 0;
    endfunction

    function out = xdg_octave_cache_dir ()
      % Gets the XDG Cache dir for Octave. The actual directory may not exist.
      f = getenv ("XDG_CACHE_HOME");
      if ! isempty (f)
        out = fullfile (f, "octave");
        return
      endif
      out = fullfile (getenv ("HOME"), ".cache", "octave");
    endfunction

    function [std_out, std_err, status] = system (cmd)
      if nargout >= 2
        tmp_dir = tempname (tempdir, "packajoozle/util/system/work-");
        packajoozle.internal.Util.mkdir (tmp_dir);
        RAII.tmp_dir = onCleanup (@() packajoozle.internal.Util.rm_rf (tmp_dir));
        # This assumes the caller is not doing their own redirection
        stdout_tmp = fullfile (tmp_dir, "stdout.txt");
        stderr_tmp = fullfile (tmp_dir, "stderr.txt");
        redirected_cmd = sprintf('%s > "%s" 2> "%s"', cmd, stdout_tmp, stderr_tmp);
        [status, leftover_stdout] = system (redirected_cmd);
        std_out = fileread (stdout_tmp);
        std_err = fileread (stderr_tmp);
      else
        [status, std_out] = system (cmd);
      endif
      if status != 0 && nargout < 3
        error (["system: command failed:\n" ...
          "  Command: %s\n  Exit status: %d"], ...
          cmd, status);
      endif
      if nargout == 0
        clear std_out std_err status
      endif
    endfunction
    
    function [found, map_out] = file_find (file, filter, map_operation)
      %FILE_FIND Recursively find files and operate on them
      if nargin < 2; filter = []; endif
      if nargin < 3; operation = []; endif
      if isempty (filter)
        filter = @(x) true;
      endif
      if isempty (map_operation)
        map_operation = @deal;
      endif

      # TODO: Decide how search pruning should work

      found = {};
      selected = {};
      map_out = {};
      function step (file1)
        found{end+1} = file1;
        if filter (file1)
          selected{end+1} = file1;
          map_out{end+1} = map_operation (file1);
        endif
        if exist (file1, "dir")
          kids = packajoozle.internal.Util.readdir (file1);
          for i = 1:numel (kids)
            step (fullfile (file1, kids{i}));
          endfor
        endif
      endfunction

      step (file);
    endfunction

    function out = local_cd_change (path)
      orig_pwd = pwd;
      out.dir = path;
      out.cleanup = onCleanup (@() cd (orig_pwd));
      cd (path);
    endfunction

  endmethods

endclassdef

