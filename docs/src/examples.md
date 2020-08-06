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

```@raw html
<table>
  <tr>
    <th>
      Polymake
    </th>
    <th>
      Julia
    </th>
  </tr>
  <tr>
    <td>
      <code>$p</code> (reference to 'scalar' variable)
    </td>
    <td>
      <code>p</code> (reference to any variable)
    </td>
  </tr>
  <tr>
    <td>
      <code>print $p;</code>
    </td>
    <td>
      <code>print(p)</code> or <code>println(p)</code> or <code>@show p</code>, or just <code>p</code> in REPL
    </td>
  </tr>
  <tr>
    <td>
      <code>$i=5; $j=6;</code>
    </td>
    <td>
      <code>i,j = 5,6</code> or <code>i=5; j=6</code><br>
      (<code>;</code> is needed for separation, can be used to suppress return value in REPL)
    </td>
  </tr>
  <tr>
    <td>
      <code>$s = $i + $j; print $s;</code>
    </td>
    <td>
      <code>s = i + j</code>
    </td>
  </tr>
</table>
```

### Arrays

```@raw html
<table>
  <tr>
    <th>
      Polymake
    </th>
    <th>
      Julia
    </th>
  </tr>
  <tr>
    <td>
      Linear containers with random access
    </td>
    <td>
      Linear containers with random access + all the algebra attached
    </td>
  </tr>
  <tr>
    <td>
      <code>@A = ("a", "b", "c");</code>
    </td>
    <td>
      <code>A = ["a", "b", "c"]</code>
    </td>
  </tr>
  <tr>
    <td>
      <code>$first = $A[0];</code>
      <br>(<code>first</code> is equal to <code>a</code>)
    </td>
    <td>
      <code>first = A[1]</code><br>(note the <code>1</code>-based indexing!)
    </td>
  </tr>
  <tr>
    <td>
      <code>@A2 = (3,1,4,2);</code>
    </td>
    <td>
      <code>A2 = [3,1,4,2]</code>
    </td>
  </tr>
  <tr>
    <td>
      <code>print sort(@A2);</code><br>(a copy of <code>A2</code> is sorted)
    </td>
    <td>
      <code>println(sort(A2))</code><br>(to sort in place use <code>sort!(A2))</code>
    </td>
  </tr>
  <tr>
    <td>
      <code>$arr = new Array<Int>([3,2,5]);</code><br>(a <code>C++</code> object)
    </td>
    <td>
      <code>arr = [3,2,5]</code><br>(the <code>Int</code> type is inferred)
    </td>
  </tr>
  <tr>
    <td>
      <code>$arr->[0] = 100;</code><br>(assignment)
    </td>
    <td>
      <code>arr[1] = 100</code><br>(assignment; returns <code>100</code>)
    </td>
  </tr>
</table>
```

### Dictionaries/Hash Tables

```@raw html
<table>
  <tr>
    <th>
      Polymake
    </th>
    <th>
      Julia
    </th>
  </tr>
  <tr>
    <td>
      <code>%h = ();</code>
    </td>
    <td>
      <code>h = Dict()</code><br>it is <b>MUCH</b> better to provide types e.g.<br><code>h = Dict{String, Int}()</code>
    </td>
  </tr>
  <tr>
    <td>
      <code>$h{"zero"}=0; $h{"four"}=4;</code>
    </td>
    <td>
      <code>h["zero"] = 0; h["four"] = 4</code><br>(call returns the value)
    </td>
  </tr>
  <tr>
    <td>
      <code>print keys %h;</code>
    </td>
    <td>
      <code>@show keys(h)</code> (NOTE: order is not specified)
    </td>
  </tr>
  <tr>
    <td>
      <code>print join(", ",keys %hash);</code>
    </td>
    <td>
      <code>join(keys(h), ", ")</code><br>(returns <code>String</code>)
    </td>
  </tr>
  <tr>
    <td>
      <code>%hash=("one",1,"two",2);</code>
    </td>
    <td>
      <code>Dict([("one",1), ("two",2)])</code><br>(will infer types)
    </td>
  </tr>
  <tr>
    <td>
      <code>%hash=("one"=>1,"two"=>2);</code>
    </td>
    <td>
      <code>Dict("one"=>1,"two"=>2)</code>
    </td>
  </tr>
</table>
```

### Sets

```@raw html
<table>
  <tr>
    <th>
      Polymake
    </th>
    <th>
      Julia
    </th>
  </tr>
  <tr>
    <td>
      Balanced binary search trees
    </td>
    <td>
      Hash table with no content
    </td>
  </tr>
  <tr>
    <td>
      <code>$set=new Set<Int>(3,2,5,3);</code>
    </td>
    <td>
      <code>set = Set{Int}([3,2,5,3])</code>
    </td>
  </tr>
  <tr>
    <td>
      <code>print $set->size;</code>
    </td>
    <td>
      <code>length(set)</code>
    </td>
  </tr>
  <tr>
    <td>
      <code>@array_from_set=@$set</code>
    </td>
    <td>
      <code>collect(set)</code><br>(NOTE: this creates a <code>Vector</code>, but order is NOT specified)
    </td>
  </tr>
</table>
```

### Matrices

