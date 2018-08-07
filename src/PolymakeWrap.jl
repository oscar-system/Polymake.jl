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

const pm_Integer = Polymake.pm_Integer
const pm_Rational = Polymake.pm_Rational
const pm_Vector = Polymake.pm_Vector
const pm_Matrix = Polymake.pm_Matrix

const exists = Polymake.exists
const new_pm_Integer = Polymake.new_pm_Integer
const numerator = Polymake.numerator
const denominator = Polymake.denominator

const application = Polymake.application

include("functions.jl")
include("convert.jl")

end