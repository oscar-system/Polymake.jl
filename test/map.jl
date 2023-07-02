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
    end
end
