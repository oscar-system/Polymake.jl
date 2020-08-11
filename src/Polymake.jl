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

# needed for setting polymake_user
import Pkg

using SparseArrays
import SparseArrays: AbstractSparseMatrix, findnz
import SparseArrays

using CxxWrap
import Libdl.dlext

# FLINT_jll now initializes the flint malloc functions
# to the corresponding julia functions.
# See also https://github.com/Nemocas/Nemo.jl/issues/788
using FLINT_jll

using Perl_jll
using Ninja_jll
using libpolymake_julia_jll

const jlpolymake_version_range = (v"0.1.0",  v"0.2")

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

libcxxwrap_build_version() = VersionNumber(unsafe_string(ccall((:jlpolymake_libcxxwrap_build_version,libpolymake_julia), Cstring, ())))

jlpolymake_version() = VersionNumber(unsafe_string(ccall((:jlpolymake_version,libpolymake_julia), Cstring, ())))

function checkversion()
  jlpolymakeversion = jlpolymake_version()
  if !(jlpolymake_version_range[1] <= jlpolymakeversion < jlpolymake_version_range[2])
    error("This version of Polymake.jl requires libpolymake-julia in the range $(libpolymake_version_range), but version $jlpolymakeversion was found")
  end
end

# Must also be called during precompile
checkversion()

generated_dir = joinpath(@__DIR__, "generated")

include("repl.jl")
include("ijulia.jl")

@wrapmodule(joinpath(libpolymake_julia), :define_module_polymake)

json_script = joinpath(@__DIR__,"polymake","apptojson.pl")
json_folder = joinpath(generated_dir,"json")
mkpath(json_folder)

polymake_run_script() do runner
   run(`$runner $json_script $json_folder`)
end

include(type_translator)

function __init__()
    if length(get(ENV,"POLYMAKE_CONFIG","")) > 0
         @warn "Setting `POLYMAKE_CONFIG` to use a custom polymake installation is no longer supported. Please use `Overrides.toml` to override `polymake_jll` and `libpolymake_julia_jll`."
    end

    checkversion()

    @initcxx

    global user_dir = abspath(joinpath(Pkg.depots1(),"polymake_user"))
    
    # prepare environment variables
    ENV["PATH"] *= ":" * Ninja_jll.PATH
    ENV["PATH"] *= ":" * Perl_jll.PATH
    ENV["POLYMAKE_USER_DIR"] = user_dir
    mkpath(user_dir)

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
    shell_execute("include(\"$(joinpath(@__DIR__, "polymake", "julia.rules"))\");")

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
include("std/pairs.jl")
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

include("polydb.jl")
end # of module Polymake
