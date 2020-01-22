@testset "converting" begin
    @test Polymake.convert_to_pm_type(Polymake.Vector{Polymake.Int}) == Polymake.Vector{Polymake.Integer}
    @test Polymake.convert_to_pm_type(Polymake.Matrix{Polymake.Int}) == Polymake.Matrix{Polymake.Integer}
    @test Polymake.convert_to_pm_type(Polymake.Matrix{Base.Rational{BigInt}}) == Polymake.Matrix{Polymake.Rational}
    @test Polymake.convert_to_pm_type(Polymake.Matrix{Base.Rational{BigInt}}) == Polymake.Matrix{Polymake.Rational}

    @test Polymake.convert_to_pm_type(Polymake.Matrix{Float32}) == Polymake.Matrix{Float64}

    @test Polymake.convert_to_pm_type(Polymake.Vector{String}) == Polymake.Array{String}

    @test Polymake.convert_to_pm_type(Polymake.Array{Polymake.Set{Int32},1}) == Polymake.Array{Polymake.Set{Int32}}
    @test Polymake.convert_to_pm_type(Polymake.Array{Polymake.Set{Polymake.Integer},1}) == Polymake.Array{Polymake.Set{Int32}}
    @test Polymake.convert_to_pm_type(Polymake.Array{Polymake.Set{Int64},1}) == Polymake.Array{Polymake.Set{Int32}}

    @test Polymake.convert_to_pm_type(Polymake.Vector{Polymake.Vector{Int64}}) == Polymake.Array{Polymake.Array{Int64}}

    y = Polymake.Vector{Polymake.Set{Int32}}([Polymake.Set([3,3]), Polymake.Set([3]), Polymake.Set([1,2])])
    @test convert(Polymake.PolymakeType, y) isa Polymake.Array{Polymake.Set{Int32}}
    y = Polymake.Vector{Polymake.Set{Int64}}([Polymake.Set([3,3]), Polymake.Set([3]), Polymake.Set([1,2])])
    @test convert(Polymake.PolymakeType, y) isa Polymake.Array{Polymake.Set{Int32}}


    @testset "convert to PolymakeType" begin
        Base.convert(::Type{Polymake.PolymakeType}, n::MyInt) = n.x

        @test polytope.cube(MyInt(3)) isa Polymake.BigObject
    end
end
