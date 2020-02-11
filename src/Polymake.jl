module Polymake

export @pm, visual

# We need to import all functions which will be extended on the Cxx side
import Base: ==, <, <=, *, -, +, //, ^, div, rem, one, zero,
    append!, delete!, numerator, denominator,
    empty!, Float64, getindex, in, intersect, intersect!, isempty,
    length, numerator, push!, resize!,
    setdiff, setdiff!, setindex!, symdiff, symdiff!,
    union, union!

using SparseArrays
import SparseArrays: AbstractSparseMatrix, findnz

using CxxWrap
import Libdl.dlext

import SparseArrays

struct PolymakeError <: Exception
    msg
end

function Base.showerror(io::IO, ex::PolymakeError)
    print(io, "Exception occured at Polymake side:\n$(ex.msg)")
end

###########################
# Load Cxx stuff and init
##########################

Sys.isapple() || Sys.islinux() || error("System is not supported!")

deps_dir = joinpath(@__DIR__, "..", "deps")

@wrapmodule(joinpath(deps_dir, "src", "libpolymake.$dlext"), :define_module_polymake)

include("generated/type_translator.jl")

include("repl.jl")
include("ijulia.jl")

include(joinpath(deps_dir,"deps.jl"))

function __init__()
    @initcxx

    if using_binary
        check_deps()
        prepare_env()
    end

    try
        initialize_polymake(isinteractive())
        if !isinteractive()
            shell_execute(raw"$Verbose::credits=\"0\";")
        end
    catch ex # initialize_polymake throws jl_error
        throw(PolymakeError(ex.msg))
    end

    application("common")
    shell_execute("include(\"$(joinpath(deps_dir, "rules", "julia.rules"))\");")

    for app in call_function(:common, :startup_applications)
        application(app)
    end
    application("common")

    # We need to set the Julia types as c types for polymake
    for (name, c_type) in C_TYPES
        current_type = Ptr{Cvoid}(pointer_from_objref(c_type))
        set_julia_type(name, current_type)
    end

    if isdefined(Base, :active_repl)
        run_polymake_repl()
    end

    if isdefined(Main, :IJulia) && Main.IJulia.inited
        prepare_jupyter_kernel_for_visualization()
    end

end

include("setup_apps.jl")
include("setup_types.jl")
include("util.jl")
include("call_function.jl")

include("perlobj.jl")
include("visual.jl")
include("convert.jl")

include("integers.jl")
include("rationals.jl")
include("sets.jl")
include("vectors.jl")
include("matrices.jl")
include("sparsematrix.jl")
include("broadcast.jl")
include("arrays.jl")
include("incidencematrix.jl")
include("tropicalnumber.jl")
include("polynomial.jl")

include("polymake_direct_calls.jl")

include("generate_applications.jl")
end # of module Polymake
