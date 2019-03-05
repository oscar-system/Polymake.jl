using Polymake.Meta

json_dir = joinpath(@__DIR__, "..", "deps", "parser", "json")
generated_dir = joinpath(@__DIR__, "generated")
isdir(generated_dir) || mkpath(generated_dir)

for (app, mod) in appname_module_dict
    json_file = joinpath(json_dir, "$app.json")
    @assert isfile(json_file)
    module_file = joinpath(generated_dir, "$app.jl")

    if !isfile(module_file)
        @info "Generating module $mod"
        pa = Polymake.Meta.PolymakeApp(mod, json_file)
        open(module_file, "w") do file
            println(file, Polymake.Meta.jl_code(pa))
        end
    end
    include(module_file)
    @eval Polymake export $mod
end

@eval module Compat
    $([Polymake.Meta.compat_statement(app, mod) for (app, mod) in appname_module_dict]...)
    end
@eval Polymake export Compat

Polymake.@register Polytopes.pseudopower
