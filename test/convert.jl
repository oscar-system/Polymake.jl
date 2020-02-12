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
    @test convert(Polymake.PolymakeType, y) isa Polymake.Array{Polymake.Set{Polymake.to_cxx_type(Int)}}
    y = Base.Vector{Base.Set{Int64}}([Base.Set([3,3]), Base.Set([3]), Base.Set([1,2])])
    @test convert(Polymake.PolymakeType, y) isa Polymake.Array{Polymake.Set{Polymake.to_cxx_type(Int)}}


    @testset "convert to PolymakeType" begin
        Base.convert(::Type{Polymake.PolymakeType}, n::MyInt) = n.x

        @test polytope.cube(MyInt(3)) isa Polymake.BigObject
    end

    @testset "@convert_to" begin
        @convert_to Integer 64 isa Polymake.Integer
        @test (@convert_to Array{Set{Int}} [Set([1, 2, 4, 5, 7, 8]), Set([1]), Set([6, 9])]) isa Polymake.Array{Polymake.Set{Polymake.to_cxx_type(Int64)}}
        @test (@convert_to Vector{Float} [10, 11, 12]) isa Polymake.Vector{Float64}
        @test (@convert_to Matrix{Rational} [10/1 11/1 12/1]) isa Polymake.Matrix{Polymake.Rational}
        @test_throws LoadError eval(:(@convert_to Array{Set{Int}}))
        @test_throws LoadError eval(:(@convert_to Array{Set{Int}} [Set([1, 2, 4, 5, 7, 8]), Set([1]), Set([6, 9])] Set([4, 3])))
        err = try
            eval(:(@convert_to Array{Set{Int}}))
        catch err
            err
        end
        @test err.error isa ArgumentError
        err = try
            @eval begin
                @convert_to Array{Set{Int}} [Set([1, 2, 4, 5, 7, 8]), Set([1]), Set([6, 9])] Set([4, 3])
            end
        catch err
            err
        end
        @test err.error isa ArgumentError

        @test_throws ArgumentError @convert_to Matrix{Rational} 2
        @test_throws UndefVarError @convert_to Matrix{Rational} A
    end
end
