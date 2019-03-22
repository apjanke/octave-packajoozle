shims
=====

This directory hierarchy contains compatibility "shims" for old versions of Octave. This lets Packajoozle use new things like isfolder() but still work on versions of Octave before they were introduced.

The way this works is that for each version compatibility level X, there's a pre-X folder under "shims/". The PKG_ADD file in the main "inst" directory detects the Octave version and loads the appropriate shims subdirectories.
