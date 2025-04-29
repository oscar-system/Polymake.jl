@testset verbose=true "bigobject" begin
    points_int = [ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]
    points_rat = Rational{Int}[ 1 0 0 ; 1 3 0 ; 1 0 3 ; 1 3 3 ]
    points_unbounded = [1 0 0; 0 1 1]

    @testset verbose=true "constructors" begin
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

        @test Polymake.bigobject("fulton::CyclicQuotient", N=7, Q=2) isa Polymake.BigObject

        G = Polymake.graph.complete(4).ADJACENCY
        @test G isa Polymake.GraphAllocated{Polymake.Undirected}
        @test Polymake.bigobject("graph::Graph", ADJACENCY=G) isa Polymake.BigObject

        @test Polymake.graph.PartiallyOrderedSet{Polymake.BasicDecoration}() isa Polymake.BigObject

        @test polytope.cube(3, 1//4, -1//4) isa Polymake.BigObject

        # make sure initial checks are run during construction (via commit)
        @test_throws ErrorException polytope.Polytope(POINTS=zeros(Int,0,3), INPUT_LINEALITY=zeros(Int,0,2))

        # unless specifying no initial properties
        empty = polytope.Polytope()
        @test setproperty!(empty, :CONE_AMBIENT_DIM, 3) === 3
        @test setproperty!(empty, :POINTS, zeros(Int,0,3)) isa Polymake.Matrix
        @test setproperty!(empty, :INPUT_LINEALITY, zeros(Int,0,2)) isa Polymake.Matrix
        # still needs to fail on first give call
        @test_throws Polymake.PolymakeError Polymake.give(empty, "CONE_DIM")


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

        @testset verbose=true "giving polytope a name" begin
            p = polytope.rand_sphere(3,20);
            @test polytope.Polytope("my cuttie", INEQUALITIES=p.POINTS) isa Polymake.BigObject
            P = polytope.Polytope("my cuttie", INEQUALITIES=p.POINTS)
            @test occursin("my cuttie", String(Polymake.properties(P)))
        end

        @testset verbose=true "copy" begin
            p = polytope.cube(3)
            @test Polymake.exists(p,"F_VECTOR") == false
            pc = copy(p)
            @test pc.F_VECTOR isa Polymake.Vector
            pdc = deepcopy(p)
            @test pdc.F_VECTOR isa Polymake.Vector
            @test Polymake.exists(p,"F_VECTOR") == false
            @test Polymake.exists(pc,"F_VECTOR") == true
            @test Polymake.exists(pdc,"F_VECTOR") == true
         end

        @testset verbose=true "conversions" begin
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
            @test_throws ArgumentError Polymake.fan.PolyhedralFan(c)
        end
    end

    @testset verbose=true "template parameters" begin
        @test (@pm polytope.Polytope(POINTS=points_int)) isa Polymake.BigObject
        @test (@pm polytope.Polytope{Rational}(POINTS=points_int)) isa Polymake.BigObject
        @test (@pm polytope.Polytope{QuadraticExtension}(POINTS=points_int)) isa Polymake.BigObject
        @test (@pm polytope.Polytope{QuadraticExtension{Rational}}(POINTS=points_int)) isa Polymake.BigObject

        @test (@pm polytope.Polytope(POINTS=points_rat)) isa Polymake.BigObject

        @test (@pm tropical.Polytope{Max}(POINTS=points_int)) isa Polymake.BigObject

        tp = @pm tropical.Polytope{Max}(POINTS=points_int)
        @test Polymake.bigobject_eltype(tp) == "Rational"

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
        @test Polymake.bigobject_eltype(P) == "Float"
        P = @pm polytope.Polytope(POINTS=[1 0.5 0; 1 0 1])
        @test P.VERTICES isa Polymake.Matrix{Polymake.Rational}
        P = @pm polytope.Polytope{Rational}(POINTS=[1 0.5 0; 1 0 1])
        @test P.VERTICES isa Polymake.Matrix{Polymake.Rational}
        @test Polymake.bigobject_eltype(P) == "Rational"
        @test Polymake.bigobject_qualifiedname(P) == "polytope::Polytope<Rational>"
    end

    @testset verbose=true "PolymakeException" begin
        test_polytope = @pm polytope.Polytope(POINTS=points_int)
        @test !(:STH in Base.propertynames(test_polytope))
        @test_throws Polymake.PolymakeError test_polytope.STH
    end

    @testset verbose=true "properties" begin
        test_polytope = @pm polytope.Polytope(POINTS=points_int)
        @test Polymake.list_properties(test_polytope) isa Polymake.Array
        @test in("POINTS", Polymake.list_properties(test_polytope))
        @test test_polytope.F_VECTOR == [ 4, 4 ]
        let prli = Polymake.list_properties(test_polytope)
            @test "POINTS" in prli
            @test "F_VECTOR" in prli
        end
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
        
        i = Polymake.polytope.icosahedron()
        @test i.VERTICES[1, :] == [1, 0, Polymake.QuadraticExtension{Polymake.Rational}(1//4, 1//4, 5), 1//2]
        @test i.VOLUME == Polymake.QuadraticExtension{Polymake.Rational}(5//4, 5//12, 5)
        @test Polymake.bigobject_eltype(i) == "QuadraticExtension"

        undefobj = Polymake.polytope.Polytope(POINTS=nothing)
        @test undefobj.POINTS === nothing
    end

    @testset verbose=true "attachments" begin
        test_polytope = polytope.Polytope(POINTS=points_int)
        att = Polymake.Matrix{Polymake.Rational}(3,3)
        @test Polymake.attach(test_polytope,"ATT",att) === nothing
        @test Polymake.get_attachment(test_polytope,"ATT") isa Polymake.Matrix
        @test Polymake.get_attachment(Polymake.PropertyValue,test_polytope,"ATT") isa Polymake.PropertyValue
        @test Polymake.remove_attachment(test_polytope,"ATT") === nothing
        @test Polymake.get_attachment(test_polytope,"ATT") === nothing

        stra = Polymake.Array{String}(["hello", "world"])
        @test Polymake.attach(test_polytope, "STRA", stra) === nothing
        # @test Polymake.get_attachment(test_polytope) .== ["hello", "world"]
    end

    @testset verbose=true "tab-completion" begin
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

    @testset verbose=true "polymake tutorials" begin
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

    @testset verbose=true "polymake MILP" begin
        p = @pm polytope.Polytope( INEQUALITIES=[1 1 -1; -1 0 1; 7 -1 -1] )
        intvar = Polymake.Set([0,1,2])
        @test Polymake.convert(Polymake.PolymakeType, intvar) isa Polymake.Set{Polymake.PmInt64}

        obj = [0,-1,-1]

        @test (@pm polytope.MixedIntegerLinearProgram( LINEAR_OBJECTIVE = obj, INTEGER_VARIABLES = intvar)) isa Polymake.BigObject

        pmintvar = Polymake.Set(intvar)

        @test (@pm polytope.MixedIntegerLinearProgram( LINEAR_OBJECTIVE = obj, INTEGER_VARIABLES = pmintvar)) isa Polymake.BigObject

        p.MILP = @pm polytope.MixedIntegerLinearProgram( LINEAR_OBJECTIVE = obj, INTEGER_VARIABLES = intvar)

        @test p.MILP.MINIMAL_VALUE == -7
    end

    @testset verbose=true "poly2lp2poly" begin
        p = polytope.Polytope( INEQUALITIES=[1 1 -1; -1 0 1; 7 -1 -1] )
        lp = polytope.LinearProgram(LINEAR_OBJECTIVE=[0,1,1])
        p.LP = lp
        x = mktemp() do path, _
           @test Polymake.polytope.poly2lp(p,lp, false, path) == 1
           return Polymake.polytope.lp2poly(path)
        end
        @test x isa Polymake.BigObject
        @test p.LP.LINEAR_OBJECTIVE == x.LP.LINEAR_OBJECTIVE
    end

    @testset verbose=true "multiple subobjects" begin
        p = polytope.Polytope( INEQUALITIES=[1 1 -1; -1 0 1; 7 -1 -1] )
        lp1 = polytope.LinearProgram(LINEAR_OBJECTIVE=[0,1,0])
        lp2 = polytope.LinearProgram(LINEAR_OBJECTIVE=[0,0,1])
        lp3 = polytope.LinearProgram(LINEAR_OBJECTIVE=[0,2,1])
        p.LP = lp1
        Polymake.add(p,"LP",lp2)
        Polymake.add(p,"LP","third",lp3)
        @test Polymake._lookup_multi(p,"LP") isa Polymake.Array{Polymake.BigObject}
        @test length(Polymake._lookup_multi(p,"LP")) == 3
        @test Polymake._lookup_multi(p,"LP","third").LINEAR_OBJECTIVE == lp3.LINEAR_OBJECTIVE
        @test Polymake._lookup_multi(p,"LP",1).LINEAR_OBJECTIVE == lp2.LINEAR_OBJECTIVE
        @test p.LP.LINEAR_OBJECTIVE == lp1.LINEAR_OBJECTIVE
        @test_throws ErrorException Polymake._lookup_multi(p,"LP",3)
        @test_throws ErrorException Polymake._lookup_multi(p,"LP","nonexisting")
    end

    @testset verbose=true "bigobject array" begin
        c = polytope.cube(3)
        c_type = Polymake.bigobject_type(c)
        @test Polymake.Array{Polymake.BigObject}(c_type,2) isa Polymake.Array{Polymake.BigObject}
        arr = Polymake.Array{Polymake.BigObject}(c_type,2)
        @test length(arr) == 2
        arr[1] = c
        arr[2] = polytope.simplex(2)
        @test arr[1] isa Polymake.BigObject
        @test arr[2] isa Polymake.BigObject
        @test arr[1].N_VERTICES == 8

        c = polytope.cross(3)
        @test Polymake.polytope.free_sum_decomposition(c) isa Polymake.Array{Polymake.BigObject}
        arr = Polymake.polytope.free_sum_decomposition(c)
        @test length(arr) == 3
        @test arr[1].CONE_DIM == 2
        @test arr[3].CONE_DIM == 2
    end


    @testset verbose=true "toplevel visual" begin
        @test visual(Polymake.Visual, polytope.cube(3)) isa Polymake.Visual
    end

    @testset verbose=true "names and description" begin
        p = polytope.cube(3)
        Polymake.setname!(p,"somename")
        @test occursin("somename", String(Polymake.getname(p)))
        Polymake.setname!(p,"other")
        @test occursin("other", String(Polymake.getname(p)))
        @test occursin("cube of dimension", String(Polymake.getdescription(p)))
        Polymake.setdescription!(p, "dual of the cross polytope")
        @test occursin("cross polytope", String(Polymake.getdescription(p)))
    end

end

@testset verbose=true "OptionSet" begin
    @test Polymake.OptionSet(Dict(:asdf => [1, 2, 3])) isa Polymake.OptionSet
end
