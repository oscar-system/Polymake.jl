@testset "Interface functions" begin
    for (args, val) in [((4,2), 5), ((pm_Integer(4), 2), 5)]
        @test call_function(:polytope, :pseudopower, args...) == val
        @test (@pm Polytope.pseudopower(args...)) == val
        @test Polytope.pseudopower(args...) == val
    end

    @test call_function(:polytope, :cube, 2) isa pm_perl_Object
    @test Polytope.cube( 2 ) isa pm_perl_Object
    @test (@pm Polytope.cube{Rational}( 3 )) isa pm_perl_Object
    c = @pm Polytope.cube{Rational}( 3 )
    cc = Polytope.cube( 3 )
    @test call_function(:polytope, :equal_polyhedra,c,cc)
    @test @pm Polytope.equal_polyhedra(c, cc)
    @test Polytope.equal_polyhedra(c, cc)

    @test Tropical.cyclic(3,5,template_parameters=["Max"]) isa pm_perl_Object

    @test (@pm Tropical.cyclic{Max}(3,5)) isa pm_perl_Object

end
