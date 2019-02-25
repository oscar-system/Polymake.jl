@testset "perlobj" begin
    input_dict_int = Dict( "POINTS" => [ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ] )
    input_dict_rat = Dict( "POINTS" => Array{Rational{Int64},2}([ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]) )
    input_dict_unbounded = Dict("POINTS" => [1 0 0; 0 1 1])

    @testset "constructors" begin
        @test Polymake.perlobj("polytope::Polytope", input_dict_int ) isa pm_perl_Object
        @test Polymake.perlobj("polytope::Polytope", input_dict_rat ) isa pm_perl_Object
        @test Polymake.perlobj("polytope::Polytope",
            POINTS=[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]) isa pm_perl_Object
        @test Polymake.perlobj("polytope::Polytope",
            :POINTS => [ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]) isa pm_perl_Object

        @test (@pm Polytopes.Polytope(input_dict_int)) isa pm_perl_Object
        @test (@pm Polytopes.Polytope{Rational}(input_dict_int)) isa pm_perl_Object
        @test (@pm Polytopes.Polytope{QuadraticExtension}(input_dict_int)) isa pm_perl_Object

        @test (@pm Polytopes.Polytope(input_dict_rat)) isa pm_perl_Object

        @test (@pm Polytopes.Polytope(POINTS=[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ])) isa pm_perl_Object
        @test (@pm Polytopes.Polytope(:POINTS=>[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ])) isa pm_perl_Object
        @test (@pm Polytopes.Polytope("POINTS"=>[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ])) isa pm_perl_Object

        @test (@pm Tropical.Polytope{Max}(input_dict_int)) isa pm_perl_Object

        @test (@pm Tropical.Polytope{Max}(input_dict_int)) isa pm_perl_Object
        @test (@pm Tropical.Polytope{Max, Rational}(input_dict_int)) isa pm_perl_Object
        @test (@pm Tropical.Polytope{Max, QuadraticExtension}(input_dict_int)) isa pm_perl_Object
    end

    @testset "PolymakeException" begin
        test_polytope = @pm Polytopes.Polytope(input_dict_int)
        @test !(:STH in Base.propertynames(test_polytope))
        @test_throws PolymakeError test_polytope.STH
    end

    @testset "properties" begin
        test_polytope = @pm Polytopes.Polytope(input_dict_int)
        @test test_polytope.F_VECTOR == [ 4, 4 ]
        @test test_polytope.INTERIOR_LATTICE_POINTS ==
            [ 1 1 1 ; 1 1 2 ; 1 2 1 ; 1 2 2 ]

        @test test_polytope.GRAPH isa pm_perl_Object
        test_graph = test_polytope.GRAPH
        @test :ADJACENCY in Base.propertynames(test_graph)
        @test_logs (:warn, "The return value contains pm::graph::Graph<pm::graph::Undirected> which has not been wrapped yet") test_graph.ADJACENCY isa Polymake.pm_perl_PropertyValue

        @test test_polytope.LATTICE_POINTS_GENERATORS isa pm_Array

        test_polytope = @pm Polytopes.Polytope(input_dict_unbounded)
        @test test_polytope.FAR_FACE == Set([1])
    end

    @testset "tab-completion" begin
        test_polytope = @pm Polytopes.Polytope(input_dict_int)

        @test Base.propertynames(test_polytope) isa Vector{Symbol}
        names = Base.propertynames(test_polytope)

        @test :VERTICES in names
        @test :FAR_FACE in names
        @test :GRAPH in names
        @test test_polytope.GRAPH isa pm_perl_Object
        @test allunique(Base.propertynames(test_polytope))
        g = test_polytope.GRAPH
        @test Base.propertynames(g) isa Vector{Symbol}
    end

    @testset "save load" begin
        test_polytope = @pm Polytopes.Polytope(input_dict_int)
        mktempdir() do path
            Polymake.save_perl_object(test_polytope,joinpath(path,"test.poly"))
            loaded = Polymake.load_perl_object(joinpath(path,"test.poly"))
            @test loaded isa pm_perl_Object
            @test Base.propertynames(test_polytope) == Base.propertynames(loaded)
        end
    end

    @testset "polymake tutorials" begin
        p = @pm Polytopes.Polytope(:POINTS=>Polymake.Polytopes.cube(4).VERTICES)
        @test p isa pm_perl_Object

        lp = @pm Polytopes.LinearProgram(:LINEAR_OBJECTIVE=>[0,1,1,1,1])
        @test lp isa pm_perl_Object

        @test (p.LP = lp) isa pm_perl_Object
        @test p.LP.MAXIMAL_VALUE == 4

        matrix = Rational{Int64}[
            1//1  0//1  0//1  0//1;
            1//1  1//16 1//4  1//16;
            1//1  3//8  1//4  1//32;
            1//1  1//4  3//8  1//32;
            1//1  1//16 1//16 1//4;
            1//1  1//32 3//8  1//4;
            1//1  1//4  1//16 1//16;
            1//1  1//32 1//4  3//8;
            1//1  3//8  1//32 1//4;
            1//1  1//4  1//32 3//8]

        special_points = pm_Rational[
            1 1//16 1//4 1//16;
            1 1//16 1//16 1//4;
            1 1//4 1//16 1//16]

        p = @pm Polytopes.Polytope(:POINTS=>matrix)

        @test Polymake.Polytopes.DIM(p) == 3

        @test p.VERTEX_SIZES == [9, 3, 4, 4, 3, 4, 3, 4, 4, 4]

        s = Set(i for (i, vsize) in enumerate(p.VERTEX_SIZES)
                if vsize == Polymake.Polytopes.DIM(p))
        pm_s = pm_Set(i for (i, vsize) in enumerate(p.VERTEX_SIZES)
                if vsize == Polymake.Polytopes.DIM(p))

        @test Set([2,5,7]) == s == pm_s

        @test p.VERTICES[collect(pm_s), :] isa Matrix{pm_Rational}
        @test p.VERTICES[collect(pm_s), :] == special_points
    end
end
