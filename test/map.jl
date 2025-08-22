@testset verbose=true "Polymake.Map" begin
    @test Polymake.Map{String,String} <: AbstractDict{String,String}
    @testset verbose=true "Constructors" begin
        @test Polymake.Map{String,String}() isa Polymake.Map{Polymake.to_cxx_type(String),Polymake.to_cxx_type(String)}
    end
    @testset verbose=true "Accessing the content" begin
        M = Polymake.Map{String,String}()
        M["one"] = "Eins"
        @test M["one"] isa String
        @test M["one"] == "Eins"
        @test_throws ErrorException M["two"]
        @testset verbose=true "Iterator" begin
            M["zero"] = "Null"
            M["infinity"] = "Unendlich"
            @test eltype(M) == Pair{String,String}
            @test sort(collect(M)) == sort(["one" => "Eins", "zero" => "Null", "infinity" => "Unendlich"])
        end
        d = Dict{String,Int}("Rat" => 6, "Rabbit" => 3, "Wolf" => 1, "Mouse" => 5)
        M2 = Polymake.Map(d)
        @test length(d) == 4
        @test M2["Rat"] == 6
        @test_throws ErrorException M2["Cat"]
    end
end
