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

    @testset "EdgeMap" begin
        g = Polymake.Graph{Polymake.Directed}(5)
        for i in 0:4
           Polymake._add_edge(g, i, (i+1)%5)
        end
        em = Polymake.EdgeMap{Polymake.Directed, Int64}(g)
        @test em isa Polymake.EdgeMap
        Polymake._set_entry(em, 0, 1, 1)
        @test Polymake._get_entry(em, 0, 1) == 1
        @test Polymake._get_entry(em, 1, 2) == 0
    end

    @testset "NodeMap" begin
        c = Polymake.polytope.cube(3)
        faces = c.HASSE_DIAGRAM.FACES
        @test faces isa Polymake.NodeMap
        @test faces isa Polymake.NodeMap{Polymake.Directed, Polymake.Set{Polymake.to_cxx_type(Int64)}}
        @test Polymake._get_entry(faces, 0) == Set([0,1,2,3,4,5,6,7])
        nm = Polymake.NodeMap{Polymake.Directed, Int64}(c.HASSE_DIAGRAM.ADJACENCY)
        Polymake._set_entry(nm, 0, 10)
        @test Polymake._get_entry(nm, 0) == 10
    end

    @testset "shortest_path_dijkstra" begin
        g = Polymake.Graph{Polymake.Directed}(5)
        for i in 0:4
           Polymake._add_edge(g, i, (i+1)%5)
        end
        em = Polymake.EdgeMap{Polymake.Directed, Int64}(g)
        Polymake._set_entry(em, 0, 1, 1)
        @test Polymake._shortest_path_dijkstra(g, em, 0, 1, true) == [0,1]
        @test Polymake._shortest_path_dijkstra(g, em, 0, 1, false) == [0,4,3,2,1]
    end
end

