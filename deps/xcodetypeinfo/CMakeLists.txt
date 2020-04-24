project(xcodetypeinfo)

cmake_minimum_required(VERSION 3.01)

find_package(JlCxx REQUIRED)

include_directories(${JlCxx_DIR}/../../../include/)

add_library(hello SHARED hello.cpp)
target_link_libraries(hello JlCxx::cxxwrap_julia)
