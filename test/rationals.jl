@testset "pm_Rational" begin
    @testset "Constructors" begin
        @test PolymakeWrap.pm_Rational(Int32(2), Int32(2)) isa PolymakeWrap.pm_Rational
        @test PolymakeWrap.pm_Rational(Int64(2), Int64(5)) isa PolymakeWrap.pm_Rational
        @test PolymakeWrap.pm_Rational(2, 4) isa PolymakeWrap.pm_Rational
        @test PolymakeWrap.pm_Rational(big(2), big(4)) isa PolymakeWrap.pm_Rational
        @test PolymakeWrap.pm_Rational(2 // 3) isa PolymakeWrap.pm_Rational
        @test PolymakeWrap.pm_Rational(big(2) // big(3)) isa PolymakeWrap.pm_Rational
        @test PolymakeWrap.pm_Rational(2, big(3)) isa PolymakeWrap.pm_Rational
        @test PolymakeWrap.pm_Rational(big(3), 2) isa PolymakeWrap.pm_Rational
        @test PolymakeWrap.pm_Rational(0) isa PolymakeWrap.pm_Rational

        @test PolymakeWrap.pm_Rational <: Real
    end

    @testset "Equality" begin
        a = PolymakeWrap.pm_Rational(2, 6)
        for b in [Int32(2) // Int32(6), 2 // 6, big(2) // big(6)]
            @test a == b
            @test b == a
        end

        a = PolymakeWrap.pm_Rational(5, 1)
        for b in [Int32(5), 5, big(5), PolymakeWrap.pm_Integer(5)]
            @test a == b
            @test b == a
        end
    end

    @testset "zero / one" begin
        a = PolymakeWrap.pm_Rational(0)
        b = PolymakeWrap.pm_Rational(1)

        @test one(a) isa PolymakeWrap.pm_Rational
        @test zero(a) isa PolymakeWrap.pm_Rational
        @test one(PolymakeWrap.pm_Rational) isa PolymakeWrap.pm_Rational
        @test zero(PolymakeWrap.pm_Rational) isa PolymakeWrap.pm_Rational

        @test one(PolymakeWrap.pm_Rational) == one(a) == 1 // 1 == 1
        @test zero(PolymakeWrap.pm_Rational) == zero(a) == 0 // 1 == 0
    end

    @testset "Arithmetic" begin
        a = PolymakeWrap.pm_Rational(2, 1)
        @test -a == -2
        for b in [Int32(5), Int64(5), big(5),
                  PolymakeWrap.pm_Integer(5), PolymakeWrap.pm_Rational(5)]
            # check promotion
            @test a + b isa PolymakeWrap.pm_Rational
            @test b + a isa PolymakeWrap.pm_Rational
            @test a - b isa PolymakeWrap.pm_Rational
            @test b - a isa PolymakeWrap.pm_Rational
            @test a * b isa PolymakeWrap.pm_Rational
            @test b * a isa PolymakeWrap.pm_Rational

            # check arithmetic results
            @test a + b == b + a == 7
            @test a - b == -3
            @test b - a == 3
            @test a * b == b * a == 10
            @test a / b == 2 // 5
            @test b / a == 5 // 2
        end

        a = PolymakeWrap.pm_Rational(1, 14)
        for b in [Int32(5) // Int32(7), 5 // 7, big(5 // 7), PolymakeWrap.pm_Rational(5, 7)]
            # check promotion
            @test a + b isa PolymakeWrap.pm_Rational
            @test b + a isa PolymakeWrap.pm_Rational
            @test a - b isa PolymakeWrap.pm_Rational
            @test b - a isa PolymakeWrap.pm_Rational
            @test a * b isa PolymakeWrap.pm_Rational
            @test b * a isa PolymakeWrap.pm_Rational

            # check arithmetic results
            @test a + b == b + a == 11 // 14
            @test a - b == -9 // 14
            @test b - a == 9 // 14
            @test a * b == b * a == 5 // 98
        end
    end

    @testset "Show" begin
        @test sprint(show, PolymakeWrap.pm_Rational(3, 5)) == "3/5"
    end


end
