using CxxWrap
import Pkg


# test whether polymake config is available in path
pm_config = nothing
try
    global pm_config = chomp(read(`which polymake-config`, String))
catch
    if haskey(ENV, "POLYMAKE_CONFIG")
        global pm_config = ENV["POLYMAKE_CONFIG"]
    end
end

if pm_config === nothing
    # TODO: Install polymake, for now just throw an error
    error("Set `POLYMAKE_CONFIG` ENV variable. And rebuild PolymakeWrap by calling `import Pkg; Pkg.build(\"PolymakeWrap\")`.")

    # This is the old Julia 0.6 script and doesnt work anymore.
    #
    # build polymake, using Nemo's GMP and MPFR
    # const oldwdir = pwd()
    # const pkgdir = Pkg.dir("PolymakeWrap")
    # const nemodir = Pkg.dir("Nemo")
    #
    # wdir = "$pkgdir/deps"
    # vdir = "$pkgdir/local"
    # nemovdir = "$nemodir/local"
    #
    # LDFLAGS = "-Wl,-rpath,$vdir/lib -Wl,-R$vdir/lib -Wl,-R$nemovdir/lib -Wl,-R\$\$ORIGIN/../share/julia/site/v$(VERSION.major).$(VERSION.minor)/Polymake/local/lib"
    #
    # cd(wdir)
    #
    # const polymake = joinpath(wdir, "polymake")
    #
    # try
    #   run(`git clone https://github.com/polymake/polymake.git`)
    # catch
    #   cd(polymake)
    #   try
    #      run(`git pull --rebase`)
    #   catch
    #   end
    #   cd(wdir)
    # end
    #
    # cd(polymake)
    #
    # withenv("CPP_FLAGS"=>"-I$vdir/include", "LD_LIBRARY_PATH"=>"$vdir/lib:$nemodir/lib") do
    #    run(`$polymake/configure --prefix=$vdir --with-gmp=$nemovdir --with-mpfr=$nemovdir`)
    #    withenv("LDFLAGS"=>LDFLAGS) do
    #       run(`make -j4`)
    #       run(`make install`)
    #    end
    # end
    #
    # ENV["POLYMAKE_CONFIG"] = "$pkgdir/local/bin/polymake-config"
end

pm_include_statements = read(`$pm_config --includes`, String) |> chomp |> split
# Remove the -I prefix of all includes
pm_include_statements = map(i -> i[3:end], pm_include_statements)
push!(pm_include_statements, joinpath(pm_include_statements[1],"..","share","polymake"))
pm_includes = join(pm_include_statements, " ")

pm_cflags = chomp(read(`$pm_config --cflags`, String))
pm_ldflags = chomp(read(`$pm_config --ldflags`, String))
pm_libraries = chomp(read(`$pm_config --libs`, String))

jlcxx_cmake_dir = joinpath(dirname(pathof(CxxWrap)), "..",  "deps", "usr", "lib", "cmake", "JlCxx")

julia_include = joinpath(Sys.BINDIR, "..", "include")
julia_lib = joinpath(Sys.BINDIR, "..", "lib")
julia_exec = joinpath(Sys.BINDIR , "julia")

cd("src")

run(`cmake -DJulia_EXECUTABLE=$julia_exec -DJlCxx_DIR=$jlcxx_cmake_dir -DJuliaIncludeDir=$julia_include -DJULIA_LIB_DIR=$julia_lib -Dpolymake_includes=$pm_includes -Dpolymake_ldflags=$pm_ldflags -Dpolymake_libs=$pm_libraries -Dpolymake_cflags=$pm_cflags -DCMAKE_INSTALL_LIBDIR=lib .`)
run(`make`)
