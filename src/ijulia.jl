import JSON

const _jupyter_resources = joinpath(polymake_jll.artifact_dir, "share",
                                 "polymake", "resources", "jupyter-polymake",
                                 "jupyter_kernel_polymake", "resources")

function check_or_install_js(source, target_dir)
   target_path = joinpath(target_dir, basename(source))
   if !isfile(target_path) || filesize(source) != filesize(target_path)
      cp(source, target_path; force=true)
   end
end

function check_jupyter_resources(target_dir)
   mkpath(target_dir)
   for file in readdir(_jupyter_resources, join=true)
      if endswith(file,".svg") || endswith(file,".js") && !endswith(file, "kernel.js")
         check_or_install_js(file, target_dir)
      end
   end
end

"""
    prepare_jupyter_kernel_for_visualization()

Polymake needs certain javascript files in order to visualize things.
Jupyter is very particular from where it wants to load these.
So we just copy into the Julia kernel directory...
"""
function prepare_jupyter_kernel_for_visualization()

   warning="Could not install threejs files for jupyter, in-notebook visualization might not work:"
   kerneldirs = String[]
   success = false

   # first try with kernelspec command
   kernelspecs = try
      c = ignorestatus(`$(Main.IJulia.find_jupyter_subcommand("kernelspec")) list --json`)
      err = Pipe()
      # If there is no kernelspec command, this will return an empty string (but
      # not throw an error because of ignorestatus)
      json = read(pipeline(c, stderr = err), String)
      close(err.in)
      # If isempty(json), then JSON.parse will throw an error
      JSON.parse(json)["kernelspecs"]
   catch e
      Dict{String, Any}()
   end
   for (kernel, spec) in kernelspecs
      if occursin("julia", kernel)
         push!(kerneldirs, spec["resource_dir"])
      end
   end
   # if kernelspec failed or nothing was found
   # we go through the directories in the IJulia kerneldir
   if isempty(kerneldirs)
      kerneldir = Main.IJulia.kerneldir()
      for dir in readdir(kerneldir)
         if isdir(joinpath(kerneldir, dir)) && startswith(dir, "julia")
            push!(kerneldirs, joinpath(kerneldir, dir))
         end
      end
   end
   for dir in kerneldirs
      try
         check_jupyter_resources(joinpath(dir, "polymake"))
         success = true
      catch e
         warning *= "\n  failed to check or install threejs resources in $dir: \n  $e"
      end
   end
   if !success
      # at least one kernel directory should have the correct files,
      # otherwise print a warning
      @warn warning
   end
   nothing
end
