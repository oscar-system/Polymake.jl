@testset "perlobj" begin
    input_dict_int = Dict( "POINTS" => [ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ] )
    input_dict_rat = Dict( "POINTS" => Array{Rational{Int64},2}([ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]) )
    input_dict_unbounded = Dict("POINTS" => [1 0 0; 0 1 1])

    @testset "constructors" begin
        @test perlobj("Polytope", input_dict_int ) isa pm_perl_Object
        @test perlobj("Polytope", input_dict_rat ) isa pm_perl_Object
        @test perlobj("Polytope",
            POINTS=[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]) isa pm_perl_Object
        @test perlobj("Polytope",
            :POINTS => [ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]) isa pm_perl_Object
    end

    @testset "output" begin
        test_polytope = perlobj("Polytope", input_dict_int )
        @test test_polytope.F_VECTOR == [ 4, 4 ]
        @test test_polytope.INTERIOR_LATTICE_POINTS ==
            [ 1 1 1 ; 1 1 2 ; 1 2 1 ; 1 2 2 ]
    end
    
    @testset "lattice points" begin
        test_polytope = perlobj("Polytope", input_dict_unbounded )
        @test test_polytope.LATTICE_POINTS_GENERATORS ==
            [[ 1 0 0;], [ 0 1 1;], Matrix{Int}(undef, 0,3)]
        @test test_polytope.FAR_FACE == Set([1])
    end
end
