using Base.Docs
using Markdown
include("meta.jl")

using Polymake.Meta

for (app, mod) in appname_module_dict
    json_file = joinpath(libpolymake_julia_jll.appsjson, "$app.json")
    @assert isfile(json_file)
    @info "Generating module $mod"
    @eval $(Polymake.Meta.jl_code(Polymake.Meta.PolymakeApp(mod, json_file)))
    @eval export $mod
end
