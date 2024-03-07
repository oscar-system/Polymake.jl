# Getting Started
This page covers the installation of `Polymake.jl` and where to find help.

## Installation

The installation can be done in the Julia's REPL by executing
```julia
julia> using Pkg; Pkg.add("Polymake")
```
This will fetch a pre-built binary of `polymake`. You are ready to start `using Polymake`.

Note: Pre-built binaries are available for the `Linux` and `macOS` platform, but the `macOS` binaries are considered experimental. Windows users are encouraged to try running Julia inside Window Subsystem for Linux and reporting back ;)

Note: Pre-built polymake will use a separate `.polymake` config directory (usually `joinpath(homedir(), ".julia", "polymake_user")`).


## Getting Help

For basic information on the usage of `Polymake.jl` we refer to the other sections of this documentation.

For further details on `polymake` and its abilities see the [Polymake User Guide](https://polymake.org/doku.php/user_guide/start).
