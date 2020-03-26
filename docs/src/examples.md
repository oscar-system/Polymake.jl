# Examples

In this section we just highlight various possible uses of `Polymake.jl`. Please refer to [Polymake syntax translation](#polymake-syntax-translation) for more thorough treatment.

`polymake` big objects (like `Polytope`, `Cone`, etc) constructors live within modules named after `polymake` applications, e.g.

```julia
# Call the Polytope constructor
julia> p = polytope.Polytope(POINTS=[1 -1 -1; 1 1 -1; 1 -1 1; 1 1 1; 1 0 0])
type: Polytope<Rational>

POINTS
1 -1 -1
1 1 -1
1 -1 1
1 1 1
1 0 0

```
Parameters to constructors can be passed as keyword arguments only.
All the keys *must* be compatible with `polymake` input attribute names.

Properties of such objects can be accessed by the `.` syntax:
```
julia> p.INTERIOR_LATTICE_POINTS
pm::Matrix<pm::Integer>
1 0 0
```

## Example script

The following script is modelled on the one from the [Using Perl within polymake](https://polymake.org/doku.php/user_guide/tutorials/perl_intro) tutorial:

```julia
using Polymake

str = read("points.demo", String)
# eval/parse is a hack for Rational input, don't do this at home!
matrix_str = "["*replace(str, "/"=>"//")*"]"
matrix = eval(Meta.parse(matrix_str))
@show matrix

p = polytope.Polytope(POINTS=matrix)

@show p.FACETS # polymake matrix of polymake rationals
@show polytope.dim(p) # Julia Int64
# note that even in Polymake property DIM is "fake" -- it's actually a function
@show p.VERTEX_SIZES # polymake array of ints
@show p.VERTICES

for (i, vsize) in enumerate(p.VERTEX_SIZES)
  if vsize == polytope.dim(p)
    println("$i : $(p.VERTICES[i,:])")
    # $i will be shifted by one from the polymake version
  end
end

simple_verts = [i for (i, vsize) in enumerate(p.VERTEX_SIZES) if vsize == polytope.dim(p)] # Julia vector of Int64s

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

Observe that a `polymake` matrix (`Polymake.Matrix`) implements julia abstract array interface: `p.VERTICES[2,:]` returns a `1`-dimensional slice (i.e. `Polymake.Vector`), while passing a set of indices (`p.VERTICES[special_points, :]`) returns a `2`-dimensional one.

### Notes:

The same minor (up to permutation of rows) could be obtained by using sets: either julia or polymake ones. However since by default one can not index arrays with sets, we need to collect them first:
```julia
simple_verts = Set(i for (i, vsize) in enumerate(p.VERTEX_SIZES) if vsize == polytope.dim(p)) # Julia set of Int64s

simple_verts = Polymake.Set(i for (i, vsize) in enumerate(p.VERTEX_SIZES) if vsize == polytope.dim(p)) # polymake set of longs

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
| `$p=new Polytope<Rational>(POINTS=>cube(4)->VERTICES);`      | `p = polytope.Polytope(POINTS=polytope.cube(4).VERTICES)` |
| `$lp=new LinearProgram<Rational>(LINEAR_OBJECTIVE=>[0,1,1,1,1]);` | `lp = polytope.LinearProgram(LINEAR_OBJECTIVE=[0,1,1,1,1])` |
| `$p->LP=$lp;`<br>`$p->LP->MAXIMAL_VALUE;`                  | `p.LP = lp`<br>`p.LP.MAXIMAL_VALUE`                        |
| `$i = ($p->N_FACETS * $p->N_FACETS) * 15;`                   | `i = (p.N_FACETS * p.N_FACETS) * 15`                         |
| `$print p->DIM;`                                             | `polytope.dim(p)`<br> `DIM` is actually a faux property, which hides a function beneath |
| `application "topaz";`<br>`$p = new Polytope<Max, QuadraticExtension>(POINTS=>[[1,0,0], [1,1,0], [1,1,1]]);` | `p = @pm tropical.Polytope{Max, QuadraticExtension}(POINTS=[1 0 0; 1 1 0; 1 1 1])`<br> more information on the @pm macro can be found below |
