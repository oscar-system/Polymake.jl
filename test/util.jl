@testset "utilities" begin
    facets = [ 0 1 0 ; 0 0 1 ; 1 -1 0 ; 1 0 -1 ]

    @testset "prefer" begin
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

    @testset "save load" begin
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

    @testset "shell vars" begin
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
end
