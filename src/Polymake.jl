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
# FIXME: check with imports of LibPolymake further down
import Base: ==, <, <=, *, -, +, //, ^, div, rem, one, zero,
    append!, deepcopy_internal, delete!, numerator, denominator,
    empty!, Float64, getindex, in, intersect, intersect!, isempty, isfinite,
    length, numerator, push!, resize!,
    setdiff, setdiff!, setindex!, symdiff, symdiff!,
    union, union!
import AbstractAlgebra: should_show_banner

import Pkg
import Downloads
import JSON

using SparseArrays
import SparseArrays: AbstractSparseMatrix, findnz
import SparseArrays

using CxxWrap

using BinaryWrappers
using Scratch
import Pidfile

import Perl_jll
import Ninja_jll
import polymake_jll
import lib4ti2_jll
import TOPCOM_jll
using libpolymake_julia_jll
using polymake_oscarnumber_jll

const jlpolymake_version_range = (v"0.12.0",  v"0.13")

struct PolymakeError <: Exception
    msg
end

function Base.showerror(io::IO, ex::PolymakeError)
    print(io, "polymake: $(ex.msg)")
end

###########################
# Load Cxx stuff and init
##########################

Sys.iswindows() &&
   error("""Windows is not supported, please try the Windows Subsystem for Linux.
            For details please check: https://www.oscar-system.org/install/""")

libpolymake_julia_jll.is_available() ||
   error("""This platform or julia version is currently not supported by Polymake:
            $(Base.BinaryPlatforms.host_triplet())""")

libcxxwrap_build_version() = VersionNumber(unsafe_string(ccall((:jlpolymake_libcxxwrap_build_version,libpolymake_julia), Cstring, ())))

jlpolymake_version() = VersionNumber(unsafe_string(ccall((:jlpolymake_version,libpolymake_julia), Cstring, ())))

function checkversion()
  jlpolymakeversion = jlpolymake_version()
  if !(jlpolymake_version_range[1] <= jlpolymakeversion < jlpolymake_version_range[2])
    error("This version of Polymake.jl requires libpolymake-julia in the range $(jlpolymake_version_range), but version $jlpolymakeversion was found")
  end
end

# Must also be called during precompile
checkversion()

# to keep the scratchspaces of different Polymake.jl folders and julia versions separate
const scratch_key = "polymake_$(string(hash(@__FILE__)))_$(VERSION.major).$(VERSION.minor)"

include("repl.jl")
include("ijulia.jl")

module LibPolymake
  # copied from the top for overriding methods ...
  import Base: ==, <, <=, *, -, +, //, ^, div, rem, one, zero,
    append!, deepcopy_internal, delete!, numerator, denominator,
    empty!, Float64, getindex, in, intersect, intersect!, isempty, isfinite,
    length, numerator, push!, resize!,
    setdiff, setdiff!, setindex!, symdiff, symdiff!,
    union, union!
  using CxxWrap
  using SparseArrays
  import SparseArrays: AbstractSparseMatrix, findnz
  import SparseArrays
  using polymake_jll
  using libpolymake_julia_jll
  using polymake_oscarnumber_jll
  import ..Polymake: libcxxwrap_build_version

  @wrapmodule(() -> joinpath(libpolymake_julia), :define_module_polymake)

  function __init__()

     @initcxx

  end

end
import .LibPolymake

const exclude = [:__init__, :eval, :include]

# for now we just import all libpolymake_julia names except for some julia internal ones
for name in names(LibPolymake; all=true)
   (name in exclude || !isdefined(LibPolymake, name)) && continue
   startswith(string(name), "#") && continue
   startswith(string(name), "__cxxwrap") && continue

   @eval import .LibPolymake: $name
end

module LibOscarNumber
  import Base: ==, <, <=, *, -, +, //, ^, div, rem, one, zero,
    append!, deepcopy_internal, delete!, numerator, denominator,
    empty!, Float64, getindex, in, intersect, intersect!, isempty, isfinite,
    length, numerator, push!, resize!,
    setdiff, setdiff!, setindex!, symdiff, symdiff!,
    union, union!
  using CxxWrap
  using SparseArrays
  import SparseArrays: AbstractSparseMatrix, findnz
  import SparseArrays
  using polymake_jll
  using libpolymake_julia_jll
  using polymake_oscarnumber_jll

  import ..LibPolymake: show_small_obj
  import ..Polymake: libcxxwrap_build_version

  @wrapmodule(() -> joinpath(libpolymake_oscarnumber), :define_module_polymake_oscarnumber)

  function __init__()

     @initcxx

  end

end

import .LibOscarNumber

for name in names(LibOscarNumber; all=true)
   (name in exclude || !isdefined(LibOscarNumber, name)) && continue
   startswith(string(name), "#") && continue
   startswith(string(name), "__cxxwrap") && continue

   @eval import .LibOscarNumber: $name
end

include(libpolymake_julia_jll.generate_deps_tree)

include(type_translator)

_pm_rand_helper() = rand(Int64)

function set_rand_source()
   _default_rand_helper = CxxWrap.@safe_cfunction(_pm_rand_helper, Int64, ())
   set_rand_source(_default_rand_helper)
end

