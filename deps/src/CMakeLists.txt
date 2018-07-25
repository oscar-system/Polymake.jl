project(PolymakeWrap)

find_package(JlCxx REQUIRED)

include_directories(${JlCxx_DIR}/../../../include/)
include_directories(${JuliaIncludeDir})

SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -std=c++14" )
SET( CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -L${JULIA_LIB_DIR} -Wl,-rpath,${JULIA_LIB_DIR}" )

add_library(polymake SHARED polymake.cpp)
target_link_libraries(polymake JlCxx::cxxwrap_julia  -ljulia "-lpolymake -lpolymake-apps -lmpfr -lgmp -lpthread -lxml2 -lz -llzma -licui18n -licuuc -licudata -lm -ldl")

install(TARGETS
  polymake
ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})