@testset "pm_Integer" begin
    @testset "Constructors" begin
        @test pm_Integer(Int32(2)) isa pm_Integer
        @test pm_Integer(Int64(2)) isa pm_Integer
        @test pm_Integer(2) isa pm_Integer
        @test pm_Integer(big(2)) isa pm_Integer

        @test pm_Integer <: Integer
    end

    @testset "Equality" begin
        a = pm_Integer(2)
        for b in [Int32(2), Int64(2), big(2), pm_Integer(2)]
            @test a == b
            @test b == a
        end
    end

    @testset "zero / one" begin
        a = pm_Integer(0)
        b = pm_Integer(1)

        @test one(a) isa pm_Integer
        @test zero(a) isa pm_Integer
        @test one(pm_Integer) isa pm_Integer
        @test zero(pm_Integer) isa pm_Integer

        @test one(pm_Integer) == one(a) == 1
        @test zero(pm_Integer) == zero(a) == 0
    end

    @testset "Arithmetic" begin
        a = pm_Integer(2)
        @test -a == -2
        for b in [Int32(5), Int64(5), big(5), pm_Integer(5)]
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

    @testset "Promotions/Conversions" begin
        a = pm_Integer(1)
        @test convert(Integer,a) === a
        @test typeof(Array{Any,1}([a,1])[1]) <: pm_Integer
    end


end
