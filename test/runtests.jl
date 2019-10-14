if VERSION < v"1.3.0-rc3.0"
    # tosimplex segfaults when called from different thread, see
    # https://github.com/oscar-system/Polymake.jl/issues/144
    # this has been fixed in julia-1.3:
    # https://github.com/JuliaLang/julia/pull/33284
    ENV["OMP_NUM_THREADS"] = 1
end

using Polymake
using Test

# make wrapper compilation verbose on travis
if (haskey(ENV, "TRAVIS"))
    Polymake.shell_execute(raw"$Verbose::cpp=3;")
end

struct MyInt x::Int end # needed in test/convert.jl

# write your own tests here
@testset "Polymake" begin
    include("integers.jl")
    include("rationals.jl")
    include("vectors.jl")
    include("matrices.jl")
    include("sets.jl")
    include("arrays.jl")
    include("convert.jl")
    include("perlobj.jl")
    include("interface_functions.jl")
    include("compat.jl")
end
