using Polymake
using Test
using Polymake.CxxWrap

_with_oscar = false
try
  using Oscar
  println("Running tests with Oscar")
  global _with_oscar = true
catch e
  if !(isa(e, ArgumentError))
    rethrow(e)
  else
    println("Oscar not found, skipping extra OscarNumber tests.")
  end
end

# make wrapper compilation verbose on CI
if (haskey(ENV, "GITHUB_ACTIONS"))
    Polymake.shell_execute(raw"$Verbose::cpp=3;")
end

struct MyInt x::Int end # needed in test/convert.jl

include("Aqua.jl")

include("integers.jl")
include("rationals.jl")
include("quadraticextension.jl")
include("oscarnumber.jl")
include("vectors.jl")
include("sparsevector.jl")
include("matrices.jl")
include("sets.jl")
include("arrays.jl")
include("incidencematrix.jl")
include("convert.jl")
include("perlobj.jl")
include("util.jl")
include("interface_functions.jl")
include("sparsematrix.jl")
include("tropicalnumber.jl")
include("polynomial.jl")
include("pairs.jl")
include("lists.jl")
include("map.jl")
include("graphs.jl")
include("homologygroup.jl")
include("groups.jl")
if get(ENV, "POLYDB_TEST_URI", "") != ""
   include("polydb.jl")
end

# reset verbose wrapper compilation on CI
if (haskey(ENV, "GITHUB_ACTIONS"))
    Polymake.shell_execute(raw"reset_custom $Verbose::cpp;")
end
