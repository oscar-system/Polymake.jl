using Base.Docs
using Markdown
include("meta.jl")

using Polymake.Meta

jsondir = libpolymake_julia_jll.appsjson

for (app, mod) in appname_module_dict
    json_file = joinpath(jsondir, "$app.json")
    @assert isfile(json_file)
    @info "Generating module $mod"
    @eval $(Polymake.Meta.jl_code(Polymake.Meta.PolymakeApp(mod, json_file)))
    @eval export $mod
end
