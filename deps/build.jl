using CxxWrap
using BinaryProvider
using Base.Filesystem
import Pkg

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.3/build_Zlib.v1.2.11.jl",
    "https://github.com/benlorenz/XML2Builder/releases/download/v1.0.1-1/build_XML2Builder.v2.9.7.jl",
    "https://github.com/benlorenz/XSLTBuilder/releases/download/v1.1.32/build_XSLTBuilder.v1.1.32.jl",
    "https://github.com/benlorenz/boostBuilder/releases/download/v1.67.0/build_boost.v1.67.0.jl",
    "https://github.com/benlorenz/GMPBuilder/releases/download/v6.1.2-2/build_GMP.v6.1.2.jl",
    "https://github.com/benlorenz/MPFRBuilder/releases/download/v4.0.1-3/build_MPFR.v4.0.1.jl",
    "https://github.com/benlorenz/perlBuilder/releases/download/v5.28.0/build_perl.v5.28.0.jl",
]


pm_config = joinpath(@__DIR__,"usr","bin","polymake-config")
perl = joinpath(@__DIR__,"usr","bin","perl")
use_binary = true
depsjl = ""

if !( haskey(ENV, "POLYMAKE_CONFIG") && ENV["POLYMAKE_CONFIG"] == "no" )
    try
        # test whether polymake config is available in path
        global pm_config = chomp(read(`command -v polymake-config`, String))
        global perl ="perl"
        global use_binary = false
    catch
        if haskey(ENV, "POLYMAKE_CONFIG")
            global pm_config = ENV["POLYMAKE_CONFIG"]
            global perl ="perl"
            global use_binary = false
        end
    end
end

const prefix = Prefix(joinpath(dirname(pm_config),".."))
const polymake = joinpath(prefix,"bin","polymake")

products = Product[
    LibraryProduct(prefix, "libpolymake", :libpolymake)
    ExecutableProduct(prefix,"polymake", :polymake)
    ExecutableProduct(prefix,"polymake-config", Symbol("polymake_config"))
]

# Download binaries from hosted location
bin_prefix = "https://github.com/benlorenz/polymakeBuilder/releases/download/v3.3"

# Listing of files generated by BinaryBuilder:
download_info = Dict(
    Linux(:i686, libc=:glibc, compiler_abi=CompilerABI(:gcc6)) => ("$bin_prefix/polymake.v3.3.0.i686-linux-gnu-gcc6.tar.gz", "67c8d0606618136e389cee64eab3420c5932e249a1dd3b6159b64991e8550bec"),
    Linux(:i686, libc=:glibc, compiler_abi=CompilerABI(:gcc7)) => ("$bin_prefix/polymake.v3.3.0.i686-linux-gnu-gcc7.tar.gz", "9b094f235abc213dee8d19548f32cac1038803052ea16b93461fb7c14d453c81"),
    Linux(:i686, libc=:glibc, compiler_abi=CompilerABI(:gcc8)) => ("$bin_prefix/polymake.v3.3.0.i686-linux-gnu-gcc8.tar.gz", "df5a649b2bab705423ff6fa1ed38f2c0819d42017c4d7a835855aa49ed3cd19c"),
    Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(:gcc6)) => ("$bin_prefix/polymake.v3.3.0.x86_64-linux-gnu-gcc6.tar.gz", "58db546b3954ee25609797cf836c3d5c82dc56005dc3af60219c7d23d200980b"),
    Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(:gcc7)) => ("$bin_prefix/polymake.v3.3.0.x86_64-linux-gnu-gcc7.tar.gz", "5fa4f79758b3332e64cce997f3f4142976d5a6e3c2d8d9d7c6798f793e37408d"),
    Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(:gcc8)) => ("$bin_prefix/polymake.v3.3.0.x86_64-linux-gnu-gcc8.tar.gz", "2885239064d1fdbe025e5eea613cc753497e22e3fcfa22154b201e2b55dbbf54"),
)


