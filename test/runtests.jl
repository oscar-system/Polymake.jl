using Polymake
using Test

# write your own tests here
@testset "Polymake" begin

    Polymake.@register Polytope.pseudopower

    include("integers.jl")
    include("rationals.jl")
    include("vectors.jl")
    include("matrices.jl")
    include("sets.jl")
    include("arrays.jl")
    include("perlobj.jl")
    include("interface_functions.jl")
    include("compat.jl")
end
