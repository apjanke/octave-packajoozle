Packajoozle Developer’s Notes
=============================

## Code Style

* Standard [GNU Octave code style](https://wiki.octave.org/Octave_style_guide)

## Code Stuff

### The `private` directory

All the stuff in the `private` directory is just copies of the legacy `pkg` code that is being kept around for reference, and to keep `pkj_old` working.
It should all be eliminated, with useful functionality moved into objects in the `+packajoozle` namespace.

### The `dispstr` API

The `dispstr` API is a convention apjanke came up with for converting arbitrary Octave types to displayable strings.
It consists of the following functions/methods:

* `dispstr (x)` – Returns a single string (`char` row vector) that represents the entire `x` array, in human-readable (not machine-parseable) form.
* `dispstrs (x)` – Returns a cellstr the same size as the input `x`, with each element containing a string that represents that element of the array.
* `char (x)` – A conversion function for converting the input to chars. Not well-defined yet.
* `disp (x)` – An override for custom display of objects. When using the `dispstr` API, `disp (x)` should just display the results of `dispstr (x)`.

This is not a standard Octave or Matlab API; it’s just something apjanke came up with, but he thinks it’s a good idea.

Andrew has done work on `dispstr` in other contexts, if you want to use those for reference.

* [`dispstr` for Matlab](https://github.com/apjanke/dispstr)
* [SLF4M](https://github.com/apjanke/dispstr), a logging library for Matlab that uses the `dispstr` API
  * [SLF4M on MathWorks File Exchange](https://www.mathworks.com/matlabcentral/fileexchange/66157-apjanke-slf4m)

The canonical implementation of the `dispstr` API for a given object is the following:

```
    function out = disp (this)
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
        out{i} = ... ACTUAL STRING CONSTRUCTION CODE GOES HERE ...
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

```

# Data Structures and Whatnot

## The `desc` structure format

A `desc` array is a cell vector, each containing a struct with fields:

* `name`
* `version`
* `date`
* `author`
* `maintainer`
* `title`
* `description`
* `categories`
* `problems`
* `depends`
  * A cell vector of structs of (`package`, `operator`, `version`)
* `suggested`
* `autoload`
* `license`
* `url`

And possibly:
* `dir`
* `archprefix` – which is really the arch-specific _dir_ for the package installation, not the prefix
* `loaded` – this field may or may not make it into the descs in the saved package index file, depending on when it was created with respect to their installation.

This structure is defined by Octave's `pkg`, not by Packajoozle.
