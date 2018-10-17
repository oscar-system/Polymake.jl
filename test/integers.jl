@testset "pm_Integer" begin
    @testset "Constructors" begin
        @test PolymakeWrap.pm_Integer(Int32(2)) isa PolymakeWrap.pm_Integer
        @test PolymakeWrap.pm_Integer(Int64(2)) isa PolymakeWrap.pm_Integer
        @test PolymakeWrap.pm_Integer(2) isa PolymakeWrap.pm_Integer
        @test PolymakeWrap.pm_Integer(big(2)) isa PolymakeWrap.pm_Integer

        @test PolymakeWrap.pm_Integer <: Integer
    end

    @testset "Equality" begin
        a = PolymakeWrap.pm_Integer(2)
        for b in [Int32(2), Int64(2), big(2), PolymakeWrap.pm_Integer(2)]
            @test a == b
            @test b == a
        end
    end

    @testset "Arithmetic" begin
        a = PolymakeWrap.pm_Integer(2)
        for b in [Int32(5), Int64(5), big(5), PolymakeWrap.pm_Integer(5)]
            # check promotion
            @test a + b isa PolymakeWrap.pm_Integer
            @test b + a isa PolymakeWrap.pm_Integer
            @test a - b isa PolymakeWrap.pm_Integer
            @test b - a isa PolymakeWrap.pm_Integer
            @test a * b isa PolymakeWrap.pm_Integer
            @test b * a isa PolymakeWrap.pm_Integer

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


end
