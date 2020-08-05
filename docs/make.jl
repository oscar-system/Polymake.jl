using Documenter, Polymake

makedocs(sitename = "Polymake.jl - Documentation", pages = ["index.md", "getting_started.md", "using_polymake_jl.md", "examples.md"])

deploydocs(
    repo = "github.com/oscar-system/Polymake.jl.git",
    push_preview    = true,
)