if use_binary
    # Install unsatisfied or updated dependencies:
    unsatisfied = any(!satisfied(p; verbose=verbose) for p in products)
    dl_info = choose_download(download_info, platform_key_abi())
    platform = platform_key_abi()
    @info platform
    if dl_info === nothing && unsatisfied
        # If we don't have a BinaryProvider-compatible .tar.gz to download, complain.
        # Alternatively, you could attempt to install from a separate provider,
        # build from source or something even more ambitious here.
        error("""
Your platform $(triplet(platform)) is not supported by this package!
If you already have a polymake installation you need to set the environment variable `POLYMAKE_CONFIG`.
""")
    end
    if unsatisfied || !isinstalled(dl_info...; prefix=prefix)
        # Download and install binaries
        for dependency in dependencies          # We do not check for already installed dependencies
            download(dependency,basename(dependency))
            evalfile(basename(dependency))
        end
        install(dl_info...; prefix=prefix, force=true, verbose=verbose)
    end
     pm_config_ninja = joinpath(libdir(prefix),"polymake","config.ninja")
     pm_bin_prefix = joinpath(@__DIR__,"usr")
     perllib = replace(chomp(read(`$perl -e 'print join(":",@INC);'`,String)),"/workspace/destdir/"=>prefix.path)
     ENV["PERL5LIB"]="$perllib"
     ENV["POLYMAKE_USER_DIR"] = abspath(joinpath(Pkg.depots1(),"polymake_user"))
     run(`$perl -pi -e "s{REPLACEPREFIX}{$pm_bin_prefix}g" $pm_config $pm_config_ninja $polymake`)
     run(`sh -c "$perl -pi -e 's{/workspace/destdir}{$pm_bin_prefix}g' $pm_bin_prefix/lib/perl5/*/*/Config_heavy.pl"`)

     global depsjl = """

        using Pkg: depots1
        ENV["PERL5LIB"]="$perllib"
        ENV["POLYMAKE_USER_DIR"] = abspath(joinpath(depots1(),"polymake_user"))

        """
else
    if pm_config == nothing
        error("Set `POLYMAKE_CONFIG` ENV variable. And rebuild Polymake by calling `import Pkg; Pkg.build(\"Polymake\")`.")
    end
end

pm_include_statements = read(`$perl $pm_config --includes`, String) |> chomp |> split
# Remove the -I prefix of all includes
pm_include_statements = map(i -> i[3:end], pm_include_statements)
push!(pm_include_statements, joinpath(pm_include_statements[1],"..","share","polymake"))
pm_includes = join(pm_include_statements, " ")

pm_cflags = chomp(read(`$perl $pm_config --cflags`, String))
pm_ldflags = chomp(read(`$perl $pm_config --ldflags`, String))
pm_libraries = chomp(read(`$perl $pm_config --libs`, String))
pm_cxx = chomp(read(`$perl $pm_config --cc`, String))

jlcxx_cmake_dir = joinpath(dirname(CxxWrap.jlcxx_path), "cmake", "JlCxx")

julia_exec = joinpath(Sys.BINDIR , "julia")

cd(joinpath(@__DIR__, "src"))

include("parser/type_setup.jl")

run(`cmake -DJulia_EXECUTABLE=$julia_exec -DJlCxx_DIR=$jlcxx_cmake_dir -Dpolymake_includes=$pm_includes -Dpolymake_ldflags=$pm_ldflags -Dpolymake_libs=$pm_libraries -Dpolymake_cflags=$pm_cflags -DCMAKE_CXX_COMPILER=$pm_cxx  -DCMAKE_INSTALL_LIBDIR=lib .`)
run(`make -j$(div(Sys.CPU_THREADS,2))`)

json_script = joinpath(@__DIR__,"rules","funtojson.pl")
json_folder = joinpath(@__DIR__,"parser","json")
mkpath(json_folder)

run(`$perl $polymake --iscript $json_script $json_folder`)

include("parser/parser.jl")

if use_binary
    # Write out a deps.jl file that will contain mappings for our products
    write_deps_file(joinpath(@__DIR__, "deps.jl"), products, verbose=verbose)
end

println("appending to deps.jl file")
f = open(joinpath(dirname(@__FILE__),"deps.jl"), "a")
write(f, depsjl)
close(f)
