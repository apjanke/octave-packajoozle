shims
=====

This directory hierarchy contains compatibility "shims" for old versions of Octave. This lets Packajoozle use new things like isfolder() but still work on versions of Octave before they were introduced.

The way this works is that for each version compatibility level X, there's a pre-X folder under "shims/". The PKG_ADD file in the main "inst" directory detects the Octave version and loads the appropriate shims subdirectories.

The `all` directory contains shims that are needed for all currently known versions of Octave for Matlab compatibility.
This was last updated as of March 23, 2019, for Octave 6.0.0 "default" prerelease (changeset 26962:1a79f289ca33).

The functions in the `all` category are intentionally not the same name as the real Octave/Matlab functions or operations, so they can still be used once those operations become available in core Octave.