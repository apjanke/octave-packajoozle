Packajoozle for GNU Octave
==========================

Packajoozle is a re-factoring/re-working of Octave’s `pkg` package management tool to use OOP. It provides the `pkj` command, a drop-in replacement for `pkg`.

I’m just doing this as a fun exercise.
I don’t plan on submitting this back up for inclusion in Octave.

## New features

Compared to Octave’s `pkg`, Packajoozle’s `pkj` provides:

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

### Usage

Use the `pkj` function like you would Octave’s `pkg` function.
That's Packajoozle's version of it.

`pkj` supports additional features:

#### Versioned installation

You can specify a particular version of a package `foo` by appending `@<version>` to its name. The `<version>` can be a specific version, or `<operator><version>` where `<operator>` is one of the `compare_versions` operators (`<`, `<=`, `==`, `!=`, `>=`, or `>`).

Examples:

```
>> pkj install -forge io@2.4.10
>> pkj install -forge financial@<0.5.0
```

When you have multiple versions of a package installed, the same version selectors can be used with `pkj load` to choose which one gets loaded.

## Internal changes

Internally, Packajoozle has reworked the Octave `pkg` code to move most of the logic into OOP classes.
The goal is to make it feasible to test small units of its functionality individually, and make it easier to handle complex data structures like version specifiers.

## Authors

Packajoozle is written and maintained by [Andrew Janke](https://github.com/apjanke).
