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

### Your own installation of `polymake`

If you already have a recent enough version of `polymake` (i.e. `>=4.0`) on your system and you want to use this version of `polymake`, you either need to
 * set the environment variable `POLYMAKE_CONFIG=yes` and make `polymake-config` available in your `PATH` or
 * set the environment variable `POLYMAKE_CONFIG` to the full path of the `polymake-config` executable.

After this just `add` the package as above (or `build` if the package has been already added), the build script will use your `polymake` installation.

### `polymake` from source

A compatible version is available at [polymake/polymake](https://github.com/polymake/polymake).
It can be compiled as follows where `GIT_FOLDER` and `INSTALL_FOLDER` have to be substituted with your favorite folders. Please note that these need to be absolute paths.
Also make sure to check [the necessary dependencies](https://polymake.org/doku.php/howto/install) as well as the [additional instructions for Macs](https://polymake.org/doku.php/howto/mac).

```sh
export POLYMAKE_GIT=GIT_FOLDER
export POLYMAKE_INSTALL=INSTALL_FOLDER
git clone git@github.com:polymake/polymake $POLYMAKE_GIT
cd $POLYMAKE_GIT
./configure --prefix=$POLYMAKE_INSTALL
ninja -C build/Opt
ninja -C build/Opt install
export POLYMAKE_CONFIG=$POLYMAKE_INSTALL/bin/polymake-config
```
Note that `polymake` might take some time to compile.

After this start Julia and follow the instructions above.

Note: Self-built polymake will use the standard `.polymake` config directory (usually `$HOME/.polymake`).

### `Polymake.jl` in a separate environment:
```
mkdir my_new_env
cd my_new_env
```
Then start Julia in the directory and press `]` for `pkg` mode.
```julia
(v1.3) pkg> activate .
(Polymake) pkg> dev --local Polymake
(Polymake) pkg> build Polymake # fetches the prebuild polymake binaries
(Polymake) pkg> test Polymake # and You are good to go!
```
If `polymake-config` is in your `PATH`, or `POLYMAKE_CONFIG` environment variable is set the `build` phase will try to use it.

Just remember that You need to `activate Polymake.jl` to use `Polymake`.

## Getting Help

For basic information on the usage of `Polymake.jl` we refer to the other sections of this documentation.

For further details on `polymake` and its abilities see the [Polymake User Guide](https://polymake.org/doku.php/user_guide/start).
