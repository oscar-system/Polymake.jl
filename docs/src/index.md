# Polymake.jl

[`Polymake.jl`](https://github.com/oscar-system/Polymake.jl) is a Julia package for using [`polymake`](https://polymake.org/doku.php), a software for research in polyhedral geometry from Julia.
This package is developed as part of the [OSCAR](https://oscar.computeralgebra.de) project.

The current version of `Polymake.jl` relies on `polymake` version `4.0` or later.

## Current state of the `polymake` wrapper

### Data structures

* Big objects, e.g., Polytopes, can be handled in Julia.
* Several small objects (data types) from `polymake` are available in `Polymake.jl`:
    * Integers (`Polymake.Integer <: Integer`)
    * Rationals (`Polymake.Rational <: Real`)
    * Vectors (`Polymake.Vector <: AbstractVector`) of `Int64`s, `Float64`s, `Polymake.Integer`s and `Polymake.Rational`s
    * Matrices (`Polymake.Matrix <: AbstractMatrix`) of `Int64`s, `Float64`s, `Polymake.Integer`s and `Polymake.Rational`s
    * Sets (`Polymake.Set <: AbstractSet`) of `Int64`s
    * Arrays (`Polymake.Array <: AbstractVector`, as `Polymake.Arrays` are one-dimensional) of `Int64`s and `Polymake.Integers`
    * some combinations thereof, e.g., `Polymake.Array`s of `Polymake.Sets` of `Int32`s.

These data types can be converted to appropriate Julia types,
but are also subtypes of the corresponding Julia abstract types (as indicated above),
and so should be accepted by all methods that apply to the abstract types.

**Note**: If the returned small object has not been wrapped in `Polymake.jl`
yet, you will not be able to access its content or in general use it **from Julia**,
however you can always pass it back as an argument to a `polymake` function.
Moreover you may try to convert to Julia understandable type via macro
`@convert_to SomeType{Template, Names} obj`.

### Functions

* All user functions from `polymake` are available in the appropriate modules, e.g. `homology` function from `topaz` can be called as `topaz.homology(...)` in julia. We pull the docstrings for functions from `polymake` as well, so `?topaz.homology` (in Julia's REPL) returns the `polymake` docstring. Note: the syntax presented in the docstring is a `polymake` syntax, not `Polymake.jl` one.
* Most of the user functions from `polymake` are available as `appname.funcname(...)` in `Polymake.jl`.  Moreover, any function from `polymake` `C++` library can be called via macro call `@pm appname.funcname{C++{template, names}}(...)`.
* All big objects of `polymake` can be constructed either via call to constructor, i.e.
```julia
obj = appname.BigObject(args)
```
One can specify some templates here as well: `polytope.Polytope{Float64}(...)` is a valid call, but the list of supported types is rather limited. Please consider filing a bug if a valid call results in `polymake` error.
For more advanced use see section on [`@pm`](@ref) macro.
* Properties of big objects are accessible by `bigobject.property` syntax (as opposed to `$bigobject->property` in `polymake`). If there is a missing property please check if it can be accessed by `appname.property(object)`. For example `polytope.Polytope` does not have `DIM` property in `Polymake.jl` sinc `DIM` is exposed as `polytope.dim(...)` function.
* Methods are available as functions in the appropriate modules, with the first argument as the object, i.e. `$bigobj->methodname(...)` can be called via `appname.methodname(bigobj, ...)`
* A function in `Polymake.jl` calling `polymake` may return a big or small object, and the generic return (`PropertyValue`) is transparently converted to one of the known data types. This conversion can be deactivated by adding `keep_PropertyValue=true` keyword argument to function/method call.

## User Guide
- [Getting Started](@ref)
- [Using Polymake.jl](@ref)
- [Examples](@ref)

## Funding

The development of this Julia package is supported by the Deutsche
Forschungsgemeinschaft DFG within the
[Collaborative Research Center TRR 195](https://www.computeralgebra.de/sfb/).
