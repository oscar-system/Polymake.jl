using Mongoc

@testset "polyDB" begin
    # conditions from which the test database dump was generated.
    add_constraints_poly = ["DIM" => Dict("\$lte" => 3)]
    function _acp(a::Array)
        return append!(Array{Pair{String,Any}}(a), add_constraints_poly)
    end
    add_constraints_mat = [:("N_ELEMENTS" <= 4)]
    function _acm(a::Array)
        return append!(Array{Expr}(a), add_constraints_mat)
    end

    @testset "Basic functionality" begin
        # Types
        @test Polymake.Polydb.get_db() isa Polymake.Polydb.Database
        db = Polymake.Polydb.get_db()
        @test db["Polytopes.Lattice.SmoothReflexive"] isa Polymake.Polydb.Collection
        @test db["Polytopes.Lattice.SmoothReflexive"] isa Polymake.Polydb.Collection{Polymake.BigObject}
        try
            @test Mongoc.ping(db.mdb.client)["ok"] == 1
        catch
            @test "not" == "connected"
        end
        collection_bo = db["Polytopes.Lattice.SmoothReflexive"]
        @test Polymake.Polydb.Collection{Mongoc.BSON}(collection_bo) isa Polymake.Polydb.Collection
        @test Polymake.Polydb.Collection{Mongoc.BSON}(collection_bo) isa Polymake.Polydb.Collection{Mongoc.BSON}
        collection_bson = Polymake.Polydb.Collection{Mongoc.BSON}(collection_bo)
        @test Polymake.Polydb.Collection{Polymake.BigObject}(collection_bson) isa Polymake.Polydb.Collection
        @test Polymake.Polydb.Collection{Polymake.BigObject}(collection_bson) isa Polymake.Polydb.Collection{Polymake.BigObject}
        constraints = _acp(["DIM" => 3, "N_VERTICES" => 8])
        query = Dict(constraints...)
        # Queries
        @test Polymake.Polydb.find(collection_bo, query) isa Polymake.Polydb.Cursor
        @test Polymake.Polydb.find(collection_bo, query) isa Polymake.Polydb.Cursor{Polymake.BigObject}
        @test Polymake.Polydb.find(collection_bo, constraints...) isa Polymake.Polydb.Cursor
        @test Polymake.Polydb.find(collection_bo, constraints...) isa Polymake.Polydb.Cursor{Polymake.BigObject}
        @test Polymake.Polydb.find(collection_bson, query) isa Polymake.Polydb.Cursor
        @test Polymake.Polydb.find(collection_bson, query) isa Polymake.Polydb.Cursor{Mongoc.BSON}
        @test Polymake.Polydb.find(collection_bson, constraints...) isa Polymake.Polydb.Cursor
        @test Polymake.Polydb.find(collection_bson, constraints...) isa Polymake.Polydb.Cursor{Mongoc.BSON}
        results_bo = Polymake.Polydb.find(collection_bo, constraints...)
        @test Polymake.Polydb.Cursor{Mongoc.BSON}(results_bo) isa Polymake.Polydb.Cursor
        @test Polymake.Polydb.Cursor{Mongoc.BSON}(results_bo) isa Polymake.Polydb.Cursor{Mongoc.BSON}
        results_bson = Polymake.Polydb.find(collection_bson, constraints...)
        @test Polymake.Polydb.Cursor{Polymake.BigObject}(results_bson) isa Polymake.Polydb.Cursor
        @test Polymake.Polydb.Cursor{Polymake.BigObject}(results_bson) isa Polymake.Polydb.Cursor{Polymake.BigObject}
        @testset "Iterator (Cursor)" begin
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
        end
        @testset "Information" begin
            for (col, f_name) in [(collection_bo, "FACETS"), (db["Matroids.Small"], "N_ELEMENTS")]
                @test Polymake.Polydb.get_fields(col) isa Array{String, 1}
                fields = Polymake.Polydb.get_fields(col)
                @test length(fields) > 10
                @test f_name in fields
                @test repr(col) isa String
            end
            @test Polymake.Polydb.get_collection_names(db) isa Array{String}
            collections = Polymake.Polydb.get_collection_names(db)
            # this only checks if print is non-empty
            io = IOBuffer()
            Polymake.Polydb.info(db, 1, io)
            infostring = String(take!(io))
            @test length(infostring) > 50
        end
    end

    @testset "Basic querying" begin
        db = Polymake.Polydb.get_db()
        collection_bo = db["Polytopes.Lattice.SmoothReflexive"]
        for (template, access) in   [(Polymake.BigObject, :((x,y) -> getproperty(x, Symbol(y)))),
                                    (Mongoc.BSON, :((x,y) -> x[y]))]
            collection = Polymake.Polydb.Collection{template}(collection_bo)
            @testset "`$template`-templated types" begin
                for (constraints, amount, op) in    [(_acp(["N_VERTICES" => 8]), 7, :(==)),
                                                    (_acp(["N_VERTICES" => Dict("\$lt" => 8)]), 12, :<),
                                                    (_acp(["N_VERTICES" => Dict("\$gt" => 8)]), 6, :>)]
                    query = Dict(constraints...)
                    for results in  [collect(Polymake.Polydb.find(collection, constraints...)),
                                    collect(Polymake.Polydb.find(collection, query))]
                        @test length(results) == amount
                        for obj in results
                            @eval @test $op($access($obj, "N_VERTICES"), 8)
                        end
                    end
                end
                let constraints = ["N_VERTICES"=>8, "N_HILBERT_BASIS"=>27]
                    query = Dict(constraints...)
                    for results in [collect(Polymake.Polydb.find(collection, constraints...)), collect(Polymake.Polydb.find(collection, query))]
                        @test length(results) == 2
                        for obj in results
                            @eval @test $access($obj, "N_VERTICES") == 8
                            @eval @test $access($obj, "N_HILBERT_BASIS") == 27
                        end
                    end
                end
            end
        end
    end

    @testset "Query macros" begin
        db = Polymake.Polydb.get_db()
        @test Polymake.Polydb.@select("Matroids.Small") isa Function
        @test Polymake.Polydb.@select("Matroids.Small")(db) isa Polymake.Polydb.Collection
        @test Polymake.Polydb.@filter("N_ELEMENTS" == 3) isa Function
        collection = Polymake.Polydb.@select("Matroids.Small")(db)
        @test Polymake.Polydb.@filter("N_ELEMENTS" == 3)(collection) isa Tuple{Polymake.Polydb.Collection, Dict{String, <:Any}}
        @test Polymake.Polydb.@filter("N_LOOPS" > 1)(Polymake.Polydb.@filter("N_ELEMENTS" == 3)(collection)) isa Tuple{Polymake.Polydb.Collection, Dict{String, <:Any}}
        @test Polymake.Polydb.@filter("N_ELEMENTS" == 3, "N_LOOPS" > 1) isa Function
        @test Polymake.Polydb.@filter("N_ELEMENTS" == 3, "N_LOOPS" > 1)(collection) isa Tuple{Polymake.Polydb.Collection, Dict{String, Any}}
        @test Polymake.Polydb.@map() isa Function
        filter_tuple = Polymake.Polydb.@filter("N_LOOPS" > 1)(Polymake.Polydb.@filter("N_ELEMENTS" == 3)(collection))
        @test Polymake.Polydb.@map()(filter_tuple) isa Polymake.Polydb.Cursor
        selection = Polymake.Polydb.@select("Matroids.Small")
        for (constraints, amount, op) in    [([:("N_ELEMENTS" == 3)], 4, :(==)),
                                            ([:("N_ELEMENTS" < 3)], 4, :<),
                                            (_acm([:("N_ELEMENTS" > 3)]), 12, :>),
                                            (_acm([:("N_ELEMENTS" != 3)]), 16, :(!=)),
                                            ([:("N_ELEMENTS" <= 3)], 8, :(<=)),
                                            (_acm([:("N_ELEMENTS" >= 3)]), 16, :(>=))]
            filtering = @eval Polymake.Polydb.@filter($(constraints...))
            mapping = Polymake.Polydb.@map()
            results =   db |>
                        selection |>
                        filtering |>
                        mapping |>
                        collect
            @test length(results) == amount
            for obj in results
                @eval @test $op($obj.N_ELEMENTS, 3)
            end
        end
        let constraints = [:("N_ELEMENTS" == 3), :("N_LOOPS" <= 2)]
            filtering = @eval Polymake.Polydb.@filter($(constraints...))
            filtering_1 = @eval Polymake.Polydb.@filter($(constraints[1]))
            filtering_2 = @eval Polymake.Polydb.@filter($(constraints[2]))
            mapping = Polymake.Polydb.@map()
            results_single =   db |>
                        selection |>
                        filtering |>
                        mapping |>
                        collect
            results_double =    db |>
                                selection |>
                                filtering_1 |>
                                filtering_2 |>
                                mapping |>
                                collect
            for results in [results_single, results_double]
                @test length(results) == 3
                for obj in results
                    @test obj.N_ELEMENTS == 3
                    @test obj.N_LOOPS <= 2
                end
            end
        end
    end
end
