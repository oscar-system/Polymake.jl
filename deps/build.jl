using CxxWrap

## build polymake, using Nemo's GMP and MPFR

if ! haskey(ENV, "POLYMAKE_CONFIG")
    const oldwdir = pwd()
    const pkgdir = Pkg.dir("PolymakeWrap")
    const nemodir = Pkg.dir("Nemo")

    wdir = "$pkgdir/deps"
    vdir = "$pkgdir/local"
    nemovdir = "$nemodir/local"

    LDFLAGS = "-Wl,-rpath,$vdir/lib -Wl,-R$vdir/lib -Wl,-R$nemovdir/lib -Wl,-R\$\$ORIGIN/../share/julia/site/v$(VERSION.major).$(VERSION.minor)/Polymake/local/lib"

    cd(wdir)

    const polymake = joinpath(wdir, "polymake")

    try
      run(`git clone https://github.com/polymake/polymake.git`)
    catch
      cd(polymake)
      try
         run(`git pull --rebase`)
      catch
      end
      cd(wdir)
    end

    cd(polymake)

    withenv("CPP_FLAGS"=>"-I$vdir/include", "LD_LIBRARY_PATH"=>"$vdir/lib:$nemodir/lib") do
       run(`$polymake/configure --prefix=$vdir --with-gmp=$nemovdir --with-mpfr=$nemovdir`)
       withenv("LDFLAGS"=>LDFLAGS) do
          run(`make -j4`)
          run(`make install`)
       end
    end

    ENV["POLYMAKE_CONFIG"] = "$pkgdir/local/bin/polymake-config"
end

pm_includes = chomp(readstring(`$(ENV["POLYMAKE_CONFIG"]) --includes`))
pm_includes = map(i->i[3:end], map(String,split(pm_includes)))
push!(pm_includes,Pkg.dir(pm_includes[1],"..","share","polymake"))
pm_includes=join(pm_includes," ")

pm_cflags = chomp(readstring(`$(ENV["POLYMAKE_CONFIG"]) --cflags`))
pm_ldflags = chomp(readstring(`$(ENV["POLYMAKE_CONFIG"]) --ldflags`))
pm_libraries = chomp(readstring(`$(ENV["POLYMAKE_CONFIG"]) --libs`))


jlcxx_cmake_dir = Pkg.dir("CxxWrap", "deps", "usr", "lib", "cmake", "JlCxx")

julia_include = Pkg.dir(JULIA_HOME,"..","include")
julia_lib = Pkg.dir(JULIA_HOME,"..","lib")
julia_exec = JULIA_HOME*"/julia"

cmake_build_path = Pkg.dir("PolymakeWrap","deps","src")

cd(cmake_build_path)

run(`cmake Julia_EXECUTABLE=$julia_exec -DJlCxx_DIR=$jlcxx_cmake_dir -DJuliaIncludeDir=$julia_include -DJULIA_LIB_DIR=$julia_lib -Dpolymake_includes=$pm_includes -Dpolymake_ldflags=$pm_ldflags -Dpolymake_libs=$pm_libraries -Dpolymake_cflags=$pm_cflags -DCMAKE_INSTALL_LIBDIR=lib .`)
run(`make`)
