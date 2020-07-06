using CxxWrap
using BinaryProvider
using Base.Filesystem
import Pkg
import CMake
using Libdl

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS

# Dependencies that must be installed before this package can be built
dependencies = [
    "build_bliss.v0.73.0.jl",
    "build_boost.v1.71.0.jl",
    "build_cddlib.v0.94.10.jl",
    "build_FLINT.v0.0.2.jl",
    "build_GMP.v6.1.2.jl",
    "build_libpolymake_julia.v0.0.2.jl",
    "build_lrslib.v0.1.0.jl",
    "build_MPFR.v4.0.2.jl",
    "build_Ncurses.v6.1.0.jl",
    "build_Ninja.v1.10.0.jl",
    "build_normaliz.v3.8.4.jl",
    "build_PPL.v1.2.0.jl",
    "build_Perl.v5.30.3.jl",
    "build_polymake.v4.1.1.jl",
    "build_Readline.v8.0.4.jl",
]


pm_config = joinpath(@__DIR__,"usr","bin","polymake-config")
perl = joinpath(@__DIR__,"usr","bin","perl")
use_binary = true
depsjl = ""

#if haskey(ENV, "LIBPOLYMAKE_JULIA")
#    try
#        lpj = ENV["LIBPOLYMAKE_JULIA"]
#        global libpolymake_julia = joinpath(lpj,"lib","libpolymake_julia.$(Libdl.dlext)")
#        global type_translator = joinpath(lpj,"share","libpolymake_julia","type_translator.jl")
#        @assert ispath(libpolymake_julia)
#        global perl = "perl"
#        global use_binary = false
#    catch err
#        if err isa AssertionError
#            @error("Environment variable LIBPOLYMAKE_JULIA does not point to a valid `libpolymake_julia` installation.")
#        end
#        rethrow(err)
#    end
#end

products = Array{Product,1}()

if use_binary
    # Install unsatisfied or updated dependencies:
    pm_bin_prefix = joinpath(@__DIR__,"usr")
    if isdir(pm_bin_prefix)
        # make sure we can overwrite all the directories (e.g. ncurses)
        run(`chmod -R u+w $(pm_bin_prefix)`)
    end
    # Download and install binaries
    for dependency in dependencies          # We do not check for already installed dependencies
        build_file = joinpath(@__DIR__, dependency)
        m = @eval module $(gensym()); include($build_file); end
        append!(products, m.products)
    end

    depsjl = :(
        function prepare_env()
            ENV["POLYMAKE_USER_DIR"] = abspath(joinpath(Pkg.depots1(),"polymake_user"));
            ENV["PATH"] = ENV["PATH"]*":"*joinpath($pm_bin_prefix,"bin");
        end
        )
    eval(depsjl)
    prepare_env()

    rex = Regex("\\s+'$(@__DIR__).*'\\s?=>\\s?'(?<wrappers_dir>wrappers\\.\\d+)'\\s?,?")
    customize_file = joinpath(ENV["POLYMAKE_USER_DIR"], "customize.pl")
    if isfile(customize_file)
        for l in readlines(customize_file)
            m = match(rex, l)
            if m !== nothing && m[:wrappers_dir] !== nothing
                wrappers = joinpath(ENV["POLYMAKE_USER_DIR"], m[:wrappers_dir])
                @info "Removing $(wrappers)"
                rm(wrappers, force=true, recursive=true)
            end
        end
    end

    pm_config_ninja = joinpath(pm_bin_prefix,"lib","polymake","config.ninja")
    run(`$perl -pi -e "s{/workspace/destdir}{$pm_bin_prefix}g" $pm_config_ninja`)

    # adjust signal used for initalization purposes to avoid problems
    run(`$perl -pi -e "s/SIG{INT}/SIG{USR1}/g" $pm_bin_prefix/share/polymake/perllib/Polymake/Main.pm`)
end

# FIXME:
# - check libpolymake_julia version
# - check polymake version
# - how to find polymake for non-binary libpolymake_julia 
# - pin cxxwrap version?

minimal_polymake_version = v"4.0"

#pm_version = read(`$perl $pm_config --version`, String) |> chomp |> VersionNumber
#if pm_version < minimal_polymake_version
#    error("Polymake version $pm_version is older than minimal required version $minimal_polymake_version")
#end

# remove old deps.jl first to avoid problems when switching from binary installation
rm(joinpath(@__DIR__,"deps.jl"), force=true)

if use_binary
    # Write out a deps.jl file that will contain mappings for our products
    write_deps_file(joinpath(@__DIR__, "deps.jl"), Array{Product,1}(products), verbose=verbose)
end

println("appending to deps.jl file")
open(joinpath(@__DIR__,"deps.jl"), "a") do f
   println(f, "const using_binary = $use_binary")
   println(f, depsjl)
end
