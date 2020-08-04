using Base.Docs
using Markdown
include("meta.jl")

using Polymake.Meta

generated_dir = joinpath(@__DIR__, "generated")
json_dir = joinpath(generated_dir, "json")
isdir(generated_dir) || mkpath(generated_dir)

for (app, mod) in appname_module_dict
    json_file = joinpath(json_dir, "$app.json")
    @assert isfile(json_file)
    @info "Generating module $mod"
    @eval $(Polymake.Meta.jl_code(Polymake.Meta.PolymakeApp(mod, json_file)))
    @eval export $mod
end
