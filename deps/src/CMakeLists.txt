project(Polymake)

cmake_minimum_required(VERSION 3.01)

find_package(JlCxx REQUIRED)

include_directories(${JlCxx_DIR}/../../../include/)
set(MY_LIST ${polymake_includes})
separate_arguments(MY_LIST)
include_directories(${MY_LIST})

SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -std=c++14 ${polymake_cflags}" )
SET( CMAKE_SHARED_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} ${polymake_ldflags}" )

# avoid gcc 9 internal compiler error,
# see https://gcc.gnu.org/bugzilla/show_bug.cgi?id=90998
if(CMAKE_COMPILER_IS_GNUCC AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 9.0
      AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS 9.3)
   SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -Wno-conversion" )
endif()


file(GLOB polymake_SRC "*.cpp")
add_library(polymake SHARED ${polymake_SRC})
target_link_libraries(polymake JlCxx::cxxwrap_julia "${polymake_libs}")

install(TARGETS
  polymake
ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
