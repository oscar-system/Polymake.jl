@testset "perlobj" begin
    input_dict_int = Dict( "POINTS" => [ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ] )
    input_dict_rat = Dict( "POINTS" => Array{Rational{Int64},2}([ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]) )
    input_dict_unbounded = Dict("POINTS" => [1 0 0; 0 1 1])

    @testset "constructors" begin
        @test Polymake.perlobj("polytope::Polytope", input_dict_int ) isa pm_perl_Object
        @test Polymake.perlobj("polytope::Polytope", input_dict_rat ) isa pm_perl_Object
        A = [ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]
        @test Polymake.perlobj("polytope::Polytope", POINTS=A) isa pm_perl_Object
        @test Polymake.perlobj("polytope::Polytope", :POINTS => A) isa pm_perl_Object
        # macro literals
        @test (@pm Polytope.Polytope(POINTS=[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ])) isa pm_perl_Object
        @test (@pm Polytope.Polytope(:POINTS=>[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ])) isa pm_perl_Object
        @test (@pm Polytope.Polytope("POINTS"=>[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ])) isa pm_perl_Object

        # make sure we're escaping where we should
        @test (@pm Polytope.Polytope(input_dict_int)) isa pm_perl_Object
        @test (@pm Polytope.Polytope{Rational}(input_dict_int)) isa pm_perl_Object
        @test (@pm Polytope.Polytope{QuadraticExtension}(input_dict_int)) isa pm_perl_Object

        @test (@pm Polytope.Polytope(input_dict_rat)) isa pm_perl_Object

        @test (@pm Tropical.Polytope{Max}(input_dict_int)) isa pm_perl_Object

        @test (@pm Tropical.Polytope{Max}(input_dict_int)) isa pm_perl_Object
        @test (@pm Tropical.Polytope{Max, Rational}(input_dict_int)) isa pm_perl_Object
        @test (@pm Tropical.Polytope{Max, QuadraticExtension}(input_dict_int)) isa pm_perl_Object

        @test (@pm Tropical.Hypersurface{Min}(
            MONOMIALS=[1 0 0; 0 1 0; 0 0 1],
            COEFFICIENTS=[0, 0, 0])) isa pm_perl_Object
        # note: You need to input COEFFICIENTS as Vector, otherwise it will be converted to pm_Matrix which polymake doesn't like.

        # Make sure that we can also handle different matrix types, e.g. adjoint
        @test (@pm Polytope.Polytope(POINTS=A')) isa pm_perl_Object

        pm1 = pm_Integer(1)
        pm2 = pm_Integer(2)
        @test (@pm Polytope.Polytope(POINTS=[pm1 pm2])) isa pm_perl_Object
        @test (@pm Polytope.Polytope(POINTS=[pm1//pm2 pm2//pm2])) isa pm_perl_Object
        @test (@pm Polytope.Polytope(POINTS=[1//2 1//2])) isa pm_perl_Object

        @test Polytope.cube(3, 1//4, -1//4) isa pm_perl_Object
    end

    @testset "PolymakeException" begin
        test_polytope = @pm Polytope.Polytope(input_dict_int)
        @test !(:STH in Base.propertynames(test_polytope))
        @test_throws PolymakeError test_polytope.STH
    end

    @testset "properties" begin
        test_polytope = @pm Polytope.Polytope(input_dict_int)
        @test test_polytope.F_VECTOR == [ 4, 4 ]
        @test test_polytope.INTERIOR_LATTICE_POINTS ==
            [ 1 1 1 ; 1 1 2 ; 1 2 1 ; 1 2 2 ]

        @test test_polytope.GRAPH isa pm_perl_Object
        test_graph = test_polytope.GRAPH
        @test :ADJACENCY in Base.propertynames(test_graph)
        @test_logs (:warn, "The return value contains pm::graph::Graph<pm::graph::Undirected> which has not been wrapped yet") test_graph.ADJACENCY isa Polymake.pm_perl_PropertyValue

        @test test_polytope.LATTICE_POINTS_GENERATORS isa pm_Array

        test_polytope = @pm Polytope.Polytope(input_dict_unbounded)
        @test test_polytope.FAR_FACE == Set([1])

        c = Polytope.cube(3, 1//4, -1//4)
        @test c.VERTICES[1,2] == -1//4
    end

    @testset "tab-completion" begin
        test_polytope = @pm Polytope.Polytope(input_dict_int)

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
        test_polytope = @pm Polytope.Polytope(input_dict_int)
        mktempdir() do path
            Polymake.save_perl_object(test_polytope,joinpath(path,"test.poly"))
            loaded = Polymake.load_perl_object(joinpath(path,"test.poly"))
            @test loaded isa pm_perl_Object
            @test Base.propertynames(test_polytope) == Base.propertynames(loaded)
        end
    end

    @testset "polymake tutorials" begin
        p = @pm Polytope.Polytope(:POINTS=>Polymake.Polytope.cube(4).VERTICES)
        @test p isa pm_perl_Object

        lp = @pm Polytope.LinearProgram(:LINEAR_OBJECTIVE=>[0,1,1,1,1])
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

        p = @pm Polytope.Polytope(:POINTS=>matrix)

        @test Polytope.dim(p) == 3

        @test p.VERTEX_SIZES == [9, 3, 4, 4, 3, 4, 3, 4, 4, 4]

        s = Set(i for (i, vsize) in enumerate(p.VERTEX_SIZES)
                if vsize == Polytope.dim(p))
        pm_s = pm_Set(i for (i, vsize) in enumerate(p.VERTEX_SIZES)
                if vsize == Polytope.dim(p))

        @test Set([2,5,7]) == s == pm_s

        @test p.VERTICES[collect(pm_s), :] isa pm_Matrix{pm_Rational}
        @test p.VERTICES[collect(pm_s), :] == special_points
    end

    @testset "polymake MILP" begin
        p = @pm Polytope.Polytope( :INEQUALITIES => [1 1 -1; -1 0 1; 7 -1 -1] )
        intvar = Set([0,1,2])
        @test Polymake.convert_to_pm(intvar) isa pm_Set{Int64}

        obj = [0,-1,-1]

        @test (@pm Polytope.MixedIntegerLinearProgram( LINEAR_OBJECTIVE = obj, INTEGER_VARIABLES = intvar)) isa Polymake.pm_perl_Object

        pmintvar = pm_Set(intvar)

        @test (@pm Polytope.MixedIntegerLinearProgram( LINEAR_OBJECTIVE = obj, INTEGER_VARIABLES = pmintvar)) isa Polymake.pm_perl_Object

        p.MILP = @pm Polytope.MixedIntegerLinearProgram( LINEAR_OBJECTIVE = obj, INTEGER_VARIABLES = intvar)

        omp_nthreads = parse(Int, get(ENV, "OMP_NUM_THREADS", "1"))

        if max(omp_nthreads, Threads.nthreads()) == 1
            # segfaults when called from different thread, see
            # https://github.com/oscar-system/Polymake.jl/issues/144
            @test p.MILP.MINIMAL_VALUE == -7
        end
    end
end
