@testset "Polymake.Graph" begin
    IntTypes = [Int64]

    @testset "constructors" begin
        c = Polymake.polytope.cube(3)
        eg = c.GRAPH.ADJACENCY
        @test Polymake.nv(eg) == 8
        @test Polymake.ne(eg) == 12
        g = Polymake.Graph{Polymake.Directed}(5)
        @test Polymake.nv(g) == 5
        @test Polymake.ne(g) == 0
    end

    @testset "manipulating edges and vertices" begin
        g = Polymake.Graph{Polymake.Directed}(5)
        Polymake._add_edge(g, 0, 1)
        @test Polymake.ne(g) == 1
        @test Polymake._has_edge(g, 0, 1)
        @test !Polymake._has_edge(g, 1, 0)
        @test !Polymake._has_vertex(g, 5)
        Polymake._add_vertex(g)
        @test Polymake._has_vertex(g, 5)
        Polymake._rem_vertex(g, 5)
        @test !Polymake._has_vertex(g, 5)
        Polymake._rem_edge(g, 0, 1)
        @test !Polymake._has_edge(g, 0, 1)
    end

    @testset "save load" begin
        G = Polymake.graph.complete(4);
        g = G.ADJACENCY;
        mktempdir() do path
            Polymake.save(g, joinpath(path, "test.graph"))
            loaded = Polymake.load(joinpath(path, "test.graph"))
            @test loaded isa Polymake.Graph{Polymake.Undirected}
            @test Polymake.nv(g) == Polymake.nv(loaded)
            @test Polymake.ne(g) == Polymake.ne(loaded)
        end
    end
end

