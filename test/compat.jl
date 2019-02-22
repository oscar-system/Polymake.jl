@testset "Polymake compat" begin
    using Polymake.PolymakeCompat
    @test polytope.cube( 2 ) isa pm_perl_Object
    @test polytope.pseudopower(2,2) == 2
    @test tropical.cyclic(3,5,template_parameters=["Max"]) isa pm_perl_Object
end
