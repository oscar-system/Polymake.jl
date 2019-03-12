@testset "Interface functions" begin
    for (args, val) in [((4,2), 5), ((pm_Integer(4), 2), 5)]
        @test call_function(:polytope, :pseudopower, args...) == val
        @test (@pm Polytopes.pseudopower(args...)) == val
        @test Polytopes.pseudopower(args...) == val
    end
    
    @test call_function(:polytope, :cube, 2) isa pm_perl_Object
    @test Polytopes.cube( 2 ) isa pm_perl_Object
    @test (@pm Polytopes.cube{Rational}( 3 )) isa pm_perl_Object
    c = @pm Polytopes.cube{Rational}( 3 )
    cc = Polytopes.cube( 3 )
    @test call_function(:polytope, :equal_polyhedra,c,cc)
    @test @pm Polytopes.equal_polyhedra(c, cc)
    @test Polytopes.equal_polyhedra(c, cc)
    
    @test Tropical.cyclic(3,5,template_parameters=["Max"]) isa pm_perl_Object
    
    @test (@pm Tropical.cyclic{Max}(3,5)) isa pm_perl_Object
    
end
