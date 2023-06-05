using Oscar

@testset verbose=true "Polymake.OscarNumber" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]
    PolymakeTypes = [Polymake.Integer, Polymake.Rational]
    AllTypes = [IntTypes; PolymakeTypes; Base.Rational;
                # Float64; BigFloat
                ]

    @testset verbose=true "Constructors/Conversions" begin
        @test Polymake.OscarNumber <: Number

        # constructors
        for T in AllTypes
            @test Polymake.OscarNumber(T(2)) isa Polymake.OscarNumber
            @test Polymake.unwrap(Polymake.OscarNumber(T(2))) isa Polymake.Rational
        end

        Qx, x = QQ["x"]
        K, (a1, a2) = embedded_number_field([x^2 - 2, x^3 - 5], [(0, 2), (0, 2)])
        m = a1 + 3*a2^2 + 7
        @test Polymake.OscarNumber(m) isa Polymake.OscarNumber
        M = Polymake.OscarNumber(m)
        @test Polymake.unwrap(M) isa Hecke.EmbeddedNumFieldElem{NfAbsNSElem}
        @test Polymake.unwrap(M) == m
        @test M == Polymake.OscarNumber(m)

        a = Polymake.OscarNumber(4)

        # no copy conversion:
        @test convert(Polymake.OscarNumber, M) === M

        # conversions to different Number types
        for T in PolymakeTypes
            @test convert(T, a) isa T
            @test convert(Polymake.OscarNumber, convert(T, a)) isa Polymake.OscarNumber
        end

        @test convert(Float64, a) isa Float64
        @test float(a) == convert(BigFloat, a)

        @test zero(Polymake.OscarNumber) isa Polymake.OscarNumber
        @test zero(Polymake.OscarNumber) == 0
        @test zero(M) isa Polymake.OscarNumber
        @test zero(M) == 0

        @test one(Polymake.OscarNumber) isa Polymake.OscarNumber
        @test one(Polymake.OscarNumber) == 1
        @test one(M) isa Polymake.OscarNumber
        @test one(M) == 1

        # julia arrays
        @test Base.Vector{Any}([M, 1])[1] isa Polymake.OscarNumber
        @test [M, 1] isa Base.Vector{Polymake.OscarNumber}
        let vec = [M, 1]
            @test vec[1] + vec[2] == Polymake.OscarNumber(a1 + 3*a2^2 + 8)
        end
    end

    Qx, x = QQ["x"]
    K, (a1, a2) = embedded_number_field([x^2 - 2, x^3 - 5], [(0, 2), (0, 2)])
    m = a1 + 3*a2^2 + 7
    M = Polymake.OscarNumber(m)
    
    @testset verbose=true "Arithmetic" begin

        @testset verbose=true "Equality" begin
            a = Polymake.OscarNumber(6)
            for T in AllTypes
                b = T(6)
                @test a == b
                @test b == a
            end
        end
        
        @test -M isa Polymake.OscarNumber
        @test -M == Polymake.OscarNumber(-a1 - 3*a2^2 - 7)
        for T in AllTypes
            b = T(5)
            # check promotion
            @test M + b isa Polymake.OscarNumber
            @test b + M isa Polymake.OscarNumber
            @test M - b isa Polymake.OscarNumber
            @test b - M isa Polymake.OscarNumber
            @test M * b isa Polymake.OscarNumber
            @test b * M isa Polymake.OscarNumber

            # check arithmetic results
            @test M + b == b + M == Polymake.OscarNumber(a1 + 3*a2^2 + 12)
            @test M - b == Polymake.OscarNumber(a1 + 3*a2^2 + 2)
            @test b - M == Polymake.OscarNumber(-a1 - 3*a2^2 - 2)
            @test M * b == b * M == Polymake.OscarNumber(5*a1 + 15*a2^2 + 35)
            # @test M // b == Polymake.OscarNumber(a1//5 + 3//5*a2^2 + 7//5)
            # @test b // M == Polymake.OscarNumber(a1 + 3*a2^2 + 7)
        end

        A2 = Polymake.OscarNumber(a2)
        @test M + A2 isa Polymake.OscarNumber
        @test A2 + M isa Polymake.OscarNumber
        @test M - A2 isa Polymake.OscarNumber
        @test A2 - M isa Polymake.OscarNumber
        @test M * A2 isa Polymake.OscarNumber
        @test A2 * M isa Polymake.OscarNumber

        # check arithmetic results
        @test M + A2 == A2 + M == Polymake.OscarNumber(a1 + a2 + 3*a2^2 + 7)
        @test M - A2 == Polymake.OscarNumber(a1 - a2 + 3*a2^2 + 7)
        @test A2 - M == Polymake.OscarNumber(-a1 + a2 - 3*a2^2 - 7)
        @test M * A2 == A2 * M == Polymake.OscarNumber(a1*a2 + 15 + 7*a2)
        @test M // Polymake.OscarNumber(5) == Polymake.OscarNumber(a1//5 + 3//5*a2^2 + 7//5)
        @test Polymake.OscarNumber(5) // A2 == Polymake.OscarNumber(a2^2)
    end

    @testset verbose=true "Show" begin
        @test sprint(show, M) == string("common::OscarNumber\n(", sprint(show, m), ")")
    end
end
