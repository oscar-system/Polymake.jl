_test_rand_fun() = return 42

@testset verbose=true "utilities" begin
    facets = [ 0 1 0 ; 0 0 1 ; 1 -1 0 ; 1 0 -1 ]

    @testset verbose=true "prefer" begin
        pcdd = polytope.Polytope(INEQUALITIES=facets)
        plrs = polytope.Polytope(INEQUALITIES=facets)
        @test Polymake.prefer("cdd") do
                 pcdd.VERTICES
              end isa Polymake.Matrix
        vertcdd = pcdd.VERTICES
        @test Polymake.prefer("lrs.convex_hull") do
                 plrs.VERTICES
              end isa Polymake.Matrix
        vertlrs = plrs.VERTICES
        @test vertcdd != vertlrs
        scdd = Polymake.@convert_to Set{Vector{Rational}} common.rows(vertcdd)
        slrs = Polymake.@convert_to Set{Vector{Rational}} common.rows(vertlrs)
        @test common.incl(scdd,slrs) == 0
        @test_throws Polymake.PolymakeError Polymake.prefer("nonexistentlabel") do print end
    end

    @testset verbose=true "save load" begin
        test_polytope = @pm polytope.Polytope(INEQUALITIES=facets)
        mat = test_polytope.VERTICES
        vec = test_polytope.F_VECTOR
        mktempdir() do path
            Polymake.save_bigobject(test_polytope,joinpath(path,"test.poly"))
            loaded = Polymake.load_bigobject(joinpath(path,"test.poly"))
            @test loaded isa Polymake.BigObject
            @test test_polytope.VERTICES == loaded.VERTICES

            Polymake.save(test_polytope,joinpath(path,"test.poly"); canonical=true)
            loaded = Polymake.load(joinpath(path,"test.poly"))
            @test loaded isa Polymake.BigObject
            @test test_polytope.INEQUALITIES == loaded.INEQUALITIES

            Polymake.save(mat,joinpath(path,"mat.pdata"); canonical=true)
            loadedmat = Polymake.load(joinpath(path,"mat.pdata"))
            @test loadedmat == mat

            Polymake.save(vec,joinpath(path,"vec.pdata"); canonical=false)
            loadedvec = Polymake.load(joinpath(path,"vec.pdata"))
            @test loadedvec == vec
        end
    end

    @testset verbose=true "shell vars" begin
        test_polytope = @pm polytope.Polytope(INEQUALITIES=facets)

        Polymake.Shell.myvar = "Hello "
        Polymake.shell_execute(raw"""$myvar .= "World!";""")
        @test Polymake.Shell.myvar == "Hello World!"

        # bigobject is just a pointer, so modifying it in the shell will modify
        # the original object as well
        @test !Polymake.exists(test_polytope, "F_VECTOR")
        Polymake.Shell.poly = test_polytope
        Polymake.shell_execute(raw"""$poly->F_VECTOR;""")
        @test Polymake.exists(Polymake.Shell.poly,"F_VECTOR")

        # small objects will also be passed via pointer
        mat = test_polytope.VERTICES
        Polymake.Shell.mat = mat
        Polymake.shell_execute(raw"""$mat->elem(0,0)=5;""")
        newmat = Polymake.Shell.mat
        @test mat == newmat

        # but at least for now they will be returned as a copy
        Polymake.shell_execute(raw"""$mat->elem(0,0)=11;""")
        @test mat != newmat
        @test mat == Polymake.Shell.mat

        # due to the way this variable access works, accessing non-existing
        # will not throw an error but just return nothing
        @test Polymake.Shell.notexisting == nothing
    end

    @testset verbose=true "4ti2 external" begin
        m = matroid.r8_matroid()
        @test m.CIRCUITS isa Polymake.Array{Polymake.Set{Polymake.to_cxx_type(Int)}}
        @test Polymake.matroid._4ti2circuits(m.VECTORS) isa Polymake.SparseMatrix

        c = polytope.cube(3, 3//2)
        Polymake.Shell.c = c
        @test Polymake.shell_execute(raw"""$c->apply_rule("_4ti2.integer_points");""") isa NamedTuple
        @test Polymake.exists(c, "LATTICE_POINTS_GENERATORS") || Polymake.exists(c, "HILBERT_BASIS_GENERATORS")
    end


    @testset verbose=true "seeding" begin
      try
        _test_rand_cfun = Polymake.CxxWrap.@safe_cfunction(_test_rand_fun, Int64, ())
        Polymake.set_rand_source(_test_rand_cfun)
        v1 = Polymake.polytope.rand_sphere(3,10).VERTICES
        v2 = Polymake.polytope.rand_sphere(3,10).VERTICES
        vs1 = Polymake.polytope.rand_sphere(3,10; seed=42).VERTICES
        vs2 = Polymake.polytope.rand_sphere(3,10; seed=43).VERTICES
        @test v1 == v2
        @test v1 == vs1
        @test v1 != vs2
        Polymake.reset_rand_source()
        vr = Polymake.polytope.rand_sphere(3,10).VERTICES
        @test v1 != vr
      finally
        Polymake.set_rand_source()
      end
    end
end
