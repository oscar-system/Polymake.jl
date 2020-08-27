@testset "Polymake.Map" begin
    @test Map{String,String} <: Dict{Polymake.to_cxx_type(String),Polymake.to_cxx_type(String)}
    @testset "Constructors" begin
        @test Polymake.Map{String,String}() isa Polymake.Map{Polymake.to_cxx_type(String),Polymake.to_cxx_type(String)}
    end
    @testset "Accessing the content" begin
        M = Polymake.Map{String,String}()
        M["one"] = "Eins"
        @test M["one"] isa String
        @test M["one"] == "Eins"
        @test_throws KeyError M["two"] #might need implementation
        @testset "Iterator" begin
            M["zero"] = "Null"
            M["infinity"] = "Unendlich"
            @test eltype(M) == Pair{String,String}
            @test sort(collect(M)) == sort(["one" => "Eins", "zero" => "Null", "infinity" => "Unendlich"])
        end
    end
end
