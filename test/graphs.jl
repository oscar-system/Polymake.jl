@testset verbose=true "Polymake.Graph" begin
    IntTypes = [Int64]

    @testset verbose=true "constructors" begin
        c = Polymake.polytope.cube(3)
        eg = c.GRAPH.ADJACENCY
        @test Polymake.nv(eg) == 8
        @test Polymake.ne(eg) == 12
        eg2 = copy(eg)
        eg3 = Polymake.polytope.cube(3).GRAPH.ADJACENCY
        @test eg == eg2
        @test hash(eg) == hash(eg2)
        Polymake._rem_vertex(eg2,2)
        @test eg != eg2
        g = Polymake.Graph{Polymake.Directed}(5)
        @test Polymake.nv(g) == 5
        @test Polymake.ne(g) == 0
    end

    @testset verbose=true "bigobjects" begin
        c = Polymake.polytope.cube(3)
        eg = c.GRAPH.ADJACENCY
        g = Polymake.Graph{Polymake.Directed}(5)
        bg = Polymake.graph.Graph{Polymake.Directed}(ADJACENCY=g)
        @test bg.N_NODES == 5
        bg2 = Polymake.graph.Graph(ADJACENCY=eg)
        @test bg2.N_NODES == 8
    end

    @testset verbose=true "manipulating edges and vertices" begin
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

    @testset verbose=true "save load" begin
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

    @testset verbose=true "EdgeMap" begin
        g = Polymake.Graph{Polymake.Directed}(5)
        for i in 0:4
           Polymake._add_edge(g, i, (i+1)%5)
        end
        em = Polymake.EdgeMap{Polymake.Directed, Int64}(g)
        @test em isa Polymake.EdgeMap
        em[1, 2] = 1
        @test em[1, 2] == em[(1, 2)] == 1
        @test em[2, 3] == 0

        d = Dict{NTuple{2, Int}, Base.Rational{Int64}}( (5, 1) => 10, (6, 2) => 2, (7, 1) => 5, (7, 3) => 5, (7, 6) => 3, (6, 4) => 2)
        g2 = Polymake.Graph{Polymake.Undirected}(7)
        for (i,j) in keys(d)
           Polymake._add_edge(g2, i-1, j-1)
        end
        em2 = Polymake.EdgeMap(g2, d)
        @test em2[5, 1] == 10
        @test em2[1, 5] == 10
        @test Polymake.ne(g2) == 6
        em3 = Polymake.EdgeMap(g2, d)
        @test em3 == em2
        @test hash(em2) == hash(em3)
        @test em != em2
    end

    @testset verbose=true "NodeMap" begin
        c = Polymake.polytope.cube(3)
        faces = c.HASSE_DIAGRAM.FACES
        @test faces isa Polymake.NodeMap
        @test faces isa Polymake.NodeMap{Polymake.Directed, Polymake.Set{Polymake.PmInt64}}
        @test faces[1] == Set([0,1,2,3,4,5,6,7])
        nm = Polymake.NodeMap{Polymake.Directed, Int64}(c.HASSE_DIAGRAM.ADJACENCY)
        nm[1] = 10
        @test nm[1] == 10

        dec = c.HASSE_DIAGRAM.DECORATION
        @test dec isa Polymake.NodeMap{Polymake.Directed, Polymake.BasicDecoration}
        decc = copy(dec)
        @test dec[1] == Polymake.BasicDecoration(Set(0:7), 4)
        decc[1] = Polymake.BasicDecoration(Polymake.Set(0:2), 2)
        @test decc[1] == Polymake.BasicDecoration((Set(0:2), 2))


        g = Polymake.Graph{Polymake.Undirected}(7)
        nl = Dict(5 => "", 4 => "Rabbit", 6 => "Mouse", 7 => "Rat", 2 => "Wolf", 3 => "", 1 => "")
        nm = Polymake.NodeMap(g, nl)
        @test nm[4] == "Rabbit"
        nm2 = Polymake.NodeMap(g, nl)
        @test nm == nm2
        @test hash(nm) == hash(nm2)
    end

    @testset verbose=true "shortest_path_dijkstra" begin
        g = Polymake.Graph{Polymake.Directed}(5)
        for i in 0:4
           Polymake._add_edge(g, i, (i+1)%5)
        end
        em = Polymake.EdgeMap{Polymake.Directed, Int64}(g)
        em[1, 2] = 1
        @test Polymake._shortest_path_dijkstra(g, em, 0, 1, true) == [0,1]
        @test Polymake._shortest_path_dijkstra(g, em, 0, 1, false) == [0,4,3,2,1]
    end
    @testset verbose=true "graph isomorphism" begin
        g = Polymake.Graph{Polymake.Directed}(7)
        for i in 0:3
           Polymake._add_edge(g, i, i+1)
        end
        Polymake._add_edge(g, 2, 5)
        Polymake._add_edge(g, 2, 6)

        gcf = Polymake._canonical_form(g)
        @test Polymake._is_isomorphic(g, gcf)

        perm = Polymake._canonical_perm(g, Polymake.Array{Int}(fill(1,7)))
        gp = Polymake._permute_nodes(g, perm)
        Polymake._permute_nodes!(g, perm)
        for i in 0:6
           for j in 0:6
              @test Polymake._has_edge(gp, i, j) == Polymake._has_edge(gcf, i, j)
              @test Polymake._has_edge(g, i, j) == Polymake._has_edge(gcf, i, j)
           end
        end

        gs1 = Polymake.Graph{Polymake.Undirected}(3)
        gs2 = Polymake.Graph{Polymake.Undirected}(3)
        Polymake._add_edge(gs1, 0, 1)
        Polymake._add_edge(gs2, 1, 2)

        @test Polymake._is_isomorphic(gs1, gs2)
        @test !Polymake._is_isomorphic_with_colors(gs1, Polymake.Array{Int}([1,2,3]), gs2, Polymake.Array{Int}([1,2,3]))
        @test Polymake._is_isomorphic_with_colors(gs1, Polymake.Array{Int}([1,1,2]), gs2, Polymake.Array{Int}([2,1,1]))
        @test Polymake._automorphisms(gs1) == [[1,0,2]]
        @test Polymake._automorphisms(gs1, Polymake.Array{Int}([1,2,3])) == []

        cubeg = Polymake.polytope.cross(2).GRAPH.ADJACENCY
        crossg = Polymake.polytope.cube(2).GRAPH.ADJACENCY
        @test Polymake._canonical_hash(cubeg, 42) == Polymake._canonical_hash(crossg, 42)
        @test Polymake._canonical_hash(cubeg, Polymake.Array{Int}([1,1,1,1]), 42) == Polymake._canonical_hash(crossg, Polymake.Array{Int}([1,1,1,1]), 42)
        @test Polymake._canonical_hash(cubeg, 42) != Polymake._canonical_hash(g, 42)
    end
end

