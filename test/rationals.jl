@testset "Polymake.Rational" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]

    @testset "Constructors/Conversions" begin
        @test Polymake.Rational <: Real

        # constructors
        for T in [IntTypes; Polymake.Integer]
            @test Polymake.Rational(T(2), T(2)) isa Polymake.Rational
            @test Polymake.Rational(T(1)) isa Polymake.Rational
        end

        for T in IntTypes
            @test Polymake.Rational(T(2)//T(3)) isa Polymake.Rational
        end

        for T in [Float64, BigFloat]
            @test Polymake.Rational(T(2)) isa Polymake.Rational
        end

        a = Polymake.Rational(4,3)

        # no copy conversion:
        @test convert(Polymake.Rational, a) === a

        # conversions to Base.Rational types
        for T in IntTypes
            RT = Base.Rational{T}
            @test RT(a) isa RT
            @test convert(Polymake.Rational, RT(a)) isa Polymake.Rational
            @test convert(Polymake.Rational, RT(a)) isa Polymake.RationalAllocated
        end
        @test Base.Rational(a) isa Base.Rational{BigInt}
        @test big(a) isa Base.Rational{BigInt}

        # conversion to other Number types
        @test convert(Float64, a) isa Float64
        @test Float64(a) isa Float64
        @test float(a) == convert(BigFloat, a)

        # julia arrays
        @test Base.Vector{Any}([a,1])[1] isa Polymake.RationalAllocated
        @test [a,1] isa Base.Vector{Polymake.Rational}
        @test [a,a] isa Base.Vector{Polymake.RationalAllocated}
    end

    @testset "Arithmetic" begin

        @testset "Equality" begin
            a = Polymake.Rational(2, 6)
            for T in IntTypes
                b = Base.Rational(T(2), T(6))
                @test a == b
                @test b == a
            end

            a = Polymake.Rational(5, 1)
            for T in [IntTypes; Polymake.Integer]
                b = T(5)
                @test a == b
                @test b == a
            end
            
            @test a != 2
            @test 2!=a
        end

        @testset "Polymake.Rational division" begin
            a = Polymake.Rational(4,5)
            for T in [IntTypes; Polymake.Integer]
                @test Polymake.Integer(4)//T(5) isa Polymake.Rational
                @test T(5)//Polymake.Integer(5) isa Polymake.Rational
                @test Polymake.Integer(4)//T(5) == T(4)//Polymake.Integer(5) == a

                @test a//T(2) isa Polymake.Rational
                @test a//T(2) == 2//5

                @test T(2)//a isa Polymake.Rational
                @test T(2)//a == 5//2
            end
            @test a//a == Polymake.Rational(1)
        end

        a = Polymake.Rational(2, 1)
        A = Polymake.Integer(2)
        @test -a == -2
        for T in [IntTypes; Polymake.Integer]
            b = T(5)
            # check promotion
            @test a + b isa Polymake.Rational
            @test b + a isa Polymake.Rational
            @test a - b isa Polymake.Rational
            @test b - a isa Polymake.Rational
            @test a * b isa Polymake.Rational
            @test b * a isa Polymake.Rational

            # check arithmetic results
            @test a + b == b + a == 7
            @test a - b == -3
            @test b - a == 3
            @test a * b == b * a == 10
            @test a // b == 2 // 5
            @test b // a == 5 // 2
        end

        a = Polymake.Rational(1, 14)
        for T in [IntTypes; Polymake.Integer]
            b = T(5)//T(7)
            # check promotion
            @test a + b isa Polymake.Rational
            @test b + a isa Polymake.Rational
            @test a - b isa Polymake.Rational
            @test b - a isa Polymake.Rational
            @test a * b isa Polymake.Rational
            @test b * a isa Polymake.Rational

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
        ZERO = Polymake.Rational(0)
        ONE = Polymake.Rational(1)

        @test one(ZERO) isa Polymake.Rational
        @test zero(ZERO) isa Polymake.Rational
        @test one(Polymake.Rational) isa Polymake.Rational
        @test zero(Polymake.Rational) isa Polymake.Rational

        @test one(Polymake.Rational) == one(ZERO) == 1 // 1 == ONE
        @test zero(Polymake.Rational) == zero(ONE) == 0 // 1 == ZERO
    end

    @testset "Show" begin
        @test sprint(show, Polymake.Rational(3, 5)) == "3/5"
    end
end
