using Polymake
using Test
using CxxWrap

# make wrapper compilation verbose on travis
if (haskey(ENV, "GITHUB_ACTIONS"))
    Polymake.shell_execute(raw"$Verbose::cpp=3;")
end

struct MyInt x::Int end # needed in test/convert.jl

@testset "Polymake" begin
    include("integers.jl")
    include("rationals.jl")
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
    if get(ENV, "POLYDB_TEST_URI", "") != ""
        include("polydb.jl")
    end
end
