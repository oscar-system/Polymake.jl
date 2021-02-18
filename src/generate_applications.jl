using Base.Docs
using Markdown
include("meta.jl")

using Polymake.Meta

for app in ordered_pm_apps
    json_file = joinpath(json_folder, "$app.json")
    @assert isfile(json_file)
    @info "Generating module $app"
    @eval $(Polymake.Meta.jl_code(Polymake.Meta.PolymakeApp(app, json_file)))
    @eval export $app
end
