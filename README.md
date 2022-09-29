# Oscar number types

To experiment with Oscar number types. The typename will probably be changed soon.

### Initial setup:

```julia
using Pkg;
Pkg.activate("fieldelemproject")

Pkg.develop([PackageSpec(url="https://github.com/benlorenz/polymake_jll.jl"),PackageSpec(url="https://github.com/benlorenz/libpolymake_julia_jll.jl")]);

Pkg.add(PackageSpec(name="Polymake",rev="bl/juliafieldelem"))

Pkg.add("Oscar");
```

### Computations with polytopes:

Starting julia with `julia --project=fieldelemproject`:
```julia
using Oscar;

Qx, x = QQ["x"];

K, (a1, a2) = embedded_number_field([x^2 - 2, x^3 - 5], [(0, 2), (0, 2)]);

enf = Polymake.JuliaFieldElement(a1+2)

enf2 = Polymake.JuliaFieldElement(a2+1);

c = Polymake.polytope.cube(3,enf,-enf2);

p = Polymake.polytope.Polytope{Polymake.JuliaFieldElement}(POINTS=c.VERTICES);

p.FACETS
p.VERTICES

pd = Polymake.polytope.polarize(p);

ps = Polymake.polytope.scale(pd,enf);

ps.FACETS

ps.VERTICES

```

# Polymake.jl


| **Stable version**    | **Documentation**   | **Build Status**    |
|:--------------:|:-------------------:|:-------------------:|
| [![version][ver-img]][ver-url] | [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![Build Status][ga-img]][ga-url] [![PkgEval][pkgeval-img]][pkgeval-url]  |

`Polymake.jl` is a Julia package for using [`polymake`](https://polymake.org/doku.php), a software for research in polyhedral geometry from Julia.
This package is developed as part of the [OSCAR](https://www.oscar-system.org) project.

The current version of `Polymake.jl` relies on `polymake` version `4.0` or later.

## Supported Platforms

While this package does support most julia platforms apart from Windows, everything except `x86_64-linux-gnu` and `x86_64-apple-darwin` is considered experimental.

## Documentation
The documentation can be found at [juliahub](https://juliahub.com/docs/Polymake/).

## How to cite
If you use `Polymake.jl` in your research, please cite our [ICMS article](https://link.springer.com/chapter/10.1007/978-3-030-52200-1_37) and the [original polymake article](https://link.springer.com/chapter/10.1007/978-3-0348-8438-9_2).


[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://oscar-system.github.io/Polymake.jl/dev/

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://oscar-system.github.io/Polymake.jl/stable/

[ga-img]: https://github.com/oscar-system/Polymake.jl/workflows/Run%20tests/badge.svg
[ga-url]: https://github.com/oscar-system/Polymake.jl/actions?query=workflow%3A%22Run+tests%22+branch%3Amaster

[pkgeval-img]: https://juliaci.github.io/NanosoldierReports/pkgeval_badges/P/Polymake.svg
[pkgeval-url]: https://juliaci.github.io/NanosoldierReports/pkgeval_badges/P/Polymake.html

[ver-img]: https://img.shields.io/github/v/release/oscar-system/Polymake.jl
[ver-url]: https://github.com/oscar-system/Polymake.jl/releases/latest
