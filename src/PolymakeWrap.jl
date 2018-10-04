module PolymakeWrap

module Polymake

    const foo = 1

    import Base: ==,
        delete!,
        empty!,
        getindex,
        in, intersect, intersect!, isempty,
        length,
        push!,
        setdiff, setdiff!, symdiff, symdiff!,
        union, union!

    using CxxWrap

    @wrapmodule(joinpath(@__DIR__, "..", "deps", "src", "libpolymake.so"),
        :define_module_polymake)
    
    function __init__()
        @initcxx
    end
end

import .Polymake

function __init__()
    Polymake.init()
    Polymake.application("polytope")
    Polymake.set_julia_types(Polymake)
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

    :swap,
    :incl,

    :range,
    :sequence,
    :scalar2set,

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
include("sets.jl")

end
