const appname_module_dict = Dict(
  :common     => :common,
  :fan        => :fan,
  :fulton     => :fulton,
  :graph      => :graph,
  :group      => :group,
  :ideal      => :ideal,
  :matroid    => :matroid,
  :polytope   => :polytope,
  :topaz      => :topaz,
  :tropical   => :tropical
)

const module_appname_dict = Dict( (j,i) for (i,j) in appname_module_dict )

list_applications() = call_function(:common, :list_applications)

list_big_objects(app::Symbol) = call_function(:common, :list_big_objects, string(app))


list_labels(app::Symbol) = call_function(:common, :list_labels, string(app))
