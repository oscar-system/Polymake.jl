@testset "pm_TropicalNumber" begin
    NumberTypes = [Int32, Int64, UInt64, BigInt, Float32, Float64, BigFloat, pm_Integer, pm_Rational]
    AdditionTypes = [pm_Min, pm_Max]

    @testset "Constructors/Conversions" begin
        @test pm_Rational <: Number

        for A in AdditionTypes
            # constructors
            for T in NumberTypes
                @test pm_TropicalNumber{A}(T(1)) isa pm_TropicalNumber
                @test pm_TropicalNumber{A}(T(1)) isa pm_TropicalNumber{A}
            end

            a = pm_TropicalNumber{A}(5)

            # no copy conversion:
            @test convert(pm_TropicalNumber{A}, a) === a
            #
            # # conversions to Rational types
            # for T in IntTypes
            #     RT = Rational{T}
            #     @test RT(a) isa RT
            #     @test convert(pm_Rational, RT(a)) isa pm_Rational
            #     @test convert(pm_Rational, RT(a)) isa Polymake.pm_RationalAllocated
            # end
            # @test Rational(a) isa Rational{BigInt}
            # @test big(a) isa Rational{BigInt}
            #
            # # conversion to other Number types
            # @test convert(Float64, a) isa Float64
            # @test Float64(a) isa Float64
            # @test float(a) == convert(BigFloat, a)
            #
            # julia arrays
            @test Array{Any,1}([a,1])[1] isa Polymake.pm_TropicalNumberAllocated
            # @test [a,1] isa Vector{pm_TropicalNumber{A,pm_Rational}}
            @test [a,a] isa Vector{Polymake.pm_TropicalNumberAllocated{A,pm_Rational}}
        end
    end

    @testset "Arithmetic" begin

        for A in AdditionTypes
            @testset "(In-)Equality $A" begin
                a = pm_TropicalNumber{A}(pm_Rational(5))
                for T in NumberTypes
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
                a //= b
                @test a == pm_TropicalNumber{A}(-12)
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
            @test_throws ArgumentError a + b
            @test_throws ArgumentError b + a
            @test_throws ArgumentError a * b
            @test_throws ArgumentError b * a
            @test_throws ArgumentError a // b
            @test_throws ArgumentError b // a
            @test_throws ArgumentError a < b
            @test_throws ArgumentError b < a
            @test_throws ArgumentError a > b
            @test_throws ArgumentError b > a
        end
    end

    @testset "zero / one" begin
        ZEROmin = pm_TropicalNumber{pm_Min}()
        ONEmin = pm_TropicalNumber{pm_Min}(0)
        DZEROmin = pm_TropicalNumber{pm_Max}()
        ZEROmax = pm_TropicalNumber{pm_Max}()
        ONEmax = pm_TropicalNumber{pm_Max}(0)
        DZEROmax = pm_TropicalNumber{pm_Min}()

        @test one(ZEROmin) isa pm_TropicalNumber{pm_Min}
        @test zero(ZEROmin) isa pm_TropicalNumber{pm_Min}
        @test dual_zero(ZEROmin) isa pm_TropicalNumber{pm_Max}
        @test one(pm_TropicalNumber{pm_Min}) isa pm_TropicalNumber{pm_Min}
        @test zero(pm_TropicalNumber{pm_Min}) isa pm_TropicalNumber{pm_Min}
        @test dual_zero(pm_TropicalNumber{pm_Min}) isa pm_TropicalNumber{pm_Max}
        @test one(ZEROmax) isa pm_TropicalNumber{pm_Max}
        @test zero(ZEROmax) isa pm_TropicalNumber{pm_Max}
        @test dual_zero(ZEROmax) isa pm_TropicalNumber{pm_Min}
        @test one(pm_TropicalNumber{pm_Max}) isa pm_TropicalNumber{pm_Max}
        @test zero(pm_TropicalNumber{pm_Max}) isa pm_TropicalNumber{pm_Max}
        @test dual_zero(pm_TropicalNumber{pm_Max}) isa pm_TropicalNumber{pm_Min}

        @test zero(pm_TropicalNumber{pm_Min}) == zero(ONEmin) == ZEROmin == dual_zero(pm_TropicalNumber{pm_Max})
        @test one(pm_TropicalNumber{pm_Min}) == one(ZEROmin) == ONEmin
        @test zero(pm_TropicalNumber{pm_Max}) == zero(ONEmax) == ZEROmax == dual_zero(pm_TropicalNumber{pm_Min})
        @test one(pm_TropicalNumber{pm_Max}) == one(ZEROmax) == ONEmax

        @test orientation(pm_TropicalNumber{pm_Min}) == orientation(ZEROmin) == -orientation(pm_TropicalNumber{pm_Max}) == - orientation(ZEROmax) == 1
    end
end
