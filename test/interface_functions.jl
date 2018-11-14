@testset "Interface functions" begin
    @test call_func(:pseudopower, pm_Integer(4), 2) == 5
    @test call_func(:cube, 2) isa pm_perl_Object
end
