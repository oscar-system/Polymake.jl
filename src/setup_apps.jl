# these must be sorted by dependency order !
const ordered_pm_apps = Symbol[
  :common
  :graph
  :group
  :ideal
  :topaz
  :polytope
  :fan
  :matroid
  :fulton
  :tropical
]

list_applications() = call_function(:common, :list_applications)

list_big_objects(app::Symbol) = call_function(:common, :list_big_objects, string(app))
