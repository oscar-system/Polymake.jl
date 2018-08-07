module PolymakeWrap

module Polymake
    using CxxWrap
    pm_dir = Pkg.dir("PolymakeWrap", "deps", "src","libpolymake.so")
    wrap_module(pm_dir,Polymake)
end

import .Polymake

function __init__()
    Polymake.init()
    Polymake.application("polytope")
end

const SmallObject = Union{Polymake.pm_Integer,
                          Polymake.pm_Rational,
                          Polymake.pm_Matrix,
                          Polymake.pm_Vector}

include("functions.jl")
include("convert.jl")

end