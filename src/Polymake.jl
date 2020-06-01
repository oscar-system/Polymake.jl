"""
`Polymake.jl` is the Julia interface to `polymake`, an open source software for research in polyhedral geometry.

For more information see:
 > https://polymake.org/doku.php
 >
 > https://github.com/oscar-system/Polymake.jl
"""
module Polymake

export @pm, @convert_to, visual

# We need to import all functions which will be extended on the Cxx side
import Base: ==, <, <=, *, -, +, //, ^, div, rem, one, zero,
    append!, delete!, numerator, denominator,
    empty!, Float64, getindex, in, intersect, intersect!, isempty,
    length, numerator, push!, resize!,
    setdiff, setdiff!, setindex!, symdiff, symdiff!,
    union, union!

using SparseArrays
import SparseArrays: AbstractSparseMatrix, findnz
import SparseArrays

using CxxWrap
import Libdl.dlext

# LoadFlint is needed to initialize the flint malloc functions
# to the corresponding julia functions.
# See also https://github.com/Nemocas/Nemo.jl/issues/788
import LoadFlint

struct PolymakeError <: Exception
    msg
end

function Base.showerror(io::IO, ex::PolymakeError)
    print(io, "Exception occured at Polymake side:\n$(ex.msg)")
end

function check_jlcxx_version(version)
    current_jlcxx = VersionNumber(unsafe_string(ccall(:cxxwrap_version_string, Cstring, ())))
    if (version != current_jlcxx)
        error("""JlCxx version changed, please run `using Pkg; Pkg.build("Polymake");`""")
    end
end

###########################
# Load Cxx stuff and init
##########################

Sys.isapple() || Sys.islinux() || error("System is not supported!")

deps_dir = joinpath(@__DIR__, "..", "deps")

isfile(joinpath(deps_dir,"jlcxx_version.jl")) &&
    isfile(joinpath(deps_dir,"deps.jl")) ||
    error("""Please run `using Pkg; Pkg.build("Polymake");`""")

include(joinpath(deps_dir,"jlcxx_version.jl"))

check_jlcxx_version(jlcxx_version)

@wrapmodule(joinpath(deps_dir, "src", "libpolymake.$dlext"), :define_module_polymake)

include("generated/type_translator.jl")

include("repl.jl")
include("ijulia.jl")

include(joinpath(deps_dir,"deps.jl"))

function __init__()
    check_jlcxx_version(jlcxx_version)
    @initcxx

    if using_binary
        check_deps()
        prepare_env()
    end

    try
        show_banner = isinteractive() &&
                       !any(x->x.name in ["Oscar"], keys(Base.package_locks))

        initialize_polymake(show_banner)
        if !show_banner
            shell_execute(raw"$Verbose::credits=\"0\";")
        end
    catch ex # initialize_polymake may throw jl_error
        ex isa ErrorException && throw(PolymakeError(ex.msg))
        rethrow(ex)
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
include("std/lists.jl")
include("vectors.jl")
include("matrices.jl")
include("sparsematrix.jl")
include("sparsevector.jl")
include("broadcast.jl")
include("arrays.jl")
include("incidencematrix.jl")
include("tropicalnumber.jl")
include("polynomial.jl")

include("polymake_direct_calls.jl")

include("generate_applications.jl")
end # of module Polymake
