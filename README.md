# Polymake.jl

[![Build Status](https://travis-ci.com/oscar-system/Polymake.jl.svg?branch=master)](https://travis-ci.com/oscar-system/Polymake.jl)

`Polymake.jl` is a Julia package for using [`polymake`](https://polymake.org/doku.php), a software for research in polyhedral geometry from Julia.
This package is developed as part of the [OSCAR](https://oscar.computeralgebra.de) project.

The current version of `Polymake.jl` relies on `polymake` version `3.3` or later.

**Index:**
* [Installation](#installation)
* [Examples](#examples)
* [Polymake syntax translation](#polymake-syntax-translation)
* [Current state](#current-state-of-the-polymake-wrapper)

## Installation

The installation can be done in the Julia's REPL by executing
```julia
julia> using Pkg; Pkg.add("Polymake")
```
This will fetch a pre-build binary of `polymake`. You are ready to start `using Polymake`.

Note: Pre-build binaries are available only for the `Linux` platform. macOS users need to follow the "Your own installation of `polymake`" below. Windows users are encouraged to try running Julia inside Window Subsystem for Linux and reporting back ;)

### Your own installation of `polymake`

If you already have a recent enough version of `polymake` (i.e. `>=3.3`) on your system,
you either need to make `polymake-config` available in your `PATH` or
the environment variable `POLYMAKE_CONFIG` needs to point to the correct
`polymake-config` file.

After this just `add` the package as above (or `build` if the package has been already added), the build script will use your `polymake` installation.

### `polymake` from source

A compatible version is available at [polymake/polymake#snapshots](https://github.com/polymake/polymake/tree/Snapshots).
It can be compiled as follows where `GIT_FOLDER` and `INSTALL_FOLDER` have to be substituted with your favorite folders. Please note that these need to be absolute paths.
Also make sure to check [the necessary dependencies](https://polymake.org/doku.php/howto/install) as well as the [additional instructions for Macs](https://polymake.org/doku.php/howto/mac).

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
Note that `polymake` might take some time to compile.

After this start Julia and follow the instructions above.

### `Polymake.jl` in a separate environment:
First clone `Polymake.jl`:
```
git clone https://github.com/oscar-system/Polymake.jl.git
```
In the same directory start Julia and press `]` for `pkg` mode. Then run
```julia
(v1.0) pkg> activate Polymake.jl
(Polymake) pkg> instantiate
(Polymake) pkg> build Polymake # fetches the prebuild polymake binaries
(Polymake) pkg> test Polymake # and You are good to go!
```
If `polymake-config` is in your `PATH`, or `POLYMAKE_CONFIG` environment variable is set the `build` phase will try to use it.

Just remember that You need to `activate Polymake.jl` to use `Polymake`.

## Examples

In this section we just highlight various possible uses of `Polymake.jl`. Please refer to [Polymake syntax translation](#polymake-syntax-translation) for more thorough treatment.

`polymake` big objects (like `Polytope`, `Cone`, etc) should be created with the help of `@pm` macro:

```julia
# Call the Polytope constructor
julia> p = @pm Polytope.Polytope(POINTS=[1 -1 -1; 1 1 -1; 1 -1 1; 1 1 1; 1 0 0])
type: Polytope<Rational>

POINTS
1 -1 -1
1 1 -1
1 -1 1
1 1 1
1 0 0

```
Parameters could be passed as
* keyword arguments (as above),
* `Pair{Symbol, ...}`s e.g. `Polytope.Polytope(:POINTS=>[ ... ])`
* dictionaries e.g. `Polytope.Polytope(Dict( "POINTS" => [ ... ] )`)

The dictionary may hold many different attributes. All the names *must* be compatible with `polymake`.

Properties of such objects can be accessed by the `.` syntax:
```
julia> p.INTERIOR_LATTICE_POINTS
pm::Matrix<pm::Integer>
1 0 0
```

### Example script

The following script is modelled on the one from the [Using Perl within polymake](https://polymake.org/doku.php/user_guide/tutorials/perl_intro) tutorial:

```julia
using Polymake

str = read("points.demo", String)
# eval/parse is a hack for Rational input, don't do this at home!
matrix_str = "["*replace(str, "/"=>"//")*"]"
matrix = eval(Meta.parse(matrix_str))
@show matrix

p = @pm Polytope.Polytope(POINTS=matrix)

@show p.FACETS # polymake matrix of polymake rationals
@show Polytope.dim(p) # Julia Int64
# note that even in Polymake property DIM is "fake" -- it's actually a function
@show p.VERTEX_SIZES # polymake array of ints
@show p.VERTICES

for (i, vsize) in enumerate(p.VERTEX_SIZES)
  if vsize == Polytope.dim(p)
    println("$i : $(p.VERTICES[i,:])")
    # $i will be shifted by one from the polymake version
  end
end

simple_verts = [i for (i, vsize) in enumerate(p.VERTEX_SIZES) if vsize == Polytope.dim(p)] # Julia vector of Int64s

special_points = p.VERTICES[simple_verts, :] # polymake Matrix of rationals
@show special_points;
```

The script included (i.e. in running REPL execute `include("example_script.jl");`) produces the following output:
```
matrix = Rational{Int64}[1//1 0//1 0//1 0//1; 1//1 1//16 1//4 1//16; 1//1 3//8 1//4 1//32; 1//1 1//4 3//8 1//32; 1//1 1//16 1//16 1//4; 1//1 1//32 3//8 1//4; 1//1 1//4 1//16 1//16; 1//1 1//32 1//4 3//8; 1//1 3//8 1//32 1//4; 1//1 1//4 1//32 3//8]
p.FACETS = pm::Matrix<pm::Rational>
0 -1 20/7 8/7
0 -1 20 -1
0 20/7 -1 8/7
0 20/7 8/7 -1
0 20 -1 -1
1 16/3 16/3 -20/3
0 8/7 20/7 -1
0 8/7 -1 20/7
1 16/3 -20/3 16/3
0 -1 -1 20
0 -1 8/7 20/7
1 -20/3 16/3 16/3
1 -32/21 -32/21 -32/21

(Polymake.Polytope).dim(p) = 3
p.VERTEX_SIZES = pm::Array<int>
9 3 4 4 3 4 3 4 4 4
p.VERTICES = pm::Matrix<pm::Rational>
1 0 0 0
1 1/16 1/4 1/16
1 3/8 1/4 1/32
1 1/4 3/8 1/32
1 1/16 1/16 1/4
1 1/32 3/8 1/4
1 1/4 1/16 1/16
1 1/32 1/4 3/8
1 3/8 1/32 1/4
1 1/4 1/32 3/8

2 : pm::Vector<pm::Rational>
1 1/16 1/4 1/16
5 : pm::Vector<pm::Rational>
1 1/16 1/16 1/4
7 : pm::Vector<pm::Rational>
1 1/4 1/16 1/16
special_points = pm::Matrix<pm::Rational>
1 1/16 1/4 1/16
1 1/16 1/16 1/4
1 1/4 1/16 1/16


```
As can be seen we show consecutive steps of computations: the input `matrix`, `FACETS`, then we ask for `VERTEX_SIZES`, which triggers the convex hull computation. Then we show vertices and print those corresponding to simple vertices. Finally we collect them in `special_points`.

Note that a `polymake` matrix tries to mimic the behaviour of Julia arrays: `p.VERTICES[2,:]` returns a `1`-dimensional slice (i.e. `pm_Vector`), while passing a set of indices (`p.VERTICES[special_points, :]`) returns a `2`-dimensional one.

#### Notes:

The same minor (up to permutation of rows) could be obtained by using sets: either Julia or polymake sets. However since by default one can not index arrays with sets, we need to collect them first:
```julia
simple_verts = Set(i for (i, vsize) in enumerate(p.VERTEX_SIZES) if vsize == Polytope.dim(p)) # Julia set of Int64s

simple_verts = pm_Set(i for (i, vsize) in enumerate(p.VERTEX_SIZES) if vsize == Polytope.dim(p)) # polymake set of longs

special_points = p.VERTICES[collect(simple_verts), :]
```

## Polymake syntax translation

The following tables explain by example how to quickly translate `polymake` syntax to `Polymake.jl`.

### Variables

| Polymake                              | Julia                                                        |
| ------------------------------------- | ------------------------------------------------------------ |
| `$p` (reference to 'scalar' variable) | `p` (reference to any variable)                              |
| `print $p;`                           | `print(p)` or `println(p)` or `@show p`, or just `p` in REPL |
| `$i=5; $j=6;`                         | `i,j = 5,6` or `i=5; j=6`<br> (`;` is needed for separation, can be used to suppress return value in REPL) |
| `$s = $i + $j; print $s;`             | `s = i + j`                                                  |

### Arrays

| Polymake                                                 | Julia                                                        |
| -------------------------------------------------------- | ------------------------------------------------------------ |
| Linear containers with random access                     | Linear containers with random access + all the algebra attached      |
| `@A = ("a", "b", "c");`                                  | `A = ["a", "b", "c"]`                                        |
| `$first = $A[0];`<br>(`first` is equal to `a`)         | `first = A[1]`<br>(note the `1`-based indexing!)           |
| `@A2 = (3,1,4,2);`                                       | `A2 = [3,1,4,2]`                                             |
| `print sort(@A2);`<br>(a copy of `A2` is sorted)       | `println(sort(A2))`<br>(to sort in place use `sort!(A2))`  |
| `$arr = new Array<Int>([3,2,5]);` <br>(a `C++` object) | `arr = [3,2,5]`<br>(the `Int` type is inferred)            |
| `$arr->[0] = 100;`<br>(assignment)                     | `arr[1] = 100`<br>(assignment; returns `100`)              |

### Dictionaries/Hash Tables

| Polymake                       | Julia                                                         |
| ------------------------------ | ------------------------------------------------------------ |
| `%h = ();`                     | `h = Dict()`<br>it is **MUCH** better to provide types e.g.<br>`h = Dict{String, Int}()` |
|`$h{"zero"}=0; $h{"four"}=4;`   | `h["zero"] = 0; h["four"] = 4`<br>(call returns the value)|
|`print keys %h;`                | `@show keys(h)` (NOTE: order is not specified)              |
|`print join(", ",keys %hash);`  | `join(keys(h), ", ")`<br>(returns `String`)               |
|`%hash=("one",1,"two",2);`      | `Dict([("one",1), ("two",2)])`<br>(will infer types)      |
|`%hash=("one"=>1,"two"=>2);`    | `Dict("one"=>1,"two"=>2)`                                     |

### Sets

| Polymake                      | Julia                                                        |
| ----------------------------- | ------------------------------------------------------------ |
| Balanced binary search trees  | Hash table with no content                                   |
| `$set=new Set<Int>(3,2,5,3);` | `set = Set{Int}([3,2,5,3])`                                  |
| `print $set->size;`           | `length(set)`                                                |
| `@array_from_set=@$set`       | `collect(set)`<br>(NOTE: this creates a `Vector`, but order is NOT specified) |

### Matrices

| Polymake                                                     | Julia                                                        |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| `new Matrix<T>` <br>Container with algebraic operations  | `Matrix{T} = Array{T, 2}`<br>**Linear** container with available indexing by `2`-ples; all algebra attached  |
| `$mat=new Matrix<Rational>([[2,1,4,0,0],[3,1,5,2,1],[1,0,4,0,6]]);`<br>`$row1=new Vector<Rational>([2,1,4,0,0]);`<br>`$row2=new Vector<Rational>([3,1,5,2,1]);`<br>`$row3=new Vector<Rational>([1,0,4,0,6]);`<br>`@matrix_rows=($row1,$row2,$row3);`(`Perl` object)<br>`$matrix_from_array=new Matrix<Rational>(\@matrix_rows);`(`C++` object) | `mat = Rational{Int}[2 1 4 0 0; 3 1 5 2 1; 1 0 4 0 6];`<br>`row1 = Rational{Int}[2, 1, 4, 0, 0];`<br>`row2 = Rational{Int}[3, 1, 5, 2, 1];`<br>`row3 = Rational{Int}[1, 0, 4, 0, 6];`<br>`matrix_rows = hcat(row1', row2', row3')`<br>(Julia stores matrices in **column major** format, so `'` i.e. transposition is needed) |
| `$mat->row(1)->[1]=7; $mat->elem(1,2)=8;`                    | `mat[2,2] = 7; mat[2,3] = 8`                                 |
| `$unit_mat=4*unit_matrix<Rational>(3);` | `unit_mat = Diagonal([4//1 for i in 1:3])` or `UniformScaling(4//1)`<br>depending on application; both require `using LinearAlgebra` |
| `$dense=new Matrix<Rational>($unit_mat);`<br>`$m_rat=new Matrix<Rational>(3/5*unit_matrix<Rational>(5));`<br>`$m2=$mat/$m_rat;`<br>`$m_int=new Matrix<Int>(unit_matrix<Rational>(5));`<br>`$m3=$m_rat/$m_int;`<br>(results in an error due to incompatible types)| `Array(unit_mat)`<br>`m_rat = Diagonal([3//5 for i in 1:5])`<br>`m2 = mat/m_rat`<br>`m_int = Diagonal([1 for i in 1:5])`<br>`m_rat/m_int`<br>(succeeds due to `promote` happening in `/`) |
| `convert_to<Rational>($m_int)`<br>`$z_vec=zero_vector<Int>($m_int->rows)`<br>`$extended_matrix=($z_vec\|$m_int);`<br>(adds `z_vec` as the first column, result is dense) | `convert(Diagonal{Rational{Int}}, m_int)`<br>`z_vec = zeros(Int, size(m_int, 1))`<br>`extended_matrix = hcat(z_vec, m_int)`<br>(result is sparse) |
| `$set=new Set<Int>(3,2,5);`<br>`$template_Ex=new Array<Set<Int>>((new Set<Int>(5,2,6)),$set)` | `set = Set([3,2,5]);`<br> `template_Ex = [Set([5,2,6]), set]` |

### Big objects & properties:

| Polymake                                                     | Julia                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------- |
| `$p=new Polytope<Rational>(POINTS=>cube(4)->VERTICES);`      | `p = @pm Polytope.Polytope(POINTS=Polytope.cube(4).VERTICES)` |
| `$lp=new LinearProgram<Rational>(LINEAR_OBJECTIVE=>[0,1,1,1,1]);` | `lp = @pm Polytope.LinearProgram(LINEAR_OBJECTIVE=[0,1,1,1,1])` |
| `$p->LP=$lp;`<br>`$p->LP->MAXIMAL_VALUE;`                  | `p.LP = lp`<br>`p.LP.MAXIMAL_VALUE`                        |
| `$i = ($p->N_FACETS * $p->N_FACETS) * 15;`                   | `i = (p.N_FACETS * p.N_FACETS) * 15`                         |
| `$print p->DIM;`                                             | `Polytope.dim(p)`<br> `DIM` is actually a faux property, which hides a function beneath |
| `application "topaz";`<br>`$p = new Polytope<Max, QuadraticExtension>(POINTS=>[[1,0,0], [1,1,0], [1,1,1]]);` | `p = @pm Tropical.Polytope{Max, QuadraticExtension}(POINTS=[1 0 0; 1 1 0; 1 1 1])` |

## Current state of the `polymake` wrapper

### Data structures

* Big objects, e.g., Polytopes, can be handled in Julia.
* Several small objects (data types) from `polymake` are available in `Polymake.jl`:
    * Integers (`pm_Integer <: Integer`)
    * Rationals (`pm_Rational <: Real`)
    * Vectors (`pm_Vector <: AbstractVector`) of `pm_Integer`s and `pm_Rational`s
    * Matrices (`pm_Matrix <: AbstractMatrix`) of `Float64`s, `pm_Integer`s and `pm_Rational`
    * Sets (`pm_Set <: AbstractSet`) of `Int32`s and `Int64`s
    * Arrays (`pm_Array <: AbstractVector`, as `pm_Arrays` are one-dimensional) of `Int32`s, `Int64`s and `pm_Integers`
    * some combinations thereof, e.g., `pm_Array`s of `pm_Sets` of `Int32`s.

These data types can be converted to appropriate Julia types,
but are also subtypes of the corresponding Julia abstract types (as indicated above), and so should be accepted by all methods that apply to the abstract types.

**Note**: If the returned small object has not been wrapped in `Polymake.jl`
yet, you will not be able to access its content or in general use it **from Julia**,
however you can always pass it back as an argument to a `polymake` function.
Moreover you may try to convert to Julia understandable type via
`@pm Common.convert_to{wrapped{templated, type}}(obj)`.
For example:

```julia
julia> c = Polytope.cube(3);

julia> f = c.FACETS;
┌ Warning: The return value contains pm::SparseMatrix<pm::Rational, pm::NonSymmetric> which has not been wrapped yet;
│ use `@pm Common.convert_to{wrapped_type}(...)` to convert to julia-understandable type.
└ @ Polymake ~/.julia/dev/Polymake/src/functions.jl:66

julia> f[1,1] # f is an opaque pm::perl::PropertyValue to julia
ERROR: MethodError: no method matching getindex(::Polymake.pm_perl_PropertyValueAllocated, ::Int64, ::Int64)
Stacktrace:
  [...]

julia> m = @pm Common.convert_to{Matrix{Integer}}(f)
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

### Functions

* All user functions from `polymake` are available in the appropriate modules, e.g. `homology` function from `topaz` can be called as `Topaz.homology(...)` in Julia. We pull the docstrings for functions from `polymake` as well, so `?Topaz.homology` (in Julia's REPL) returns a `polymake` docstring. Note: the syntax presented in the docstring is a `polymake` syntax, not `Polymake.jl` one.
* Most of the user functions from `polymake` are available as `Appname.funcname(...)` in `Polymake.jl`.  Moreover, any function from `polymake` `C++` library can be called via `@pm Appname.funcname(...)` macro. If you happen to use a non-user `polymake` function in REPL quite often you might `Polymake.@register Appname.funcname` so that it becomes available for completion. This is a purely convenience macro, as the effects of `@register` will be lost when Julia kernel restarts.
* All big objects of `polymake` can be constructed via `@pm` macro. For example
```perl
$obj = new BigObject<Template,Parameters>(args)
```
becomes
```julia
obj = @pm Appname.BigObject{Templete,Parameters}(args)
```
See Section Polymake syntax translation for concrete examples.
* Properties of big objects are accessible by `bigobject.property` syntax (as opposed to `$bigobject->property` in `polymake`). If there is a missing property (e.g. `Polytope.Polytope` does not have `DIM` property in `Polymake.jl`), please check if it can be accessed by `Appname.property(object)`. For example property `DIM` is exposed as `Polytope.dim(...)` function.
* Methods are available as functions in the appropriate modules, with the first argument as the object, i.e. `$bigobj->methodname(...)` can be called via `Appname.methodname(bigobj, ...)`
* A function in `Polymake.jl` calling `polymake` may return a big or small object, and the generic return (`PropertyValue`) is transparently converted to one of the data types above. If you really care about performance, this conversion can be deactivated by adding `keep_PropertyValue=true` keyword argument to function/method call.

### Function Arguments

Functions in `Polymake.jl` accept the following types for their arguments:
* simple data types (bools, machine integers, floats)
* wrapped native types (`pm_Integer`, `pm_Rational`, `pm_Vector`, `pm_Matrix`, `pm_Set` etc.)
* other objects returned by polymake:
  *  `pm_perl_Object` (essentially Big Objects),
  *  `pm_perl_PropertyValue` (containers opaque to Julia)
<!-- *  `pm_perl_OptionSet` -->

If an object passed to `Polymake.jl` function is of a different type the software will try its best to convert it to such. However, if the conversion doesn't work the `ArgumentError` will be thrown:
```julia
ERROR: ArgumentError: Unrecognized argument type: SomeType.
You need to convert to polymake compatible type first.
```

You can tell `Polymake.jl` how to convert it by definig
```julia
Base.convert(::Type{Polymake.PolymakeType}, ma::SomeType)
```
The returned value must be of one of the types as above. For example to use `AbstractAlgebra` matrices as input to `Polymake.jl` one may define
```julia
Base.convert(::Type{Polymake.PolymakeType}, M::Generic.MatSpaceElem) = pm_Matrix(M.entries)
```
and the following should run smoothly.
```julia
julia> using AbstractAlgebra, Polymake
polymake version 3.4
Copyright (c) 1997-2019
Ewgenij Gawrilow, Michael Joswig (TU Berlin)
https://polymake.org

This is free software licensed under GPL; see the source for copying conditions.
There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


julia> mm = AbstractAlgebra.matrix(ZZ, [1 2 3; 4 5 6])
[1 2 3]
[4 5 6]

julia> @pm Polytope.Polytope(POINTS=mm)
ERROR: ArgumentError: Unrecognized argument type: AbstractAlgebra.Generic.MatSpaceElem{Int64}.
You need to convert to polymake compatible type first.
  [...]

julia> Base.convert(::Type{Polymake.PolymakeType}, M::Generic.MatSpaceElem) = pm_Matrix(M.entries)

julia> @pm Polytope.Polytope(POINTS=mm)
type: Polytope<Rational>

POINTS
1 2 3
1 5/4 3/2

```
