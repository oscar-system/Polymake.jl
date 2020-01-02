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
        @test (@pm polytope.Polytope(POINTS=[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ])) isa pm_perl_Object
        @test (@pm polytope.Polytope(:POINTS=>[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ])) isa pm_perl_Object
        @test (@pm polytope.Polytope("POINTS"=>[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ])) isa pm_perl_Object

        # Make sure that we can also handle different matrix types, e.g. adjoint
        @test (@pm polytope.Polytope(POINTS=A')) isa pm_perl_Object

        pm1 = pm_Integer(1)
        pm2 = pm_Integer(2)
        @test (@pm polytope.Polytope(POINTS=[pm1 pm2])) isa pm_perl_Object
        @test (@pm polytope.Polytope(POINTS=[pm1//pm2 pm2//pm2])) isa pm_perl_Object
        @test (@pm polytope.Polytope(POINTS=[1//2 1//2])) isa pm_perl_Object

        @test polytope.cube(3, 1//4, -1//4) isa pm_perl_Object

        function test_pm_macro()
            P = @pm polytope.cube(3)
            Pfl = @pm common.convert_to{Float}(P)
            d = polytope.dim(Pfl)
            return d+1
        end

        @test test_pm_macro() == 4
    end

    @testset "template parameters" begin
        @test (@pm polytope.Polytope(input_dict_int)) isa pm_perl_Object
        @test (@pm polytope.Polytope{Rational}(input_dict_int)) isa pm_perl_Object
        @test (@pm polytope.Polytope{QuadraticExtension}(input_dict_int)) isa pm_perl_Object
        @test (@pm polytope.Polytope{QuadraticExtension{Rational}}(input_dict_int)) isa pm_perl_Object

        @test (@pm polytope.Polytope(input_dict_rat)) isa pm_perl_Object

        @test (@pm tropical.Polytope{Max}(input_dict_int)) isa pm_perl_Object

        @test (@pm tropical.Polytope{Max}(input_dict_int)) isa pm_perl_Object
        @test (@pm tropical.Polytope{Max, Rational}(input_dict_int)) isa pm_perl_Object
        @test (@pm tropical.Polytope{Max, QuadraticExtension}(input_dict_int)) isa pm_perl_Object

        @test (@pm tropical.Hypersurface{Min}(
            MONOMIALS=[1 0 0; 0 1 0; 0 0 1],
            COEFFICIENTS=[0, 0, 0])) isa pm_perl_Object
        # note: You need to input COEFFICIENTS as Vector, otherwise it will be converted to pm_Matrix which polymake doesn't like.

        P = @pm polytope.Polytope{Float}(POINTS=[1 1//2 0; 1 0 1])
        @test P.VERTICES isa pm_Matrix{Float64}
        P = @pm polytope.Polytope{Float}(POINTS=[1 0.5 0; 1 0 1])
        @test P.VERTICES isa pm_Matrix{Float64}
        P = @pm polytope.Polytope(POINTS=[1 0.5 0; 1 0 1])
        @test P.VERTICES isa pm_Matrix{pm_Rational}
        P = @pm polytope.Polytope{Rational}(POINTS=[1 0.5 0; 1 0 1])
        @test P.VERTICES isa pm_Matrix{pm_Rational}
    end

    @testset "PolymakeException" begin
        test_polytope = @pm polytope.Polytope(input_dict_int)
        @test !(:STH in Base.propertynames(test_polytope))
        @test_throws PolymakeError test_polytope.STH
    end

    @testset "properties" begin
        test_polytope = @pm polytope.Polytope(input_dict_int)
        @test test_polytope.F_VECTOR == [ 4, 4 ]
        @test test_polytope.INTERIOR_LATTICE_POINTS ==
            [ 1 1 1 ; 1 1 2 ; 1 2 1 ; 1 2 2 ]

        @test test_polytope.GRAPH isa pm_perl_Object
        test_graph = test_polytope.GRAPH
        @test :ADJACENCY in Base.propertynames(test_graph)

        @test test_polytope.LATTICE_POINTS_GENERATORS isa pm_Array

        test_polytope = @pm polytope.Polytope(input_dict_unbounded)
        @test test_polytope.FAR_FACE == Set([1])

        c = polytope.cube(3, 1//4, -1//4)
        @test c.VERTICES[1,2] == -1//4
    end

    @testset "tab-completion" begin
        test_polytope = @pm polytope.Polytope(input_dict_int)

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
        test_polytope = @pm polytope.Polytope(input_dict_int)
        mktempdir() do path
            Polymake.save_perl_object(test_polytope,joinpath(path,"test.poly"))
            loaded = Polymake.load_perl_object(joinpath(path,"test.poly"))
            @test loaded isa pm_perl_Object
            @test Base.propertynames(test_polytope) == Base.propertynames(loaded)
        end
    end

    @testset "polymake tutorials" begin
        p = @pm polytope.Polytope(:POINTS=>polytope.cube(4).VERTICES)
        @test p isa pm_perl_Object

        lp = @pm polytope.LinearProgram(:LINEAR_OBJECTIVE=>[0,1,1,1,1])
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

        p = @pm polytope.Polytope(:POINTS=>matrix)

        @test polytope.dim(p) == 3

        @test p.VERTEX_SIZES == [9, 3, 4, 4, 3, 4, 3, 4, 4, 4]

        s = Set(i for (i, vsize) in enumerate(p.VERTEX_SIZES)
                if vsize == polytope.dim(p))
        pm_s = pm_Set(i for (i, vsize) in enumerate(p.VERTEX_SIZES)
                if vsize == polytope.dim(p))

        @test Set([2,5,7]) == s == pm_s

        @test p.VERTICES[collect(pm_s), :] isa pm_Matrix{pm_Rational}
        @test p.VERTICES[collect(pm_s), :] == special_points
    end

    @testset "polymake MILP" begin
        p = @pm polytope.Polytope( :INEQUALITIES => [1 1 -1; -1 0 1; 7 -1 -1] )
        intvar = Set([0,1,2])
        @test Polymake.convert(Polymake.PolymakeType, intvar) isa pm_Set{Int32}

        obj = [0,-1,-1]

        @test (@pm polytope.MixedIntegerLinearProgram( LINEAR_OBJECTIVE = obj, INTEGER_VARIABLES = intvar)) isa Polymake.pm_perl_Object

        pmintvar = pm_Set(intvar)

        @test (@pm polytope.MixedIntegerLinearProgram( LINEAR_OBJECTIVE = obj, INTEGER_VARIABLES = pmintvar)) isa Polymake.pm_perl_Object

        p.MILP = @pm polytope.MixedIntegerLinearProgram( LINEAR_OBJECTIVE = obj, INTEGER_VARIABLES = intvar)

        @test p.MILP.MINIMAL_VALUE == -7
    end
end
