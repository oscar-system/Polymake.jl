@testset "converting" begin
    @test Polymake.convert_to_pm_type(Base.Vector{Base.Int}) == Polymake.Vector{Polymake.Integer}
    @test Polymake.convert_to_pm_type(Base.Matrix{Base.Int}) == Polymake.Matrix{Polymake.Integer}
    @test Polymake.convert_to_pm_type(Base.Matrix{Base.Rational{BigInt}}) == Polymake.Matrix{Polymake.Rational}
    @test Polymake.convert_to_pm_type(Base.Matrix{Base.Rational{BigInt}}) == Polymake.Matrix{Polymake.Rational}

    @test Polymake.convert_to_pm_type(Base.Matrix{Float32}) == Polymake.Matrix{Float64}

    @test Polymake.convert_to_pm_type(Base.Vector{String}) == Polymake.Array{String}

    @test Polymake.convert_to_pm_type(Base.Array{Base.Set{Int64},1}) == Polymake.Array{Polymake.Set{Int64}}
    @test Polymake.convert_to_pm_type(Base.Array{Base.Set{Polymake.Integer},1}) == Polymake.Array{Polymake.Set{Int64}}
    @test Polymake.convert_to_pm_type(Base.Array{Base.Set{Int64},1}) == Polymake.Array{Polymake.Set{Int64}}

    @test Polymake.convert_to_pm_type(Base.Vector{Base.Vector{Int64}}) == Polymake.Array{Polymake.Array{Int64}}

    y = Base.Vector{Base.Set{Int64}}([Base.Set([3,3]), Base.Set([3]), Base.Set([1,2])])
    @test convert(Polymake.PolymakeType, y) isa Polymake.Array{Polymake.Set{Int64}}
    y = Base.Vector{Base.Set{Int64}}([Base.Set([3,3]), Base.Set([3]), Base.Set([1,2])])
    @test convert(Polymake.PolymakeType, y) isa Polymake.Array{Polymake.Set{Int64}}


    @testset "convert to PolymakeType" begin
        Base.convert(::Type{Polymake.PolymakeType}, n::MyInt) = n.x

        @test polytope.cube(MyInt(3)) isa Polymake.BigObject
    end
end