```@raw html
<table>
  <tr>
    <th>
      Polymake
    </th>
    <th>
      Julia
    </th>
  </tr>
  <tr>
    <td>
      <code>new Matrix<T></code><br>Container with algebraic operations
    </td>
    <td>
      <code>Matrix{T} = Array{T, 2}</code><br>**Linear** container with available indexing by <code>2</code>-ples; all algebra attached
    </td>
  </tr>
  <tr>
    <td>
      <code>$mat=new Matrix<Rational>([[2,1,4,0,0],[3,1,5,2,1],[1,0,4,0,6]]);</code><br><code>$row1=new Vector<Rational>([2,1,4,0,0]);</code><br><code>$row2=new Vector<Rational>([3,1,5,2,1]);</code><br><code>$row3=new Vector<Rational>([1,0,4,0,6]);</code><br><code>@matrix_rows=($row1,$row2,$row3);</code> (<code>Perl</code> object)<br><code>$matrix_from_array=new Matrix<Rational>(\@matrix_rows);</code> (<code>C++</code> object)
    </td>
    <td>
      <code>mat = Rational{Int}[2 1 4 0 0; 3 1 5 2 1; 1 0 4 0 6];</code><br><code>row1 = Rational{Int}[2, 1, 4, 0, 0];</code><br><code>row2 = Rational{Int}[3, 1, 5, 2, 1];</code><br><code>row3 = Rational{Int}[1, 0, 4, 0, 6];</code><br><code>matrix_rows = hcat(row1', row2', row3')</code><br>(Julia stores matrices in <b>column major</b> format, so <code>'</code> i.e. transposition is needed)
    </td>
  </tr>
  <tr>
    <td>
      <code>$mat->row(1)->[1]=7; $mat->elem(1,2)=8;</code>
    </td>
    <td>
      <code>mat[2,2] = 7; mat[2,3] = 8</code>
    </td>
  </tr>
  <tr>
    <td>
      <code>$unit_mat=4*unit_matrix<Rational>(3);</code>
    </td>
    <td>
      <code>unit_mat = Diagonal([4//1 for i in 1:3])</code> or <code>UniformScaling(4//1)</code><br>depending on application; both require <code>using LinearAlgebra</code>
    </td>
  </tr>
  <tr>
    <td>
      <code>$dense=new Matrix<Rational>($unit_mat);</code><br><code>$m_rat=new Matrix<Rational>(3/5*unit_matrix<Rational>(5));</code><br><code>$m2=$mat/$m_rat;</code><br><code>$m_int=new Matrix<Int>(unit_matrix<Rational>(5));</code><br><code>$m3=$m_rat/$m_int;</code><br>(results in an error due to incompatible types)
    </td>
    <td>
      <code>Array(unit_mat)</code><br><code>m_rat = Diagonal([3//5 for i in 1:5])</code><br><code>m2 = mat/m_rat</code><br><code>m_int = Diagonal([1 for i in 1:5])</code><br><code>m_rat/m_int</code><br>(succeeds due to <code>promote</code> happening in <code>/</code>)
    </td>
  </tr>
  <tr>
    <td>
      <code>convert_to<Rational>($m_int)</code><br><code>$z_vec=zero_vector<Int>($m_int->rows)</code><br><code>$extended_matrix=($z_vec\|$m_int);</code><br>(adds <code>z_vec</code> as the first column, result is dense)
    </td>
    <td>
      <code>convert(Diagonal{Rational{Int}}, m_int)</code><br><code>z_vec = zeros(Int, size(m_int, 1))</code><br><code>extended_matrix = hcat(z_vec, m_int)</code><br>(result is sparse)
    </td>
  </tr>
  <tr>
    <td>
      <code>$set=new Set<Int>(3,2,5);</code><br><code>$template_Ex=new Array<Set<Int>>((new Set<Int>(5,2,6)),$set)</code>
    </td>
    <td>
      <code>set = Set([3,2,5]);</code><br> <code>template_Ex = [Set([5,2,6]), set]</code>
    </td>
  </tr>
</table>
```

### Big objects & properties:

```@raw html
<table>
  <tr>
    <th>
      Polymake
    </th>
    <th>
      Julia
    </th>
  </tr>
  <tr>
    <td>
      <code>$p=new Polytope<Rational>(POINTS=>cube(4)->VERTICES);</code>
    </td>
    <td>
      <code>p = polytope.Polytope(POINTS=polytope.cube(4).VERTICES)</code>
    </td>
  </tr>
  <tr>
    <td>
      <code>$lp=new LinearProgram<Rational>(LINEAR_OBJECTIVE=>[0,1,1,1,1]);</code>
    </td>
    <td>
      <code>lp = polytope.LinearProgram(LINEAR_OBJECTIVE=[0,1,1,1,1])</code>
    </td>
  </tr>
  <tr>
    <td>
      <code>$p->LP=$lp;</code><br><code>$p->LP->MAXIMAL_VALUE;</code>
    </td>
    <td>
      <code>p.LP = lp</code><br><code>p.LP.MAXIMAL_VALUE</code>
    </td>
  </tr>
  <tr>
    <td>
      <code>$i = ($p->N_FACETS * $p->N_FACETS) * 15;</code>
    </td>
    <td>
      <code>i = (p.N_FACETS * p.N_FACETS) * 15</code>
    </td>
  </tr>
  <tr>
    <td>
      <code>$print p->DIM;</code>
    </td>
    <td>
      <code>polytope.dim(p)</code><br><code>DIM</code> is actually a faux property, which hides a function beneath
    </td>
  </tr>
  <tr>
    <td>
      <code>application "topaz";</code><br><code>$p = new Polytope<Max, QuadraticExtension>(POINTS=>[[1,0,0], [1,1,0], [1,1,1]]);</code>
    </td>
    <td>
      <code>p = @pm tropical.Polytope{Max, QuadraticExtension}(POINTS=[1 0 0; 1 1 0; 1 1 1])</code><br>more information on the @pm macro can be found
```
here: [`@pm`](@ref)
```@raw html
    </td>
  </tr>
</table>
```
