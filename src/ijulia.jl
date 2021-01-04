import JSON

function copy_javascript_files(target_dir)
    jupyter_resources = joinpath(polymake_jll.artifact_dir, "share",
                                 "polymake", "resources", "jupyter-polymake",
                                 "jupyter_kernel_polymake", "resources")
    mkpath(target_dir)
    for file in readdir(jupyter_resources)
        if endswith(file,".svg") || endswith(file,".js") && file != "kernel.js"
            cp(joinpath(jupyter_resources, file),
               joinpath(target_dir, file); force=true)
        end
    end
    nothing
end

"""
    prepare_jupyter_kernel_for_visualization()

Polymake needs certain javascript files in order to visualize things.
Jupyter is very particular from where it wants to load these.
So we just copy into the Julia kernel directory...
"""
function prepare_jupyter_kernel_for_visualization()

    json = read(`$(Main.IJulia.JUPYTER) kernelspec list --json`, String)
    kernelspecs = JSON.parse(json)["kernelspecs"]

    for (kernel, spec) in kernelspecs
        if occursin("julia", kernel)
            copy_javascript_files(joinpath(spec["resource_dir"],"polymake"))
        end
    end
    nothing
end
