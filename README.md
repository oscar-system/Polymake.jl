# Polymake.jl

Julia package for using [polymake](https://polymake.org/doku.php), a software for research in polyhedral geometry.
This package is developed as part of the [OSCAR](https://oscar.computeralgebra.de) project.

## Installation

The current version relies on an unreleased version of polymake. A compatible version is available at [polymake/polymake#snapshots](https://github.com/polymake/polymake/tree/Snapshots) and it can be compiled as follows where `GIT_FOLDER` and `INSTALL_FOLDER` have to be substituted with your favorite folder.
```sh
export POLYMAKE_GIT=GIT_FOLDER
export POLYMAKE_INSTALL=INSTALL_FOLDER
git clone git@github.com:polymake/polymake $POLYMAKE_GIT
cd $POLYMAKE_GIT
git checkout Snapshots
./configure --prefix=$POLYMAKE_INSTALL
ninja -C build/Opt
ninja -C build/Opt install
export POLYMAKE_CONFIG=$POLYMAKE_INSTALL/bin/polymake-config
```

Note that the compilation can take.

If you already have a recent enough version of polymake on your system and skipped the above instructions you still need to either have `polymake-config` available in your PATH or the environment variable `POLYMAKE_CONFIG` needs to point to the correct `polymake-config` file.

After this the installation can be done in the Julia REPL by first pressing `]` and then
```julia
pkg> add https://github.com/oscar-system/Polymake.jl
```

## Examples

polymake big objects (like `Polytope`, `Cone`, etc) can be created with the `perlobj` helper functions.
```julia
# Call the Polytope constructor
julia> p = perlobj("Polytope", POINTS=[1 -1 -1; 1 1 -1; 1 -1 1; 1 1 1; 1 0 0])
type: Polytope<Rational>

POINTS
1 -1 -1
1 1 -1
1 -1 1
1 1 1
1 0 0

```

Properties of such objects can be accessed by the `.` syntax
```
julia> p.INTERIOR_LATTICE_POINTS
pm::Matrix<pm::Integer>
1 0 0
```

## Current state

### Data structures

* Several small data types from polymake are available in Julia:
    * Integers
    * Rationals
    * Vectors
    * Matrices
    * Arrays
    * Sets
    * Combinations thereof, e.g., Sets of Arrays of Integers
 
The polymake data types can be converted to appropriate Julia types,
but are also subtypes of the corresponding Julia abstract types, e.g., a
polymake array is an `AbstractArray`, and one can call methods that
apply to `AbstractArray`s on polymake arrays.
* Big objects, e.g., Polytopes, can be handled in Julia

### Functions

* Properties of big objects are accessible by `object.property` syntax
(and also via the `give` function).
* Methods can be called via `call_method`
* Functions can be called via `call_function`

All three ways of calling a function in polymake can return any big or
small object, and the generic return (`PropertyValue`) is transparently
converted to one of the data types above. For performance reasons, this
conversion can be deactivated
