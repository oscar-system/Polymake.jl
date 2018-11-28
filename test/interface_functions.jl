@testset "Interface functions" begin
    @test call_function(:pseudopower, pm_Integer(4), 2) == 5
    @test polytope.pseudopower( pm_Integer(4), 2) == 5
    @test polytope.pseudopower( 4, 2) == 5
    @test call_function(:cube, 2) isa pm_perl_Object
    @test polytope.cube( 2 ) isa pm_perl_Object
end
