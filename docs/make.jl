using Documenter, Polymake

makedocs(sitename = "Polymake.jl - Documentation",
         pages = [
                  "index.md",
                  "getting_started.md",
                  "using_polymake_jl.md",
                  "examples.md",
                  "shell.md",
                 ])

should_push_preview = true
if get(ENV, "GITHUB_ACTOR", "") == "dependabot[bot]"
    # skip preview for dependabot PRs as they fail due to lack of permissions
    should_push_preview = false
end

deploydocs(
    repo = "github.com/oscar-system/Polymake.jl.git",
    push_preview = should_push_preview,
)
