@testset "LP_solve" begin
    c = polytope.cube(2)
    @test Polymake.solve_LP(c.VERTICES, [1, 2, 1]) == [1,1, 0]
    @test Polymake.solve_LP(c.VERTICES, [1, 1, 2]) == [1,0, 1]
    @test Polymake.solve_LP(c.VERTICES, [1,-1,-2]) == [1,0,-1]

    d = polytope.polarize(c)

    @test Polymake.solve_LP(d.VERTICES, [1, 2, 1]) == [1, 1, 1]
    @test Polymake.solve_LP(d.VERTICES, [1, 1, 2]) == [1, 1, 1]
    @test Polymake.solve_LP(d.VERTICES, [1,-1,-2]) == [1,-1,-1]
    @test Polymake.solve_LP(d.VERTICES, [1, 1,-2]) == [1, 1,-1]

    @test Polymake.solve_LP(float.(d.VERTICES), float.([1,1,2])) ≈ [1.,1.,1.]

    @test Polymake.solve_LP(float.(c.VERTICES), float.([1,2,1])) ≈ [1,1,0]
    @test Polymake.solve_LP(float.(c.VERTICES), BigFloat.([1,2,1])) ≈ [1,1,0]
end

@testset "BeneathBeyond" begin
    c = polytope.cube(4)
    bb = Polymake.BeneathBeyond(c.VERTICES)
    bb_new = deepcopy(bb)
    @test Polymake.triangulation_size(bb) == 0
    @test Polymake.triangulation_size(bb_new) == 0
    @test collect(bb) == fill(nothing, 16)
    @test Polymake.triangulation_size(bb) == 24
    @test Polymake.triangulation_size(bb_new) == 0
    @test Polymake.state(bb) == collect(0:15)
    @test Polymake.state(bb_new) == Int[]
    bb = 0
    GC.gc(); GC.gc()
    @test collect(bb_new) == fill(nothing, 16)
    @test Polymake.triangulation_size(bb_new) == 24
    bb_n = deepcopy(bb_new)
    @test collect(bb_n) == fill(nothing, 16)
    @test Polymake.triangulation_size(bb_n) == 24
end
