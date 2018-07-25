using CxxWrap

jlcxx_cmake_dir = Pkg.dir("CxxWrap", "deps", "usr", "lib", "cmake", "JlCxx")

julia_include = Pkg.dir(JULIA_HOME,"..","include")
julia_lib = Pkg.dir(JULIA_HOME,"..","lib")
julia_exec = JULIA_HOME*"/julia"

cmake_build_path = Pkg.dir("PolymakeWrap","deps","src")

cd(cmake_build_path)

run(`cmake Julia_EXECUTABLE=$julia_exec -DJlCxx_DIR=$jlcxx_cmake_dir -DJuliaIncludeDir=$julia_include -DJULIA_LIB_DIR=$julia_lib -DCMAKE_INSTALL_LIBDIR=lib .`)
run(`make`)
