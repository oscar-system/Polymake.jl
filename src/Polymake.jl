module Polymake

module CxxPM
    using CxxWrap

    @wrapmodule(joinpath(@__DIR__, "..", "deps", "src", "libpolymake.so"),
        :define_module_polymake)

    function __init__()
        @initcxx
    end
end

import .CxxPM

function __init__()
    CxxPM.init()
    CxxPM.application("polytope")
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
]
    @eval begin
        const $T = CxxPM.$T
    end
end

const SmallObject = Union{CxxPM.pm_Integer,
                          CxxPM.pm_Rational,
                          CxxPM.pm_Matrix,
                          CxxPM.pm_Vector,
                          CxxPM.pm_Set
                          }

include("functions.jl")
include("convert.jl")

end
