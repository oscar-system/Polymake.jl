@testset "pm_Rational" begin
    @testset "Constructors" begin
        @test pm_Rational(Int32(2), Int32(2)) isa pm_Rational
        @test pm_Rational(Int64(2), Int64(5)) isa pm_Rational
        @test pm_Rational(2, 4) isa pm_Rational
        @test pm_Rational(big(2), big(4)) isa pm_Rational
        @test pm_Rational(2 // 3) isa pm_Rational
        @test pm_Rational(big(2) // big(3)) isa pm_Rational
        @test pm_Rational(2, big(3)) isa pm_Rational
        @test pm_Rational(big(3), 2) isa pm_Rational
        @test pm_Rational(0) isa pm_Rational

        @test pm_Rational <: Real
    end

    @testset "Equality" begin
        a = pm_Rational(2, 6)
        for b in [Int32(2) // Int32(6), 2 // 6, big(2) // big(6)]
            @test a == b
            @test b == a
        end

        a = pm_Rational(5, 1)
        for b in [Int32(5), 5, big(5), pm_Integer(5)]
            @test a == b
            @test b == a
        end
    end

    @testset "zero / one" begin
        a = pm_Rational(0)
        b = pm_Rational(1)

        @test one(a) isa pm_Rational
        @test zero(a) isa pm_Rational
        @test one(pm_Rational) isa pm_Rational
        @test zero(pm_Rational) isa pm_Rational

        @test one(pm_Rational) == one(a) == 1 // 1 == 1
        @test zero(pm_Rational) == zero(a) == 0 // 1 == 0
    end

    @testset "Arithmetic" begin
        a = pm_Rational(2, 1)
        @test -a == -2
        for b in [Int32(5), Int64(5), big(5), pm_Integer(5), pm_Rational(5)]
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
            @test a / b == 2 // 5
            @test b / a == 5 // 2
        end

        a = pm_Rational(1, 14)
        for b in [Int32(5) // Int32(7), 5 // 7, big(5 // 7), pm_Rational(5, 7)]
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
        end
    end

    @testset "Show" begin
        @test sprint(show, pm_Rational(3, 5)) == "3/5"
    end


end
