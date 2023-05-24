using Aqua

@testset "Aqua.jl" begin
   Aqua.test_all(
      Polymake;
      # this check is disabled as it returns thousands of ambiguities from
      # libcxxwrap defined interfaces where we can't really do anything about
      # (at least until someone has time to work on CxxWrap for this)
      ambiguities=false,
      unbound_args=true,
      undefined_exports=true,
      project_extras=true,
      stale_deps=true,
      deps_compat=true,
      project_toml_formatting=true,
      # this is also disabled to to the way libcxxwrap defines c++ function mappings
      piracy=false,
   )
end