function __init__()

    binpaths = [
                 @generate_wrappers(lib4ti2_jll),
                 @generate_wrappers(TOPCOM_jll),
                 @generate_wrappers(Ninja_jll),
                 @generate_wrappers(Perl_jll),
               ]

    # to avoid conflicts between symlinks and directories we switch to a new depstree folder name
    polymake_deps_tree = @get_scratch!("$(scratch_key)_depstree_v2")

    @static if isdefined(Downloads, :default_downloader!)
      # work around long Downloads.jl timer
      Downloads.default_downloader!(Downloads.Downloader(grace=0.01))
    end
    # we run this on every init to make sure all artifacts still exist
    # (this code should be race condition free even with multiple processes)
    prepare_deps_tree(polymake_deps_tree)
    @static if isdefined(Downloads, :default_downloader!)
      # restore default
      Downloads.default_downloader!()
    end

    polymake_user_dir = @get_scratch!("$(scratch_key)_userdir")

    # check libpolymake_julia version with a plain ccall before initializing libcxxwrap and libpolymake
    checkversion()

    # prepare environment variables
    # these are needed for the whole session
    ENV["PATH"] = join([binpaths...,ENV["PATH"]], ":")
    ENV["POLYMAKE_DEPS_TREE"] = polymake_deps_tree
    installtop = joinpath(polymake_deps_tree, "share", "polymake")
    installarch = joinpath(polymake_deps_tree, "lib", "polymake")

    extensions = [(polymake_oscarnumber_jll, "oscarnumber")]
    extensionpaths = []

    exttop = joinpath("share", "polymake", "ext")
    extarch = joinpath("lib", "polymake", "ext")
    target(name...) = joinpath(polymake_deps_tree, name...)
    mkpath(target(exttop))
    mkpath(target(extarch))

    for (ext, dirname) in extensions
       src(name...) = joinpath(ext.artifact_dir, name...)
       force_symlink(src(exttop, dirname), target(exttop, dirname))
       force_symlink(src(extarch, dirname), target(extarch, dirname))
       push!(extensionpaths, target(exttop, dirname))
    end

    polymake_extension_config = joinpath(polymake_deps_tree, "extensions.json")
    tmpfile = tempname(polymake_deps_tree; cleanup=false)
    open(tmpfile, "w") do file
       JSON.print(file, Dict("Polymake::User::extensions" => extensionpaths))
    end
    Base.Filesystem.rename(tmpfile, polymake_extension_config)

    # Temporarily unset PERL5LIB during initialization
    # This variable can cause errors if the perl modules in this folder were not
    # built with the same configuration as Perl_jll.
    # If this is really intended please set POLYMAKE_FORCE_PERL5LIB to "true".
    adjustenv = Dict{String,Union{String,Nothing}}()
    if !isempty(get(ENV,"PERL5LIB","")) && get(ENV, "POLYMAKE_FORCE_PERL5LIB", false) != "true"
       adjustenv["PERL5LIB"] = nothing
    end


    withenv(adjustenv...) do
       try
           show_banner = should_show_banner() &&
                          !any(x->x.name in ["Oscar"], keys(Base.package_locks))
           mkpath(polymake_user_dir)
           # lock to avoid race-conditions when recompiling wrappers in multiple processes
           Pidfile.mkpidlock("$(polymake_user_dir)/userdir.lock") do
               initialize_polymake_with_dir("$(polymake_extension_config);user=$(polymake_user_dir)", installtop, installarch, show_banner)
           end
           if !show_banner
               shell_execute(raw"$Verbose::credits=\"0\";")
           end
       catch ex # initialize_polymake may throw jl_error
           ex isa ErrorException && throw(PolymakeError(ex.msg))
           rethrow(ex)
       end

       application("common")
       shell_execute("include(\"$(joinpath(@__DIR__, "polymake", "julia.rules"))\");")

       # try using wslviewer to open threejs / svg / pdf properly on WSL
       # Note: the binfmt_misc check might not detect all cases of wsl but we need exactly
       # that feature enabled to be able to launch a windows process for the visualization
       # alternative check might be: WSL2 occuring in /proc/sys/kernel/osrelease
       if Sys.islinux() && isfile("/proc/sys/fs/binfmt_misc/WSLInterop")
           configure_wslview(force=false);
       end

       # work around issue with lp2poly and looking up perl modules from different applications
       application("polytope")
       shell_execute("require LPparser;")

       # workaround until next polymake release to make sure mcf does not get stuck
       Polymake.shell_execute(raw"""
                              if (application("graph")->configured->{"mcf.rules"} > 0) {
                                $mcf = "$mcf -q" unless ($mcf =~ / -q/);
                              }
                              """)

       for app in call_function(:common, :startup_applications)
           application(app)
       end
       application("common")
    end

    set_rand_source()

    # We need to set the Julia types as c types for polymake
    for (name, c_type) in C_TYPES
        current_type = Ptr{Cvoid}(pointer_from_objref(c_type))
        set_julia_type(name, current_type)
    end

    # oscarnumber types
    on_type = Ptr{Cvoid}(pointer_from_objref(OscarNumber))
    set_julia_type("OscarNumber", on_type)
    for (name, c_type) in [("Array", Array),
                           ("Vector", Vector),
                           ("Matrix", Matrix),
                           ("SparseVector", SparseVector),
                           ("SparseMatrix", SparseMatrix)]
        current_type = Ptr{Cvoid}(pointer_from_objref(c_type{OscarNumber}))
        set_julia_type("$(name)_OscarNumber", current_type)
    end


    if isdefined(Base, :active_repl)
        run_polymake_repl()
    end

    if isdefined(Main, :IJulia) && Main.IJulia.inited
        prepare_jupyter_kernel_for_visualization()
    end
    # this will disable callbacks for oscarnumber gc free calls
    # to avoid some crashes during exit
    # the data will be cleaned anyway once the iddict is cleared
    Base.atexit() do
        Polymake.oscarnumber_prepare_cleanup()
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
include("quadraticextension.jl")
include("oscarnumber.jl")
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
include("map.jl")

include("polymake_direct_calls.jl")

include("generate_applications.jl")

include("get_attachment.jl")

include("polydb.jl")
end # of module Polymake
