@testset "bigobj" begin
    input_dict_int = Dict( "POINTS" => [ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ] )
    input_dict_rat = Dict( "POINTS" => Base.Array{Base.Rational{Int64},2}([ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]) )
    input_dict_unbounded = Dict("POINTS" => [1 0 0; 0 1 1])

    @testset "constructors" begin
        @test Polymake.bigobj("polytope::Polytope", input_dict_int ) isa BigObject
        @test Polymake.bigobj("polytope::Polytope", input_dict_rat ) isa BigObject
        A = [ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]
        @test Polymake.bigobj("polytope::Polytope", POINTS=A) isa BigObject
        @test Polymake.bigobj("polytope::Polytope", :POINTS => A) isa BigObject
        # macro literals
        @test (@pm polytope.Polytope(POINTS=[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ])) isa BigObject
        @test (@pm polytope.Polytope(:POINTS=>[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ])) isa BigObject
        @test (@pm polytope.Polytope("POINTS"=>[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ])) isa BigObject

        # Make sure that we can also handle different matrix types, e.g. adjoint
        @test (@pm polytope.Polytope(POINTS=A')) isa BigObject

        pm1 = Polymake.Integer(1)
        pm2 = Polymake.Integer(2)
        @test (@pm polytope.Polytope(POINTS=[pm1 pm2])) isa BigObject
        @test (@pm polytope.Polytope(POINTS=[pm1//pm2 pm2//pm2])) isa BigObject
        @test (@pm polytope.Polytope(POINTS=[1//2 1//2])) isa BigObject

        @test polytope.cube(3, 1//4, -1//4) isa BigObject

        function test_pm_macro()
            P = @pm polytope.cube(3)
            Pfl = @pm common.convert_to{Float}(P)
            d = polytope.dim(Pfl)
            return d+1
        end

        @test test_pm_macro() == 4
    end

    @testset "template parameters" begin
        @test (@pm polytope.Polytope(input_dict_int)) isa BigObject
        @test (@pm polytope.Polytope{Rational}(input_dict_int)) isa BigObject
        @test (@pm polytope.Polytope{QuadraticExtension}(input_dict_int)) isa BigObject
        @test (@pm polytope.Polytope{QuadraticExtension{Rational}}(input_dict_int)) isa BigObject

        @test (@pm polytope.Polytope(input_dict_rat)) isa BigObject

        @test (@pm tropical.Polytope{Max}(input_dict_int)) isa BigObject

        @test (@pm tropical.Polytope{Max}(input_dict_int)) isa BigObject
        @test (@pm tropical.Polytope{Max, Rational}(input_dict_int)) isa BigObject
        @test (@pm tropical.Polytope{Max, QuadraticExtension}(input_dict_int)) isa BigObject

        @test (@pm tropical.Hypersurface{Min}(
            MONOMIALS=[1 0 0; 0 1 0; 0 0 1],
            COEFFICIENTS=[0, 0, 0])) isa BigObject
        # note: You need to input COEFFICIENTS as Polymake.Vector, otherwise it will be converted to Polymake.Matrix which polymake doesn't like.

        P = @pm polytope.Polytope{Float}(POINTS=[1 1//2 0; 1 0 1])
        @test P.VERTICES isa Polymake.Matrix{Float64}
        P = @pm polytope.Polytope{Float}(POINTS=[1 0.5 0; 1 0 1])
        @test P.VERTICES isa Polymake.Matrix{Float64}
        P = @pm polytope.Polytope(POINTS=[1 0.5 0; 1 0 1])
        @test P.VERTICES isa Polymake.Matrix{Polymake.Rational}
        P = @pm polytope.Polytope{Rational}(POINTS=[1 0.5 0; 1 0 1])
        @test P.VERTICES isa Polymake.Matrix{Polymake.Rational}
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

        @test test_polytope.GRAPH isa BigObject
        test_graph = test_polytope.GRAPH
        @test :ADJACENCY in Base.propertynames(test_graph)

        @test test_polytope.LATTICE_POINTS_GENERATORS isa Polymake.Array

        test_polytope = @pm polytope.Polytope(input_dict_unbounded)
        @test test_polytope.FAR_FACE == Polymake.Set([1])

        c = polytope.cube(3, 1//4, -1//4)
        @test c.VERTICES[1,2] == -1//4
    end

    @testset "tab-completion" begin
        test_polytope = @pm polytope.Polytope(input_dict_int)

        @test Base.propertynames(test_polytope) isa Base.Vector{Symbol}
        names = Base.propertynames(test_polytope)

        @test :VERTICES in names
        @test :FAR_FACE in names
        @test :GRAPH in names
        @test test_polytope.GRAPH isa BigObject
        @test allunique(Base.propertynames(test_polytope))
        g = test_polytope.GRAPH
        @test Base.propertynames(g) isa Base.Vector{Symbol}
    end

    @testset "save load" begin
        test_polytope = @pm polytope.Polytope(input_dict_int)
        mktempdir() do path
            Polymake.save_bigobject(test_polytope,joinpath(path,"test.poly"))
            loaded = Polymake.load_bigobject(joinpath(path,"test.poly"))
            @test loaded isa BigObject
            @test Base.propertynames(test_polytope) == Base.propertynames(loaded)
        end
    end

    @testset "polymake tutorials" begin
        p = @pm polytope.Polytope(:POINTS=>polytope.cube(4).VERTICES)
        @test p isa BigObject

        lp = @pm polytope.LinearProgram(:LINEAR_OBJECTIVE=>[0,1,1,1,1])
        @test lp isa BigObject

        @test (p.LP = lp) isa BigObject
        @test p.LP.MAXIMAL_VALUE == 4

        matrix = Base.Rational{Int64}[
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

        special_points = Polymake.Rational[
            1 1//16 1//4 1//16;
            1 1//16 1//16 1//4;
            1 1//4 1//16 1//16]

        p = @pm polytope.Polytope(:POINTS=>matrix)

        @test polytope.dim(p) == 3

        @test p.VERTEX_SIZES == [9, 3, 4, 4, 3, 4, 3, 4, 4, 4]

        s = Polymake.Set(i for (i, vsize) in enumerate(p.VERTEX_SIZES)
                if vsize == polytope.dim(p))
        s = Polymake.Set(i for (i, vsize) in enumerate(p.VERTEX_SIZES)
                if vsize == polytope.dim(p))

        @test Polymake.Set([2,5,7]) == s == s

        @test p.VERTICES[collect(s), :] isa Polymake.Matrix{Polymake.Rational}
        @test p.VERTICES[collect(s), :] == special_points
    end

    @testset "polymake MILP" begin
        p = @pm polytope.Polytope( :INEQUALITIES => [1 1 -1; -1 0 1; 7 -1 -1] )
        intvar = Polymake.Set([0,1,2])
        @test Polymake.convert(Polymake.PolymakeType, intvar) isa Polymake.Set{Int64}

        obj = [0,-1,-1]

        @test (@pm polytope.MixedIntegerLinearProgram( LINEAR_OBJECTIVE = obj, INTEGER_VARIABLES = intvar)) isa Polymake.BigObject

        pmintvar = Polymake.Set(intvar)

        @test (@pm polytope.MixedIntegerLinearProgram( LINEAR_OBJECTIVE = obj, INTEGER_VARIABLES = pmintvar)) isa Polymake.BigObject

        p.MILP = @pm polytope.MixedIntegerLinearProgram( LINEAR_OBJECTIVE = obj, INTEGER_VARIABLES = intvar)

        @test p.MILP.MINIMAL_VALUE == -7
    end

    @testset "toplevel visual" begin
        @test visual(polytope.cube(3)) isa Polymake.Visual
    end
end
