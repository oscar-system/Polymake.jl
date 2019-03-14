# Polymake.jl

[![Build Status](https://travis-ci.com/oscar-system/Polymake.jl.svg?branch=master)](https://travis-ci.com/oscar-system/Polymake.jl)

Julia package for using [polymake](https://polymake.org/doku.php), a software for research in polyhedral geometry.
This package is developed as part of the [OSCAR](https://oscar.computeralgebra.de) project.

**Index:**
* [Installation](#installation)
* [Examples](#examples)
* [Polymake syntax translation](#polymake-syntax-translation)
* [Current state](#current-state)

## Installation

The installation can be done in the Julia REPL by first pressing `]` and then
```julia
pkg> add https://github.com/oscar-system/Polymake.jl
```
This will fetch a pre-build binary of `polymake`. You are ready to start `using Polymake`.

### Your own installation of `polymake`

If you already have a recent enough version of polymake on your system, you either need to make `polymake-config` available in your `PATH` or the environment variable `POLYMAKE_CONFIG` needs to point to the correct `polymake-config` file.

After this just `add` the package url as above, the build script will use your `polymake` installation.

### `polymake` from source

The current version of `Polymake.jl` relies on an unreleased version of polymake. A compatible version is available at [polymake/polymake#snapshots](https://github.com/polymake/polymake/tree/Snapshots).
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
Note that polymake might take some time to compile.

After this start `julia` and just `add` the `Polymake.jl` from url as above.

### `Polymake.jl` in a separate environment:
First clone `Polymake.jl`:
```
git clone https://github.com/oscar-system/Polymake.jl.git
```
In Julia REPL press `]` for `pkg` mode and
```julia
(v1.0) pkg> activate Polymake.jl
(Polymake) pkg> instantiate
(Polymake) pkg> build Polymake # fetches the prebuild polymake binaries
(Polymake) pkg> test Polymake # and You are good to go!
```
If `polymake-config` is in your `PATH`, or `POLYMAKE_CONFIG` environment variable is set the `build` phase will try to use it.

Just remember that You need to `activate Polymake.jl` to use `Polymake`.

## Examples

polymake big objects (like `Polytope`, `Cone`, etc) can be created with the `@pm` macro:
```julia
# Call the Polytope constructor
julia> p = @pm Polytopes.Polytope(POINTS=[1 -1 -1; 1 1 -1; 1 -1 1; 1 1 1; 1 0 0])
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

## Polymake syntax translation

The following tables explain by example how to quickly translate `Polymake` syntax to `Polymake.jl`.

### Variables

| Polymake                              | Julia                                                        |
| ------------------------------------- | ------------------------------------------------------------ |
| `$p` (reference to 'scalar' variable) | `p` (reference to any variable)                              |
| `print $p;`                           | `print(p)` or `println(p)` or `@show p`, or just `p` in REPL |
| `$i=5; $j=6;`                         | `i,j = 5,6` or `i=5; j=6` (`;` is needed for separation, <br />can be used to suppress return value in REPL) |
| `$s = $i + $j; print $s;`             | `s = i + j`                                                  |

### Arrays

| Polymake                                                 | Julia                                                        |
| -------------------------------------------------------- | ------------------------------------------------------------ |
| Linear containers with random access                     | Linear containers with random access + all the algebra attached      |
| `@A = ("a", "b", "c");`                                  | `A = ["a", "b", "c"]`                                        |
| `$first = $A[0];`<br />(`first` is equal to `a`)         | `first = A[1]`<br />(note the `1`-based indexing!)           |
| `@A2 = (3,1,4,2);`                                       | `A2 = [3,1,4,2]`                                             |
| `print sort(@A2);` <br />(a copy of `A2` is sorted)      | `println(sort(A2))` <br />(to sort in place use `sort!(A2))` |
| `$arr = new Array<Int>([3,2,5]);` <br />(a `C++` object) | `arr = Int[3,2,5]` <br />(although the type would have been inferred) |
| `$arr->[0] = 100;`<br />(assignment)                     | `arr[1] = 100` <br />(assignment; returns `100`)             |

### Dictionaries/Hash Tables

| Polymake                       | Julia                                                        |
| ------------------------------ | ------------------------------------------------------------ |
| `%h = ();`                     | `h = Dict()`<br />it is **MUCH** better to provide types, e.g.<br />`h = Dict{String, Int}()` |
| `$h{"zero"}=0; $h{"four"}=4;`  | `h["zero"] = 0; h["four"] = 4`<br />(call returns the value) |
| `print keys %h;`               | `@show keys(h)` (order is not specified)                     |
| `print join(", ",keys %hash);` | `join(keys(h), ", ")`<br />(returns `String`)                |
| `%hash=("one",1,"two",2);`     | `Dict([("one",1), ("two",2)])`<br />(will infer types)       |
| `%hash=("one"=>1,"two"=>2);`   | `Dict("one"=>1,"two"=>2)`<br />(will infer types)            |
|                                |                                                              |

### Sets

| Polymake                      | Julia                                                        |
| ----------------------------- | ------------------------------------------------------------ |
| Balanced binary search trees  | Hash table with no content                                   |
| `$set=new Set<Int>(3,2,5,3);` | `set = Set{Int}([3,2,5,3])`                                  |
| `print $set->size;`           | `length(set)`                                                |
| `@array_from_set=@$set`       | `collect(set)` <br />(creates a `Vector` , order is not specified) |
|                               |                                                              |

### Matrices

| Polymake                                                     | Julia                                                        |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| Containers with algebraic operations                         | `Matrix{T} = Array{T, 2}` – (linear) container of elements of type `T` with available indexing by `2`-ples; all algebra attached |
| `$mat=new Matrix<Rational>([[2,1,4,0,0],[3,1,5,2,1],[1,0,4,0,6]]);` | `mat = Rational{Int}[2 1 4 0 0; 3 1 5 2 1; 1 0 4 0 6]`       |
| `$row1=new Vector<Rational>([2,1,4,0,0]); $row2=new Vector<Rational>([3,1,5,2,1]); $row3=new Vector<Rational>([1,0,4,0,6]);` <br />`@matrix_rows=($row1,$row2,$row3);` (`Perl` object)<br />`$matrix_from_array=new Matrix<Rational>(\@matrix_rows);`(`C++` object) | `row1 = Rational{Int}[2, 1, 4, 0, 0]; row2 = Rational{Int}[3, 1, 5, 2, 1]; row3 = Rational{Int}[1, 0, 4, 0, 6];`<br />`matrix_rows = hcat(row1', row2', row3')`<br />(Julia stores matrices in **column major** format, so `'` i.e. transposition is needed) |
| `$mat->row(1)->[1]=7; $mat->elem(1,2)=8;`                    | `mat[2,2] = 7; mat[2,3] = 8`                                 |
| `$unit_mat=4*unit_matrix<Rational>(3);`                      | `unit_mat = Diagonal([4//1 for i in 1:3])`<br />or `UniformScalin(4//1)`, depending on application (both require `using LinearAlgebra`) |
| `$dense=new Matrix<Rational>($unit_mat);`                    | `Array(unit_mat)`                                            |
| `$m_rat=new Matrix<Rational>(3/5*unit_matrix<Rational>(5));`<br />`$m2=$mat/$m_rat;` | `m_rat = Diagonal([3//5 for i in 1:5])`<br />`m2 = mat/m_rat` |
| `$m_int=new Matrix<Int>(unit_matrix<Rational>(5));`<br />`$m3=$m_rat/$m_int;`<br />(results in an error due to incompatible types) | `m_int = Diagonal([1 for i in 1:5])`<br />`m_rat/m_int`<br />(succeeds due to `promote` happening in `/`) |
| `convert_to<Rational>($m_int)`                               | `convert(Diagonal{Rational{Int}}, m_int)`                    |
| `$z_vec=zero_vector<Int>($m_int->rows)`<br />`$extended_matrix=($z_vec\|$m_int);`<br />(adds `z_vec` as the first column, result is dense) | `z_vec = zeros(Int, size(m_int, 1))`<br />`extended_matrix = hcat(z_vec, m_int)`<br />(result is sparse) |
| `$set=new Set<Int>(3,2,5);`<br />`$template_Ex=new Array<Set<Int>>((new Set<Int>(5,2,6)),$set)` | `set = Set([3,2,5]); template_Ex = [Set([5,2,6]), set]`      |
| `$p=new Polytope<Rational>(POINTS=>cube(4)->VERTICES);`<br />`$lp=new LinearProgram<Rational>(LINEAR_OBJECTIVE=>[0,1,1,1,1]);`<br />`$p->LP=$lp;`<br />`$p->LP->MAXIMAL_VALUE;` | `p = @pm Polytopes.Polytope(:POINTS=>Polymake.Polytopes.cube(4).VERTICES)`<br />`lp = @pm Polytopes.LinearProgram(:LINEAR_OBJECTIVE=>[0,1,1,1,1])`<br />`p.LP = lp`<br />`p.LP.MAXIMAL_VALUE` |
| `$i = ($p->N_FACETS * $p->N_FACETS) * 15;`                   | `i = (p.N_FACETS * p.N_FACETS) * 15`                         |

### Example script

The following script is modelled on the one from the polymake tutorial:

```julia
using Polymake

str = read("points.demo", String)
matrix_str = "["*replace(replace(str, "\n"=>";"), "/"=>"//")*"]"
matrix = eval(Base.Meta.parse(matrix_str))
@show matrix

p = @pm Polytopes.Polytope(:POINTS=>matrix)

@show p.FACETS # polymake matrix of polymake rationals
@show Polymake.Polytopes.DIM(p) # julias Int64
# note that even in Polymake property DIM is "fake" -- it's actually a function
@show p.VERTEX_SIZES # polymake array of ints

for (i, vsize) in enumerate(p.VERTEX_SIZES)
  if vsize == Polymake.Polytopes.DIM(p)
    println("$i : $(p.VERTICES[i,:])")
    # $i will be shifted by one from the polymake version
  end
end

s = [i for (i, vsize) in enumerate(p.VERTEX_SIZES) if vsize == Polymake.Polytopes.DIM(p)] # julias vector of Int64s
# note that sets are unordered in julia
unique!(s)

special_points = p.VERTICES[s, :] # julia Matrix of polymake pationals
@show special_points
```

The script included (i.e. in running REPL execute `include("example_script.jl")`) produces the following output:
```
matrix = Rational{Int64}[1//1 0//1 0//1 0//1; 1//1 1//16 1//4 1//16; 1//1 3//8 1//4 1//32; 1//1 1//4 3//8 1//32; 1//1 1//16 1//16 1//4; 1//1 1//32 3//8 1//4; 1//1 1//4 1//16 1//16; 1//1 1//32 1//4 3//8; 1//1 3//8 1//32 1//4; 1//1 1//4 1//32 3//8]
p.FACETS = pm::Matrix<pm::Rational>
21 -32 -32 -32
0 20 8 -7
0 20 -7 8
0 8 20 -7
0 20 -1 -1
0 8 -7 20
3 16 16 -20
0 -1 20 -1
3 16 -20 16
0 -7 20 8
0 -7 8 20
3 -20 16 16
0 -1 -1 20

(Polymake.Polytopes).DIM(p) = 3
p.VERTEX_SIZES = pm::Array<int>
9 3 4 4 3 4 3 4 4 4
2 : pm_Rational[1, 1/16, 1/4, 1/16]
5 : pm_Rational[1, 1/16, 1/16, 1/4]
7 : pm_Rational[1, 1/4, 1/16, 1/16]
special_points = pm_Rational[1 1/16 1/4 1/16; 1 1/16 1/16 1/4; 1 1/4 1/16 1/16]
3×4 Array{pm_Rational,2}:
 1  1/16   1/4  1/16
 1  1/16  1/16   1/4
 1   1/4  1/16  1/16
```
As can be seen we show `matrix`, `FACETS`, `DIM` and `VERTEX_SIZES`.
Then we print rows corresponding to simple vertices and show `special_points`.
The last ouptut is the return of the `include(...)` function (i.e. the last statement in the `example_script.jl`).
To suppress it just execute `include("example_script.jl);`.

#### Notes:

The same minor (up to permutation of rows) could be obtained by using sets, or the identical minor by using (ordered) polymake sets.
Just remember to `collect` the set to a vector when indexing `VERTICES`.
```julia
s = Set(i for (i, vsize) in enumerate(p.VERTEX_SIZES) if vsize == Polymake.Polytopes.DIM(p))
# s is julias set of Int64s

s = pm_Set(i for (i, vsize) in enumerate(p.VERTEX_SIZES) if vsize == Polymake.Polytopes.DIM(p))
# polymake set of longs

special_points = p.VERTICES[collect(s), :]
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
