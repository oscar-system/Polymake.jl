module PolymakeWrap

module Polymake

    import Base: ==, union!, intersect!, setdiff!, symdiff!

    using CxxWrap
    pm_dir = Pkg.dir("PolymakeWrap", "deps", "src","libpolymake.so")
    wrap_module(pm_dir,Polymake)
end

function __init__()
    Polymake.init()
    Polymake.application("polytope")
end

for T in [
    :pm_Integer,
    :pm_Rational,
    :pm_Matrix,
    :pm_Vector,
    :pm_Set,
    :exists,
    :new_pm_Integer,
    :numerator,
    :denominator,
    :application,
    :clear,
    :reset,
    :resize,
    :swap,
    :size,
    :empty,
    :contains,
    :collect,
]
    @eval begin
        const $T = Polymake.$T
    end
end

const SmallObject = Union{Polymake.pm_Integer,
                          Polymake.pm_Rational,
                          Polymake.pm_Matrix,
                          Polymake.pm_Vector,
                          Polymake.pm_Set
                          }

include("functions.jl")
include("convert.jl")

end