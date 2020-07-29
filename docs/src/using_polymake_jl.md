# Using Polymake.jl

In this section, the main functionality of `Polymake.jl` is covered: how to access `polymake`'s powerful abilities. For this cause one needs to know how to call `polymake` methods and how to handle the supported types.

## Executing Polymake Methods

### Directly calling a `polymake` method

One of the simplest yet most useful possibilities `Polymake.jl` offers is to directly use a `polymake` method via the following macro:
```@docs
@pm
```
The `@pm` macro can be used to issue more complicated calls to polymake from julia.
If You need to pass templates to `BigObject`s, some limited support is provided in costructors.
For example one can construct `polytope.Polytope{Float64}(...)`.
However for this to work templates need to be valid julia types/object, hence
it is not possible to construct a `Polytope<QuadraticExtension>` through such call.
For this (and in general: for passing more complicated templates) one needs the
`@pm` macro:
```perl
$obj = new BigObject<Template,Parameters>(args)
```
becomes
```julia
obj = @pm appname.BigObject{Template, Parameters}(args)
```

Examples:
```julia
tropical.Polytope{max, Polymake.Rational}(POINTS=[1 0 0; 1 1 0; 1 1 1])
# call to constructor, note that max is a julia function, hence a valid object
@pm tropical.Polytope{Max, QuadraticExtension}(POINTS=[1 0 0; 1 1 0; 1 1 1])
# macro call: none of the types in templates need to exist in julia
```

As a rule of thumb any template passed to `@pm` macro needs to be translatable
on syntax level to a `C++` one. E.g. `Matrix{Integer}` works, as it translates to
`pm::Matrix<pm::Integer>`.

Such templates can be passed to functions as well. A very useful example is the
`common.convert_to`:
```julia
julia> c = polytope.cube(3);

julia> f = c.FACETS;

julia> f[1,1] # f is an opaque pm::perl::PropertyValue to julia
ERROR: MethodError: no method matching getindex(::Polymake.PropertyValueAllocated, ::Int64, ::Int64)
Stacktrace:
  [...]

julia> m = @pm common.convert_to{Matrix{Integer}}(f) # the template must consist of C++ names
pm::Matrix<pm::Integer>
1 1 0 0
1 -1 0 0
1 0 1 0
1 0 -1 0
1 0 0 1
1 0 0 -1

julia> m[1,1]
1
```

Since the combination of the `@pm` macro and `common.convert_to` is quite common there is a
specialized `@convert_to` macro for this:
```julia

julia> m = @convert_to Matrix{Integer} f # the template must consist of C++ names
pm::Matrix<pm::Integer>
1 1 0 0
1 -1 0 0
1 0 1 0
1 0 -1 0
1 0 0 1
1 0 0 -1
```

### Wrapped methods

As the [`@pm`](@ref) macro allows to access `polymake`'s library, there is no need for every method to be wrapped. In general, the wrapped methods restrict to simpler ones in the context of small types, guaranteeing compatibility with `julia` or allowing easy modification/operations of/with instances of these types.
This results in a handling of these types which is equivalent to `julia`'s syntax, e.g. arrays can be accessed with the brackets operator `[]` or addition can be applied by using `+`:

```julia
julia> m = Polymake.Matrix{Polymake.Rational}(4,6)
pm::Matrix<pm::Rational>
0 0 0 0 0 0
0 0 0 0 0 0
0 0 0 0 0 0
0 0 0 0 0 0


julia> m[2,1] = 9
9

julia> m
pm::Matrix<pm::Rational>
0 0 0 0 0 0
9 0 0 0 0 0
0 0 0 0 0 0
0 0 0 0 0 0

julia> a = Polymake.TropicalNumber{Polymake.Min}(7)
pm::TropicalNumber<pm::Min, pm::Rational>
7

julia> b = Polymake.TropicalNumber{Polymake.Min}(10)
pm::TropicalNumber<pm::Min, pm::Rational>
10

julia> a + b
pm::TropicalNumber<pm::Min, pm::Rational>
7
```

### Function Arguments

Functions in `Polymake.jl` accept the following types for their arguments:
* simple data types (bools, machine integers, floats)
* wrapped native types (`Polymake.Integer`, `Polymake.Rational`, `Polymake.Vector`, `Polymake.Matrix`, `Polymake.Set` etc.)
* other objects returned by polymake:
  *  `Polymake.BigObject`,
  *  `Polymake.PropertyValue` (containers opaque to Julia)

If an object passed to `Polymake.jl` function is of a different type the software will try its best to convert it to a known one. However, if the conversion doesn't work an `ArgumentError` will be thrown:
```julia
ERROR: ArgumentError: Unrecognized argument type: SomeType.
You need to convert to polymake compatible type first.
```

You can tell `Polymake.jl` how to convert it by definig
```julia
Base.convert(::Type{Polymake.PolymakeType}, x::SomeType)
```
The returned value must be of one of the types as above. For example to use `AbstractAlgebra.jl` matrices as input to `Polymake.jl` one may define
```julia
Base.convert(::Type{Polymake.PolymakeType}, M::Generic.MatSpaceElem) = Polymake.Matrix(M.entries)
```
and the following should run smoothly.
```julia
julia> using AbstractAlgebra, Polymake
polymake version 4.0
Copyright (c) 1997-2020
Ewgenij Gawrilow, Michael Joswig (TU Berlin)
https://polymake.org

This is free software licensed under GPL; see the source for copying conditions.
There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


julia> mm = AbstractAlgebra.matrix(ZZ, [1 2 3; 4 5 6])
[1 2 3]
[4 5 6]

julia> polytope.Polytope(POINTS=mm)
ERROR: ArgumentError: Unrecognized argument type: AbstractAlgebra.Generic.MatSpaceElem{Int64}.
You need to convert to polymake compatible type first.
  [...]

julia> Base.convert(::Type{Polymake.PolymakeType}, M::Generic.MatSpaceElem) = Polymake.Matrix(M.entries)

julia> polytope.Polytope(POINTS=mm)
type: Polytope<Rational>

POINTS
1 2 3
1 5/4 3/2

```

## Accessing the polyDB

```@meta
CurrentModule = Polymake.Polydb
```

`Polymake.jl` allows the user to access the objects stored within the `polyDB` via the `Mongoc.jl` package; this functionality can be found in another sub-module, `Polymake.Polydb`, which requires no additional interaction to be loaded. It offers two different ways for querying, as well as some methods for information.
For demonstration purposes, there also is a `Jupyter notebook` in the `examples/` folder.

### General tools

There are three types one needs to know when working with `Polymake.Polydb`:

```@docs
Database
Collection
Cursor
```

To receive the `Database` object referencing to the `polyDB`, there is the `get_db()` method:

```@docs
get_db()
```

A specific `Collection` object can then be obtained with the brackets operator:

```@docs
getindex(::Database, ::String)
```

By default, the results are parsed to `Polymake.BigObject`s when accessed, but one may choose to change this behaviour by adjusting the typing template of `Collection` or `Cursor` using the following method:

```@docs
Collection(::Collection)
```

### Information

```@docs
info
get_collection_names
get_fields
```

### Querying

There are two ways for querying within `Polymake.jl`.

#### Methods

```@docs
find
```

#### Macros

```@docs
@select
@filter
@map
```
