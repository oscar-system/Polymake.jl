using Mongoc

Polymake.Polydb._set_uri(get(ENV, "POLYDB_SERVER_URI", ""))

@testset "polyDB" begin

    @testset "Basic functionality" begin
        @test Polymake.Polydb.get_db() isa Polymake.Polydb.Database
        db = Polymake.Polydb.get_db()
        @test db["Polytopes.Lattice.SmoothReflexive"] isa Polymake.Polydb.Collection
        @test db["Polytopes.Lattice.SmoothReflexive"] isa Polymake.Polydb.Collection{Polymake.BigObject}
        collection_bo = db["Polytopes.Lattice.SmoothReflexive"]
        @test Polymake.Polydb.Collection{Mongoc.BSON}(collection_bo) isa Polymake.Polydb.Collection
        @test Polymake.Polydb.Collection{Mongoc.BSON}(collection_bo) isa Polymake.Polydb.Collection{Mongoc.BSON}
        collection_bson = Polymake.Polydb.Collection{Mongoc.BSON}(collection_bo)
        constraints = ["DIM" => 3, "N_VERTICES" => 8]
        query = Dict(constraints...)
        @test Polymake.Polydb.find(collection_bo, query) isa Polymake.Polydb.Cursor
        @test Polymake.Polydb.find(collection_bo, query) isa Polymake.Polydb.Cursor{Polymake.BigObject}
        @test Polymake.Polydb.find(collection_bo, constraints...) isa Polymake.Polydb.Cursor
        @test Polymake.Polydb.find(collection_bo, constraints...) isa Polymake.Polydb.Cursor{Polymake.BigObject}
        @test Polymake.Polydb.find(collection_bson, query) isa Polymake.Polydb.Cursor
        @test Polymake.Polydb.find(collection_bson, query) isa Polymake.Polydb.Cursor{Mongoc.BSON}
        @test Polymake.Polydb.find(collection_bson, constraints...) isa Polymake.Polydb.Cursor
        @test Polymake.Polydb.find(collection_bson, constraints...) isa Polymake.Polydb.Cursor{Mongoc.BSON}
        @testset "Iterator (Cursor)" begin
            results_bo = Polymake.Polydb.find(collection_bo, constraints...)
            results_bson = Polymake.Polydb.find(collection_bson, constraints...)
            @test iterate(results_bo) isa Tuple{Polymake.BigObject, Nothing}
            @test iterate(results_bson) isa Tuple{Mongoc.BSON, Nothing}
            results_bo = Polymake.Polydb.find(collection_bo, constraints...)
            results_bson = Polymake.Polydb.find(collection_bson, constraints...)
            @test collect(results_bo) isa Array{Polymake.BigObject, 1}
            @test collect(results_bson) isa Array{Mongoc.BSON, 1}
        end
        @testset "Iterator (Collection)" begin
            @test iterate(collection_bo) isa Tuple{Polymake.BigObject, Polymake.Polydb.Cursor{Polymake.BigObject}}
            @test iterate(collection_bson) isa Tuple{Mongoc.BSON, Mongoc.Cursor}
            @test collect(collection_bo) isa Array{Polymake.BigObject}
            @test collect(collection_bson) isa Array{Mongoc.BSON}
        end
        @testset "Information" begin
            @test Polymake.Polydb.get_fields(collection_bo) isa Array{String, 1}
            fields = Polymake.Polydb.get_fields(collection_bo)
            @test length(fields) == 44
            @test fields[1] == "AFFINE_HULL"
        end
    end

    @testset "Basic querying" begin
        db = Polymake.Polydb.get_db()
        collection_bo = db["Polytopes.Lattice.SmoothReflexive"]
        @testset "`Polymake.BigObject`-templated types" begin
            complete = collect(collection_bo)
            @test length(complete) == 25
            constraints = ["N_VERTICES" => 8]
            query = Dict(constraints...)
            results = collect(Polymake.Polydb.find(collection, constraints...))
        end
    end

    @testset "Query macros" begin
        @test 1 == 1
    end
end
