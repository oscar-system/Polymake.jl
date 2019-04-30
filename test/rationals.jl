@testset "pm_Rational" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]

    @testset "Constructors/Conversions" begin
        @test pm_Rational <: Real

        # constructors
        for T in [IntTypes; pm_Integer]
            @test pm_Rational(T(2), T(2)) isa pm_Rational
            @test pm_Rational(T(1)) isa pm_Rational
        end

        for T in IntTypes
            @test pm_Rational(T(2)//T(3)) isa pm_Rational
        end

        for T in [Float64, BigFloat]
            @test pm_Rational(T(2)) isa pm_Rational
        end

        a = pm_Rational(4,3)

        # no copy conversion:
        @test convert(pm_Rational, a) === a

        # conversions to Rational types
        for T in IntTypes
            RT = Rational{T}
            @test RT(a) isa RT
            @test convert(pm_Rational, RT(a)) isa pm_Rational
            @test convert(pm_Rational, RT(a)) isa Polymake.pm_RationalAllocated
        end
        @test Rational(a) isa Rational{BigInt}
        @test big(a) isa Rational{BigInt}

        # conversion to other Number types
        @test convert(Float64, a) isa Float64
        @test Float64(a) isa Float64
        @test float(a) == convert(BigFloat, a)

        # julia arrays
        @test Array{Any,1}([a,1])[1] isa Polymake.pm_RationalAllocated
        @test [a,1] isa Vector{pm_Rational}
        @test [a,a] isa Vector{Polymake.pm_RationalAllocated}
    end

    @testset "Arithmetic" begin

        @testset "Equality" begin
            a = pm_Rational(2, 6)
            for T in IntTypes
                b = Rational(T(2), T(6))
                @test a == b
                @test b == a
            end

            a = pm_Rational(5, 1)
            for T in [IntTypes; pm_Integer]
                b = T(5)
                @test a == b
                @test b == a
            end
        end

        @testset "Rational division" begin
            a = pm_Rational(4,5)
            for T in [IntTypes; pm_Integer]
                @test pm_Integer(4)//T(5) isa pm_Rational
                @test T(5)//pm_Integer(5) isa pm_Rational
                @test pm_Integer(4)//T(5) == T(4)//pm_Integer(5) == a

                @test a//T(2) isa pm_Rational
                @test a//T(2) == 2//5

                @test T(2)//a isa pm_Rational
                @test T(2)//a == 5//2
            end
            @test a//a == pm_Rational(1)
        end

        a = pm_Rational(2, 1)
        A = pm_Integer(2)
        @test -a == -2
        for T in [IntTypes; pm_Integer]
            b = T(5)
            # check promotion
            @test a + b isa pm_Rational
            @test b + a isa pm_Rational
            @test a - b isa pm_Rational
            @test b - a isa pm_Rational
            @test a * b isa pm_Rational
            @test b * a isa pm_Rational

            # check arithmetic results
            @test a + b == b + a == 7
            @test a - b == -3
            @test b - a == 3
            @test a * b == b * a == 10
            @test a // b == 2 // 5
            @test b // a == 5 // 2
        end

        a = pm_Rational(1, 14)
        for T in [IntTypes; pm_Integer]
            b = T(5)//T(7)
            # check promotion
            @test a + b isa pm_Rational
            @test b + a isa pm_Rational
            @test a - b isa pm_Rational
            @test b - a isa pm_Rational
            @test a * b isa pm_Rational
            @test b * a isa pm_Rational

            # check arithmetic results
            @test a + b == b + a == 11 // 14
            @test a - b == -9 // 14
            @test b - a == 9 // 14
            @test a * b == b * a == 5 // 98
            @test a // b == 1//10
            @test b // a == 10
        end
    end

    @testset "zero / one" begin
        ZERO = pm_Rational(0)
        ONE = pm_Rational(1)

        @test one(ZERO) isa pm_Rational
        @test zero(ZERO) isa pm_Rational
        @test one(pm_Rational) isa pm_Rational
        @test zero(pm_Rational) isa pm_Rational

        @test one(pm_Rational) == one(ZERO) == 1 // 1 == ONE
        @test zero(pm_Rational) == zero(ONE) == 0 // 1 == ZERO
    end

    @testset "Show" begin
        @test sprint(show, pm_Rational(3, 5)) == "3/5"
    end
end
