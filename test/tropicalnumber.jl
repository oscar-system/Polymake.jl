@testset verbose=true "Polymake.TropicalNumber" begin
    NumberTypes = [Int32, Int64, UInt64, BigInt, Float32, Float64, BigFloat, Polymake.Integer, Polymake.Rational]
    AdditionTypes = [Polymake.Min, Polymake.Max]

    @testset verbose=true "Constructors/Conversions" begin
        for T in [NumberTypes; Polymake.TropicalNumber{Polymake.Min}; Polymake.TropicalNumber{Polymake.Max}]
            @test_throws ArgumentError Polymake.TropicalNumber(T(2))
        end

        for A in AdditionTypes
            # constructors
            for T in [NumberTypes; Polymake.TropicalNumber{Polymake.Min}; Polymake.TropicalNumber{Polymake.Max}]
                @test Polymake.TropicalNumber{A}(T(1)) isa Polymake.TropicalNumber
                @test Polymake.TropicalNumber{A}(T(1)) isa Polymake.TropicalNumber{A}
            end

            a = Polymake.TropicalNumber{A}(5)

            # no copy conversion:
            @test convert(Polymake.TropicalNumber{A}, a) === a

            for R in [Base.Rational{Polymake.Int}, Polymake.Rational]
              r = R(1//3)
              @test convert(Polymake.TropicalNumber{Polymake.Max}, r) isa Polymake.TropicalNumber
              tr = convert(Polymake.TropicalNumber{Polymake.Max}, r)
              @test convert(R, tr) isa R
              @test convert(R, tr) == r
            end

            # julia arrays
            @test Vector{Any}([a,1])[1] isa Polymake.TropicalNumberAllocated
            @test [a,a] isa Vector{Polymake.TropicalNumberAllocated{A,Polymake.Rational}}
        end
    end

    @testset verbose=true "Arithmetic" begin

        for A in AdditionTypes
            @testset verbose=true "(In-)Equality $A" begin
                a = Polymake.TropicalNumber{A}(Polymake.Rational(5))
                for T in [NumberTypes; Polymake.TropicalNumber{Polymake.Min}; Polymake.TropicalNumber{Polymake.Max}]
                    b = Polymake.TropicalNumber{A}(T(5))
                    @test a == b
                    @test b == a
                end
                b = Polymake.TropicalNumber{A}(17)
                @test a == a
                @test a <= a
                @test a >= a
                @test a != b
                @test a <= b
                @test a < b
                @test b >= a
                @test b > a
            end

            @testset verbose=true "Multiplication $A" begin
                a = Polymake.TropicalNumber{A}(5)
                b = Polymake.TropicalNumber{A}(17)
                @test a * b isa Polymake.TropicalNumber{A}
                @test a * b == b * a == Polymake.TropicalNumber{A}(22)
                a *= b
                @test a == Polymake.TropicalNumber{A}(22)
            end

            @testset verbose=true "Division $A" begin
                a = Polymake.TropicalNumber{A}(5)
                b = Polymake.TropicalNumber{A}(17)
                @test a // b isa Polymake.TropicalNumber{A}
                @test a // b == Polymake.TropicalNumber{A}(-12)
                @test b // a == Polymake.TropicalNumber{A}(12)
                @test a / b isa Polymake.TropicalNumber{A}
                @test a / b == Polymake.TropicalNumber{A}(-12)
                @test b / a == Polymake.TropicalNumber{A}(12)
                a //= b
                @test a == Polymake.TropicalNumber{A}(-12)
                a /= b
                @test a == Polymake.TropicalNumber{A}(-29)
            end
        end

        @testset verbose=true "Addition" begin
            a = Polymake.TropicalNumber{Polymake.Min}(5)
            b = Polymake.TropicalNumber{Polymake.Min}(17)
            c = Polymake.TropicalNumber{Polymake.Max}(5)
            d = Polymake.TropicalNumber{Polymake.Max}(17)
            @test a + b isa Polymake.TropicalNumber{Polymake.Min}
            @test a + b == b + a == a
            @test c + d isa Polymake.TropicalNumber{Polymake.Max}
            @test c + d == d + c == d
            a += b
            @test a == Polymake.TropicalNumber{Polymake.Min}(5)
            b += a
            @test b == a
            d += c
            @test d == Polymake.TropicalNumber{Polymake.Max}(17)
            c += d
            @test c == d
        end

        @testset verbose=true "Catching mismatching parameters" begin
            a = Polymake.TropicalNumber{Polymake.Min}(5)
            b = Polymake.TropicalNumber{Polymake.Max}(17)
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

    @testset verbose=true "zero / one" begin
        ZEROmin = Polymake.TropicalNumber{Polymake.Min}()
        ONEmin = Polymake.TropicalNumber{Polymake.Min}(0)
        DZEROmin = Polymake.TropicalNumber{Polymake.Min}(-Inf)
        ZEROmax = Polymake.TropicalNumber{Polymake.Max}()
        ONEmax = Polymake.TropicalNumber{Polymake.Max}(0)
        DZEROmax = Polymake.TropicalNumber{Polymake.Max}(Inf)

        @test one(ZEROmin) isa Polymake.TropicalNumber{Polymake.Min}
        @test zero(ZEROmin) isa Polymake.TropicalNumber{Polymake.Min}
        @test Polymake.dual_zero(ZEROmin) isa Polymake.TropicalNumber{Polymake.Min}
        @test one(Polymake.TropicalNumber{Polymake.Min}) isa Polymake.TropicalNumber{Polymake.Min}
        @test zero(Polymake.TropicalNumber{Polymake.Min}) isa Polymake.TropicalNumber{Polymake.Min}
        @test Polymake.dual_zero(Polymake.TropicalNumber{Polymake.Min}) isa Polymake.TropicalNumber{Polymake.Min}
        @test one(ZEROmax) isa Polymake.TropicalNumber{Polymake.Max}
        @test zero(ZEROmax) isa Polymake.TropicalNumber{Polymake.Max}
        @test Polymake.dual_zero(ZEROmax) isa Polymake.TropicalNumber{Polymake.Max}
        @test one(Polymake.TropicalNumber{Polymake.Max}) isa Polymake.TropicalNumber{Polymake.Max}
        @test zero(Polymake.TropicalNumber{Polymake.Max}) isa Polymake.TropicalNumber{Polymake.Max}
        @test Polymake.dual_zero(Polymake.TropicalNumber{Polymake.Max}) isa Polymake.TropicalNumber{Polymake.Max}

        @test zero(Polymake.TropicalNumber{Polymake.Min}) == zero(ONEmin) == ZEROmin
        @test Polymake.dual_zero(Polymake.TropicalNumber{Polymake.Min}) == Polymake.dual_zero(ONEmin) == Polymake.TropicalNumber{Polymake.Min}(-Inf)
        @test one(Polymake.TropicalNumber{Polymake.Min}) == one(ZEROmin) == ONEmin
        @test zero(Polymake.TropicalNumber{Polymake.Max}) == zero(ONEmax) == ZEROmax
        @test Polymake.dual_zero(Polymake.TropicalNumber{Polymake.Max}) == Polymake.dual_zero(ONEmax) == Polymake.TropicalNumber{Polymake.Max}(Inf)
        @test one(Polymake.TropicalNumber{Polymake.Max}) == one(ZEROmax) == ONEmax

        @test Polymake.orientation(Polymake.TropicalNumber{Polymake.Min}) == Polymake.orientation(ZEROmin) == -Polymake.orientation(Polymake.TropicalNumber{Polymake.Max}) == - Polymake.orientation(ZEROmax) == 1
    end

    @testset verbose=true "Promotion (equality)" begin
        for A in AdditionTypes
            for T in NumberTypes
                a = Polymake.TropicalNumber{A}(5)
                @test a == T(5)
                @test T(5) == a
            end
        end
    end

    @testset "Containers" begin
        for VType in [Polymake.Vector, Polymake.Array]
            for A in AdditionTypes
                v = VType{Polymake.TropicalNumber{A, Polymake.Rational}}(5)
                @test v isa VType{Polymake.TropicalNumber{A, Polymake.Rational}}
                # If this at some point might work, we want to get notified:
                @test_broken v isa VType{Polymake.TropicalNumber{A}}
                @test length(v) == 5
                @test v+v == v
                for e in v
                    @test iszero(e)
                end
            end
        end
        for MType in [Polymake.Matrix, Polymake.SparseMatrix]
            for A in AdditionTypes
                v = MType{Polymake.TropicalNumber{A, Polymake.Rational}}(5,5)
                @test v isa MType{Polymake.TropicalNumber{A, Polymake.Rational}}
                # If this at some point might work, we want to get notified:
                @test_broken v isa MType{Polymake.TropicalNumber{A}}
                @test size(v) == (5,5)
                @test v+v == v
                for e in v
                    @test iszero(e)
                end
            end
        end
    end
end
