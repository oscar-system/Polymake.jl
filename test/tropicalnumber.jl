@testset "pm_TropicalNumber" begin
    NumberTypes = [Int32, Int64, UInt64, BigInt, Float32, Float64, BigFloat, pm_Integer, pm_Rational]
    AdditionTypes = [pm_Min, pm_Max]

    @testset "Constructors/Conversions" begin
        for T in [NumberTypes; pm_TropicalNumber{pm_Min}; pm_TropicalNumber{pm_Max}]
            @test_throws ArgumentError pm_TropicalNumber(T(2))
        end

        for A in AdditionTypes
            # constructors
            for T in [NumberTypes; pm_TropicalNumber{pm_Min}; pm_TropicalNumber{pm_Max}]
                @test pm_TropicalNumber{A}(T(1)) isa pm_TropicalNumber
                @test pm_TropicalNumber{A}(T(1)) isa pm_TropicalNumber{A}
            end

            a = pm_TropicalNumber{A}(5)

            # no copy conversion:
            @test convert(pm_TropicalNumber{A}, a) === a

            for R in [Rational{Int}, pm_Rational]
              r = R(1//3)
              @test convert(pm_TropicalNumber{pm_Max}, r) isa pm_TropicalNumber
              tr = convert(pm_TropicalNumber{pm_Max}, r)
              @test convert(R, tr) isa R
              @test convert(R, tr) == r
            end

            # julia arrays
            @test Array{Any,1}([a,1])[1] isa Polymake.pm_TropicalNumberAllocated
            @test [a,a] isa Vector{Polymake.pm_TropicalNumberAllocated{A,pm_Rational}}
        end
    end

    @testset "Arithmetic" begin

        for A in AdditionTypes
            @testset "(In-)Equality $A" begin
                a = pm_TropicalNumber{A}(pm_Rational(5))
                for T in [NumberTypes; pm_TropicalNumber{pm_Min}; pm_TropicalNumber{pm_Max}]
                    b = pm_TropicalNumber{A}(T(5))
                    @test a == b
                    @test b == a
                end
                b = pm_TropicalNumber{A}(17)
                @test a == a
                @test a <= a
                @test a >= a
                @test a != b
                @test a <= b
                @test a < b
                @test b >= a
                @test b > a
            end

            @testset "Multiplication $A" begin
                a = pm_TropicalNumber{A}(5)
                b = pm_TropicalNumber{A}(17)
                @test a * b isa pm_TropicalNumber{A}
                @test a * b == b * a == pm_TropicalNumber{A}(22)
                a *= b
                @test a == pm_TropicalNumber{A}(22)
            end

            @testset "Division $A" begin
                a = pm_TropicalNumber{A}(5)
                b = pm_TropicalNumber{A}(17)
                @test a // b isa pm_TropicalNumber{A}
                @test a // b == pm_TropicalNumber{A}(-12)
                @test b // a == pm_TropicalNumber{A}(12)
                @test a / b isa pm_TropicalNumber{A}
                @test a / b == pm_TropicalNumber{A}(-12)
                @test b / a == pm_TropicalNumber{A}(12)
                a //= b
                @test a == pm_TropicalNumber{A}(-12)
                a /= b
                @test a == pm_TropicalNumber{A}(-29)
            end
        end

        @testset "Addition" begin
            a = pm_TropicalNumber{pm_Min}(5)
            b = pm_TropicalNumber{pm_Min}(17)
            c = pm_TropicalNumber{pm_Max}(5)
            d = pm_TropicalNumber{pm_Max}(17)
            @test a + b isa pm_TropicalNumber{pm_Min}
            @test a + b == b + a == a
            @test c + d isa pm_TropicalNumber{pm_Max}
            @test c + d == d + c == d
            a += b
            @test a == pm_TropicalNumber{pm_Min}(5)
            b += a
            @test b == a
            d += c
            @test d == pm_TropicalNumber{pm_Max}(17)
            c += d
            @test c == d
        end

        @testset "Catching mismatching parameters" begin
            a = pm_TropicalNumber{pm_Min}(5)
            b = pm_TropicalNumber{pm_Max}(17)
            @test_throws DomainError a + b
            @test_throws DomainError b + a
            @test_throws DomainError a * b
            @test_throws DomainError b * a
            @test_throws DomainError a // b
            @test_throws DomainError b // a
            @test_throws DomainError a / b
            @test_throws DomainError b / a
            @test_throws DomainError a < b
            @test_throws DomainError b < a
            @test_throws DomainError a > b
            @test_throws DomainError b > a
        end
    end

    @testset "zero / one" begin
        ZEROmin = pm_TropicalNumber{pm_Min}()
        ONEmin = pm_TropicalNumber{pm_Min}(0)
        DZEROmin = pm_TropicalNumber{pm_Min}(-Inf)
        ZEROmax = pm_TropicalNumber{pm_Max}()
        ONEmax = pm_TropicalNumber{pm_Max}(0)
        DZEROmax = pm_TropicalNumber{pm_Max}(Inf)

        @test one(ZEROmin) isa pm_TropicalNumber{pm_Min}
        @test zero(ZEROmin) isa pm_TropicalNumber{pm_Min}
        @test dual_zero(ZEROmin) isa pm_TropicalNumber{pm_Min}
        @test one(pm_TropicalNumber{pm_Min}) isa pm_TropicalNumber{pm_Min}
        @test zero(pm_TropicalNumber{pm_Min}) isa pm_TropicalNumber{pm_Min}
        @test dual_zero(pm_TropicalNumber{pm_Min}) isa pm_TropicalNumber{pm_Min}
        @test one(ZEROmax) isa pm_TropicalNumber{pm_Max}
        @test zero(ZEROmax) isa pm_TropicalNumber{pm_Max}
        @test dual_zero(ZEROmax) isa pm_TropicalNumber{pm_Max}
        @test one(pm_TropicalNumber{pm_Max}) isa pm_TropicalNumber{pm_Max}
        @test zero(pm_TropicalNumber{pm_Max}) isa pm_TropicalNumber{pm_Max}
        @test dual_zero(pm_TropicalNumber{pm_Max}) isa pm_TropicalNumber{pm_Max}

        @test zero(pm_TropicalNumber{pm_Min}) == zero(ONEmin) == ZEROmin
        @test dual_zero(pm_TropicalNumber{pm_Min}) == dual_zero(ONEmin) == pm_TropicalNumber{pm_Min}(-Inf)
        @test one(pm_TropicalNumber{pm_Min}) == one(ZEROmin) == ONEmin
        @test zero(pm_TropicalNumber{pm_Max}) == zero(ONEmax) == ZEROmax
        @test dual_zero(pm_TropicalNumber{pm_Max}) == dual_zero(ONEmax) == pm_TropicalNumber{pm_Max}(Inf)
        @test one(pm_TropicalNumber{pm_Max}) == one(ZEROmax) == ONEmax

        @test orientation(pm_TropicalNumber{pm_Min}) == orientation(ZEROmin) == -orientation(pm_TropicalNumber{pm_Max}) == - orientation(ZEROmax) == 1
    end

    @testset "Promotion (equality)" begin
        for A in AdditionTypes
            for T in NumberTypes
                a = pm_TropicalNumber{A}(5)
                @test a == T(5)
                @test T(5) == a
            end
        end
    end
end
