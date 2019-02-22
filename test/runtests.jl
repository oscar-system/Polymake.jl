using Polymake
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

# write your own tests here
@testset "Polymake" begin
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
