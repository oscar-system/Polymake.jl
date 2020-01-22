@testset "Polymake.Integer" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]

    @testset "Constructors/Conversions" begin
        @test Polymake.Integer <: Base.Integer

        # constructors
        for T in [IntTypes; [Float64, BigFloat]]
            @test Polymake.Integer(T(2)) isa Polymake.Integer
        end

        a = Polymake.Integer(5)

        # no copy conversions
        @test convert(Base.Integer,a) === a
        @test convert(Polymake.Integer, a) === a

        # conversions to Base.Integer types
        for T in IntTypes
            @test T(a) isa T
            @test convert(T, a) isa T
            @test convert(Polymake.Integer, T(a)) isa Polymake.Integer
            @test convert(Polymake.Integer, T(a)) isa Polymake.IntegerAllocated
        end
        @test big(a) isa BigInt

        # conversion to other Number types
        @test convert(Float64, a) isa Float64
        @test Float64(a) isa Float64

        @test float(a) == convert(BigFloat, a)

        # julia arrays
        @test Base.Array{Any,1}([a,1])[1] isa Polymake.IntegerAllocated
        @test [a,1] isa Base.Vector{Polymake.Integer}
        @test [a,a] isa Base.Vector{Polymake.IntegerAllocated}
    end

    @testset "Arithmetic" begin
        a = Polymake.Integer(2)
        @test -a == -2
        # for T in [IntTypes; Polymake.Integer]
        for T in IntTypes
            b = T(5)
            # Equality
            @test a == T(2)
            @test T(2) == a

            # check promotion
            @test a + b isa Polymake.Integer
            @test b + a isa Polymake.Integer
            @test a - b isa Polymake.Integer
            @test b - a isa Polymake.Integer
            @test a * b isa Polymake.Integer
            @test b * a isa Polymake.Integer

            # check arithmetic results
            @test a + b == b + a == 7
            @test a - b == -3
            @test b - a == 3
            @test a * b == b * a == 10

            @test div(a, b) == 0
            @test div(b, a) == 2
            @test rem(a, b) == 2
            @test rem(b, a) == 1
        end
    end

    @testset "zero / one" begin
        ZERO = Polymake.Integer(0)
        ONE = Polymake.Integer(1)

        @test one(ZERO) isa Polymake.Integer
        @test zero(ZERO) isa Polymake.Integer
        @test one(Polymake.Integer) isa Polymake.Integer
        @test zero(Polymake.Integer) isa Polymake.Integer

        @test zero(Polymake.Integer) == zero(ONE) == ZERO
        @test one(Polymake.Integer) == one(ZERO) == ONE
    end
end
