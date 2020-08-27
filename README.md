Packajoozle for GNU Octave
==========================

Packajoozle is a re-working of Octave’s `pkg` package management tool to use OOP. It provides the `pkj` command, a drop-in replacement for `pkg`.

I started this as just a fun exercise, but it kind of got out of hand, and now it’s almost a real, usable package.

## Requirements

* Octave 4.4.1 or later

## New features

Compared to Octave’s `pkg`, Packajoozle’s `pkj` also provides:

* Versioned Forge package installation
  * Installation of a selected version instead of just the latest
  * Installation of multiple versions side-by-side
* More metadata available from Octave Forge
* Capturing of package build logs
* A `pkj test` command for running package unit tests
* A `pkj review` command to quality check Forge package distributions before publishing

## Installation

    pkg install https://github.com/apjanke/octave-packajoozle/archive/master.zip
    pkg load packajoozle

## Usage

Use the `pkj` function like you would Octave’s `pkg` function.
That's Packajoozle's version of it.
It supports all the calling forms that `pkg` does, and more.

See `help pkj` for details.
Though the help and documentation is pretty lacking right now.
Sorry about that.

`pkj` supports additional features:

### Versioned installation

You can specify a particular version of a package `foo` by appending `@<version>` to its name. The `<version>` can be a specific version, or `<operator><version>` where `<operator>` is one of the `compare_versions` operators (`<`, `<=`, `==`, `!=`, `>=`, or `>`).

Examples:

```
>> pkj install -forge io@2.4.10
>> pkj install -forge financial@<0.5.0
```

When you have multiple versions of a package installed, the same version selectors can be used with `pkj load` to choose which one gets loaded.

When you use `<` or `>` selectors instead of a specific version for `install` or `load`, `pkj` will choose the most recent version that meets all your specified criteria.
For example, if you did `pkj install -forge io@<1.2`, it would pick `forge`
1.0.20, because that’s the most recent version that is still less than 1.2.0.

### Things to try

Here’s some stuff Packajoozle can do.

```
% What's available on Octave Forge?
pkj list -forge     % This is 40x faster than Octave's `pkg list -forge`!
pkj list -forge -listversions statistics

% Want to test multiple versions?
pkj install -forge statistics@1.4.0 statistics@1.3.0 statistics@1.2.4
pkj load statistics@1.3.0
```

You can also do `pkj test <package>` to run the tests in a package, but I haven’t been able to find any Octave Forge packages which actually have tests.

## Compatibility with Octave `pkg`

Packajoozle `pkj` is pretty well compatible with `pkg`.

The `pkj` command is back-compatible with the `pkg` command at the interface level.
Generally, any `pkg ...` command you run will do the same thing when you run it as `pkj ...` instead.
It’s just that `pkj` supports more commands, options, and package specifier forms over and above what `pkg` does, so more things will work in `pkj` than `pkg`.

Packajoozle uses the same package directory structure, installation locations, and index/metadata file formats that `pkg` does.
This means that packages installed by `pkj` are visible to `pkj`, and vice versa.
The one big exception here is versioning: `pkg` does not support multiple versioned installations of a given package, even though its index file supports it.
This means that if you install multiple versions of a single package using `pkj`, they will all be visible to `pkj`, and the newest ones will be visible to `pkg`, and everyone will be happy.
But then if you install a package using `pkg` (or do something else that causes it to update the package index file), `pkg` will wipe out all the “duplicate” old versions of the package, leaving only the latest version.
The older versions of the package will then disappear to both `pkg` and `pkj`.

Packajoozle uses a superset of the Octave Forge metadata that `pkg` does.
Generally, they will see the same state of Octave Forge; it’s just that `pkj` knows more details about it, like full listings of versions for a given Forge package.
Also, `pkj` does caching, so it may take a couple hours for Octave Forge updates to make their way down to `pkj` clients.
But that shouldn’t be a big deal, given how seldom Octave Forge packages receive updates.

## Requirements

* Octave 4.4.0 or newer

## Code organization

The main user interface to Packajoozle is the command-style function `pkj`.

All the stuff in `+internal` namespaces is undocumented stuff for Packajoozle’s internal use, and may change at any time.
Don’t code against it.
There’s nothing in the main `+packajoozle` namespace right now, but I’m planning on eventually moving some stuff there and making it part of the public API, to support programmatic use of Packajoozle.

## Internal changes

Internally, Packajoozle has reworked the Octave `pkg` code to move most of the logic into OOP classes.
The goal is to make it feasible to test small units of its functionality individually, and make it easier to handle complex data structures like version specifiers.
I’d also like to provide an OOP API to make it easier for developers to script Packajoozle operations; the `pkj` interface is clumsy, and intended for end user interaction, both in terms of its interface design and its output behavior.

## Authors

Packajoozle is written and maintained by [Andrew Janke](https://github.com/apjanke).
