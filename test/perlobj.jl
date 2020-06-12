@testset "bigobject" begin
    points_int = [ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]
    points_rat = Rational{Int}[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]
    points_unbounded = [1 0 0; 0 1 1]

    @testset "constructors" begin
        @test Polymake.bigobject("polytope::Polytope", POINTS=points_int ) isa Polymake.BigObject
        @test Polymake.bigobject("polytope::Polytope", POINTS=points_rat ) isa Polymake.BigObject
        # macro literals
        @test (@pm polytope.Polytope(POINTS=[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ])) isa Polymake.BigObject
        # Make sure that we can also handle different matrix types, e.g. adjoint
        @test (@pm polytope.Polytope(POINTS=points_int')) isa Polymake.BigObject

        pm1 = Polymake.Integer(1)
        pm2 = Polymake.Integer(2)
        @test (@pm polytope.Polytope(POINTS=[pm1 pm2])) isa Polymake.BigObject
        @test (@pm polytope.Polytope(POINTS=[pm1//pm2 pm2//pm2])) isa Polymake.BigObject
        @test (@pm polytope.Polytope(POINTS=[1//2 1//2])) isa Polymake.BigObject

        @test polytope.cube(3, 1//4, -1//4) isa Polymake.BigObject

        function test_pm_macro()
            P = @pm polytope.cube(3)
            Pfl = @pm common.convert_to{Float}(P)
            d = polytope.dim(Pfl)::Int
            return d+1
        end

        @test test_pm_macro() == 4

        @test polytope.cube(Polymake.PropertyValue, 3) isa Polymake.PropertyValue
        c = polytope.cube(Polymake.PropertyValue, 3);
        @test polytope.spherize(c) isa Polymake.BigObject

        @testset "giving polytope a name" begin
            p = polytope.rand_sphere(3,20);
            @test polytope.Polytope("my cuttie", INEQUALITIES=p.POINTS) isa Polymake.BigObject
            P = polytope.Polytope("my cuttie", INEQUALITIES=p.POINTS)
            @test occursin("my cuttie", String(Polymake.properties(P)))
        end

        @testset "conversions" begin
            p = polytope.rand_sphere(3,20);
            @test polytope.Cone(p) isa Polymake.BigObject

            # copy
            @test polytope.Polytope(p) isa Polymake.BigObject

            c = polytope.Cone(p)
            @test Polymake.type_name(c) == "Cone<Rational>"
            @test Polymake.bigobject_type(c) isa Polymake.BigObjectType

            conetype = Polymake.bigobject_type(c)
            @test Polymake.type_name(c) == Polymake.type_name(conetype)

            # a polytope is still a cone
            @test Polymake._isa(p,conetype)

            @test Polymake.cast!(p,conetype) isa Polymake.BigObject
            @test Polymake.BigObjectType("polytope::Polytope") isa Polymake.BigObjectType
            @test Polymake.type_name(p) == "Cone<Rational>"

            @test polytope.Polytope(c) isa Polymake.BigObject

            @test_throws ErrorException Polymake.cast!(c,Polymake.BigObjectType("fan::PolyhedralFan"))
        end
    end

    @testset "template parameters" begin
        @test (@pm polytope.Polytope(POINTS=points_int)) isa Polymake.BigObject
        @test (@pm polytope.Polytope{Rational}(POINTS=points_int)) isa Polymake.BigObject
        @test (@pm polytope.Polytope{QuadraticExtension}(POINTS=points_int)) isa Polymake.BigObject
        @test (@pm polytope.Polytope{QuadraticExtension{Rational}}(POINTS=points_int)) isa Polymake.BigObject

        @test (@pm polytope.Polytope(POINTS=points_rat)) isa Polymake.BigObject

        @test (@pm tropical.Polytope{Max}(POINTS=points_int)) isa Polymake.BigObject

        @test (@pm tropical.Polytope{Max}(POINTS=points_int)) isa Polymake.BigObject
        @test (@pm tropical.Polytope{Max, Rational}(POINTS=points_int)) isa Polymake.BigObject
        @test (@pm tropical.Polytope{Max, QuadraticExtension}(POINTS=points_int)) isa Polymake.BigObject

        @test (@pm tropical.Hypersurface{Min}(
            MONOMIALS=[1 0 0; 0 1 0; 0 0 1],
            COEFFICIENTS=[0, 0, 0])) isa Polymake.BigObject
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
        test_polytope = @pm polytope.Polytope(POINTS=points_int)
        @test !(:STH in Base.propertynames(test_polytope))
        @test_throws Polymake.PolymakeError test_polytope.STH
    end

    @testset "properties" begin
        test_polytope = @pm polytope.Polytope(POINTS=points_int)
        @test test_polytope.F_VECTOR == [ 4, 4 ]
        @test test_polytope.INTERIOR_LATTICE_POINTS ==
            [ 1 1 1 ; 1 1 2 ; 1 2 1 ; 1 2 2 ]

        @test test_polytope.GRAPH isa Polymake.BigObject
        test_graph = test_polytope.GRAPH
        @test :ADJACENCY in Base.propertynames(test_graph)

        @test test_polytope.LATTICE_POINTS_GENERATORS isa Polymake.Array

        test_polytope = @pm polytope.Polytope(POINTS=points_unbounded)
        @test test_polytope.FAR_FACE == Polymake.Set([1])

        c = polytope.cube(3, 1//4, -1//4)
        @test c.VERTICES[1,2] == -1//4
    end

    @testset "attachments" begin
        test_polytope = polytope.Polytope(POINTS=points_int)
        att = Polymake.Matrix{Polymake.Rational}(3,3)
        @test Polymake.attach(test_polytope,"ATT",att) === nothing
        @test Polymake.get_attachment(test_polytope,"ATT") isa Polymake.Matrix
        @test Polymake.get_attachment(Polymake.PropertyValue,test_polytope,"ATT") isa Polymake.PropertyValue
        @test Polymake.remove_attachment(test_polytope,"ATT") === nothing
        @test Polymake.get_attachment(test_polytope,"ATT") === nothing
    end

    @testset "tab-completion" begin
        test_polytope = @pm polytope.Polytope(POINTS=points_int)

        @test Base.propertynames(test_polytope) isa Base.Vector{Symbol}
        names = Base.propertynames(test_polytope)

        @test :VERTICES in names
        @test :FAR_FACE in names
        @test :GRAPH in names
        @test test_polytope.GRAPH isa Polymake.BigObject
        @test allunique(Base.propertynames(test_polytope))
        g = test_polytope.GRAPH
        @test Base.propertynames(g) isa Base.Vector{Symbol}
    end

    @testset "save load" begin
        test_polytope = @pm polytope.Polytope(POINTS=points_int)
        mktempdir() do path
            Polymake.save_bigobject(test_polytope,joinpath(path,"test.poly"))
            loaded = Polymake.load_bigobject(joinpath(path,"test.poly"))
            @test loaded isa Polymake.BigObject
            @test Base.propertynames(test_polytope) == Base.propertynames(loaded)
        end
    end

    @testset "polymake tutorials" begin
        p = @pm polytope.Polytope(POINTS=polytope.cube(4).VERTICES)
        @test p isa Polymake.BigObject

        lp = @pm polytope.LinearProgram(LINEAR_OBJECTIVE=[0,1,1,1,1])
        @test lp isa Polymake.BigObject

        @test (p.LP = lp) isa Polymake.BigObject
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

        p = @pm polytope.Polytope(POINTS=matrix)

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
        p = @pm polytope.Polytope( INEQUALITIES=[1 1 -1; -1 0 1; 7 -1 -1] )
        intvar = Polymake.Set([0,1,2])
        @test Polymake.convert(Polymake.PolymakeType, intvar) isa Polymake.Set{Polymake.to_cxx_type(Int64)}

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
