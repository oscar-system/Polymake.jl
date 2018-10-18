@testset "perlobj" begin
    input_dict_int = Dict( "POINTS" => [ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ] )
    input_dict_rat = Dict( "POINTS" => Array{Rational{Int64},2}([ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]) )
    pm_perl_Object = PolymakeWrap.pm_perl_Object

    @testset "constructors" begin
        @test PolymakeWrap.perlobj("Polytope", input_dict_int ) isa pm_perl_Object
        @test PolymakeWrap.perlobj("Polytope", input_dict_rat ) isa pm_perl_Object
        @test PolymakeWrap.perlobj("Polytope",
            POINTS=[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]) isa pm_perl_Object
        @test PolymakeWrap.perlobj("Polytope",
            :POINTS => [ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]) isa pm_perl_Object
    end

    @testset "output" begin
        test_polytope = PolymakeWrap.perlobj("Polytope", input_dict_int )
        @test test_polytope.F_VECTOR == [ 4, 4 ]
        @test test_polytope.INTERIOR_LATTICE_POINTS ==
            [ 1 1 1 ; 1 1 2 ; 1 2 1 ; 1 2 2 ]
    end
end
