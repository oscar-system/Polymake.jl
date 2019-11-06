const appname_module_dict = Dict(
  :common  => :Common,
  :fan  => :Fan,
  :fulton  => :Fulton,
  :graph  => :Graph,
  :group  => :Group,
  :ideal  => :Ideal,
  :matroid  => :Matroid,
  :polytope  => :Polytope,
  :topaz  => :Topaz,
  :tropical  => :Tropical
)

const module_appname_dict = Dict( (j,i) for (i,j) in appname_module_dict )

list_applications() = call_function(:common, :list_applications)

list_big_objects(app::Symbol) = call_function(:common, :list_big_objects, string(app))
