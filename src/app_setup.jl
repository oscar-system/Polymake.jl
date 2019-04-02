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
