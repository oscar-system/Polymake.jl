@testset "pm_Integer" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]

    @testset "Constructors/Conversions" begin
        @test pm_Integer <: Integer

        # constructors
        for T in [IntTypes; [Float64, BigFloat]]
            @test pm_Integer(T(2)) isa pm_Integer
        end

        a = pm_Integer(5)

        # no copy conversions
        @test convert(Integer,a) === a
        @test convert(pm_Integer, a) === a

        # conversions to Integer types
        for T in IntTypes
            @test T(a) isa T
            @test convert(T, a) isa T
            @test convert(pm_Integer, T(a)) isa pm_Integer
            @test convert(pm_Integer, T(a)) isa Polymake.pm_IntegerAllocated
        end
        @test big(a) isa BigInt

        # conversion to other Number types
        @test convert(Float64, a) isa Float64
        @test Float64(a) isa Float64

        @test float(a) == convert(BigFloat, a)

        # julia arrays
        @test Array{Any,1}([a,1])[1] isa Polymake.pm_IntegerAllocated
        @test [a,1] isa Vector{pm_Integer}
        @test [a,a] isa Vector{Polymake.pm_IntegerAllocated}
    end

    @testset "Arithmetic" begin
        a = pm_Integer(2)
        @test -a == -2
        # for T in [IntTypes; pm_Integer]
        for T in IntTypes
            b = T(5)
            # Equality
            @test a == T(2)
            @test T(2) == a

            # check promotion
            @test a + b isa pm_Integer
            @test b + a isa pm_Integer
            @test a - b isa pm_Integer
            @test b - a isa pm_Integer
            @test a * b isa pm_Integer
            @test b * a isa pm_Integer

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
        ZERO = pm_Integer(0)
        ONE = pm_Integer(1)

        @test one(ZERO) isa pm_Integer
        @test zero(ZERO) isa pm_Integer
        @test one(pm_Integer) isa pm_Integer
        @test zero(pm_Integer) isa pm_Integer

        @test zero(pm_Integer) == zero(ONE) == ZERO
        @test one(pm_Integer) == one(ZERO) == ONE
    end
end
