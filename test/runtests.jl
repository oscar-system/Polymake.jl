using Polymake
using Test

# make wrapper compilation verbose on travis
if (haskey(ENV, "TRAVIS"))
    Polymake.shell_execute(raw"$Verbose::cpp=3;")
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
