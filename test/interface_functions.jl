@testset "Interface functions" begin
    @test call_function(:pseudopower, pm_Integer(4), 2) == 5
    @test Polytopes.pseudopower( pm_Integer(4), 2) == 5
    @test Polytopes.pseudopower( 4, 2) == 5
    @test call_function(:cube, 2) isa pm_perl_Object
    @test Polytopes.cube( 2 ) isa pm_perl_Object
    cc = Polytopes.cube( 3 )
    @test call_function(:equal_polyhedra,cc,cc)
    @test Polytopes.pseudopower(2,2) == 2
    @test Tropical.cyclic(3,5,template_parameters=["Max"]) isa pm_perl_Object
end
