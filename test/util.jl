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
end
