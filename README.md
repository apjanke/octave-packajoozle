Packajoozle for GNU Octave
==========================

Packajoozle is a re-factoring/re-working of Octave’s `pkg` package management tool to use OOP. It provides the `pkj` command, a drop-in replacement for `pkg`.

I’m just doing this as a fun exercise.
I don’t plan on submitting this back up for inclusion in Octave.

## New features

Compared to Octave’s `pkg`, Packajoozle’s `pkj` also provides:

* Versioned Forge package installation
  * Installation of a selected version instead of just the latest
  * Installation of multiple versions side-by-side
* More metadata available from Octave Forge
* Capturing of package build logs

## Installation and usage

* Clone the repo.
  * `git clone https://github.com/apjanke/octave-packajoozle`
* Add its `inst` dir to your Octave path
  * `cd /path/to/octave-packajoozle/inst`
  * `addpath (pwd)`

## Usage

Use the `pkj` function like you would Octave’s `pkg` function.
That's Packajoozle's version of it.

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
