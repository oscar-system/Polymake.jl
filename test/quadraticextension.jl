@testset verbose=true "Polymake.QuadraticExtension{Polymake.Rational}" begin
    FloatTypes = [Float32, Float64, BigFloat]
    MoreNumberTypes = [Int32, Int64, UInt64, BigInt, Polymake.Integer, Polymake.Rational]

    @testset verbose=true "Constructors/Conversions" begin
        
        # constructors
        for T in  [FloatTypes; MoreNumberTypes]
            @test Polymake.QuadraticExtension{Polymake.Rational}(T(1), T(2), T(3)) isa Polymake.QuadraticExtension
            @test Polymake.QuadraticExtension{Polymake.Rational}(T(1), T(2), T(3)) isa Polymake.QuadraticExtension{Polymake.Rational}
            @test Polymake.QuadraticExtension(T(1), T(2), T(3)) isa Polymake.QuadraticExtension{Polymake.Rational}
            
            @test Polymake.QuadraticExtension{Polymake.Rational}(T(1)) isa Polymake.QuadraticExtension{Polymake.Rational}
            @test Polymake.QuadraticExtension(T(1)) isa Polymake.QuadraticExtension{Polymake.Rational}
        end
        
        # example for different `Number` types
        @test Polymake.QuadraticExtension{Polymake.Rational}(Int32(1), Float64(2), Polymake.Integer(3)) isa Polymake.QuadraticExtension{Polymake.Rational}

        a = Polymake.QuadraticExtension{Polymake.Rational}(5)
        
        # no copy conversion:
        @test convert(Polymake.QuadraticExtension{Polymake.Rational}, a) === a
        
        for T in [FloatTypes; MoreNumberTypes]
            t = T(7)
            @test convert(Polymake.QuadraticExtension{Polymake.Rational}, t) isa Polymake.QuadraticExtension{Polymake.Rational}
            tt = convert(Polymake.QuadraticExtension{Polymake.Rational}, t)
            @test convert(T, tt) isa T
            @test convert(T, tt) == t
        end
        
        # julia arrays
        @test Vector{Any}([a,1])[1] isa Polymake.QuadraticExtension{Polymake.Rational}
        @test [a,a] isa Vector{Polymake.QuadraticExtensionAllocated{Polymake.Rational}}
    end

    @testset verbose=true "Arithmetic" begin
    
        @testset verbose=true "(In-)Equality" begin
            a = Polymake.QuadraticExtension{Polymake.Rational}(5)
            for T in [FloatTypes; MoreNumberTypes], b in [Polymake.QuadraticExtension{Polymake.Rational}(T(5)), Polymake.QuadraticExtension{Polymake.Rational}(T(5), T(0), T(0)), Polymake.QuadraticExtension{Polymake.Rational}(T(5), T(1), T(0)), Polymake.QuadraticExtension{Polymake.Rational}(T(5), T(0), T(2))]
                @test a == b
                @test b == a
            end
            @test a == a
            @test a <= a
            @test a >= a
            let b = Polymake.QuadraticExtension{Polymake.Rational}(4, 1, 3)
                @test a != b
                @test a <= b
                @test a < b
                @test b >= a
                @test b > a
            end
        end
        
        @testset verbose=true "Addition" begin
            a = Polymake.QuadraticExtension{Polymake.Rational}(5)
            b = Polymake.QuadraticExtension{Polymake.Rational}(17, 1, 5)
            @test a + b isa Polymake.QuadraticExtension{Polymake.Rational}
            @test a + b == b + a == Polymake.QuadraticExtension{Polymake.Rational}(22, 1, 5)
            a += b
            @test a == Polymake.QuadraticExtension{Polymake.Rational}(22, 1, 5)
            b += a
            @test b == Polymake.QuadraticExtension{Polymake.Rational}(39, 2, 5)
        end
        
        @testset verbose=true "Subtraction" begin
            a = Polymake.QuadraticExtension{Polymake.Rational}(5)
            b = Polymake.QuadraticExtension{Polymake.Rational}(17, 1, 5)
            @test a - b isa Polymake.QuadraticExtension{Polymake.Rational}
            @test a - b == -(b - a) == Polymake.QuadraticExtension{Polymake.Rational}(-12, -1, 5)
            a -= b
            @test a == Polymake.QuadraticExtension{Polymake.Rational}(-12, -1, 5)
            b -= a
            @test b == Polymake.QuadraticExtension{Polymake.Rational}(29, 2, 5)
        end
        
        @testset verbose=true "Multiplication" begin
            a = Polymake.QuadraticExtension{Polymake.Rational}(5)
            b = Polymake.QuadraticExtension{Polymake.Rational}(17, 1, 5)
            @test a * b isa Polymake.QuadraticExtension{Polymake.Rational}
            @test a * b == b * a == Polymake.QuadraticExtension{Polymake.Rational}(85, 5, 5)
            a *= b
            @test a == Polymake.QuadraticExtension{Polymake.Rational}(85, 5, 5)
        end
        
        @testset verbose=true "Division" begin
            a = Polymake.QuadraticExtension{Polymake.Rational}(5)
            b = Polymake.QuadraticExtension{Polymake.Rational}(17, 1, 5)
            @test a // b isa Polymake.QuadraticExtension{Polymake.Rational}
            @test a // b == Polymake.QuadraticExtension{Polymake.Rational}(85//284, -5//284, 5)
            @test b // a == Polymake.QuadraticExtension{Polymake.Rational}(17//5, 1//5, 5)
            @test a / b isa Polymake.QuadraticExtension{Polymake.Rational}
            @test a / b == Polymake.QuadraticExtension{Polymake.Rational}(85//284, -5//284, 5)
            @test b / a == Polymake.QuadraticExtension{Polymake.Rational}(17//5, 1//5, 5)
            a //= b
            @test a == Polymake.QuadraticExtension{Polymake.Rational}(85//284, -5//284, 5)
            a /= b
            @test a == Polymake.QuadraticExtension{Polymake.Rational}(735//40328, -85//40328, 5)
        end
        
    end
    
    @testset verbose=true "zero / one" begin
        ZERO = Polymake.QuadraticExtension{Polymake.Rational}(0)
        ONE = Polymake.QuadraticExtension{Polymake.Rational}(1)
    
        @test one(ZERO) isa Polymake.QuadraticExtension{Polymake.Rational}
        @test zero(ZERO) isa Polymake.QuadraticExtension{Polymake.Rational}
        @test one(Polymake.QuadraticExtension{Polymake.Rational}) isa Polymake.QuadraticExtension{Polymake.Rational}
        @test zero(Polymake.QuadraticExtension{Polymake.Rational}) isa Polymake.QuadraticExtension{Polymake.Rational}
    
        @test zero(Polymake.QuadraticExtension{Polymake.Rational}) == zero(ONE) == ZERO
        @test one(Polymake.QuadraticExtension{Polymake.Rational}) == one(ZERO) == ONE
    end
    
    @testset verbose=true "Promotion" begin
        for T in MoreNumberTypes
            a = Polymake.QuadraticExtension{Polymake.Rational}(5, 1, 3)
            b = T(17)
            c = Polymake.QuadraticExtension{Polymake.Rational}(17)
            @test b == c
            @test c == b
            @test a != b
            @test a <= b
            @test a < b
            @test b >= a
            @test b > a
            @test a + b isa Polymake.QuadraticExtension{Polymake.Rational}
            @test b + a isa Polymake.QuadraticExtension{Polymake.Rational}
            @test a + b == b + a == Polymake.QuadraticExtension{Polymake.Rational}(22, 1, 3)
            @test a - b isa Polymake.QuadraticExtension{Polymake.Rational}
            @test b - a isa Polymake.QuadraticExtension{Polymake.Rational}
            @test a - b == -(b - a) == Polymake.QuadraticExtension{Polymake.Rational}(-12, 1, 3)
            @test a * b isa Polymake.QuadraticExtension{Polymake.Rational}
            @test b * a isa Polymake.QuadraticExtension{Polymake.Rational}
            @test a * b == b * a == Polymake.QuadraticExtension{Polymake.Rational}(85, 17, 3)
            @test a // b isa Polymake.QuadraticExtension{Polymake.Rational}
            @test b // a isa Polymake.QuadraticExtension{Polymake.Rational}
            @test a // b == 1//(b // a) == Polymake.QuadraticExtension{Polymake.Rational}(5//17, 1//17, 3)
        end
        for T in FloatTypes
            a = Polymake.QuadraticExtension{Polymake.Rational}(5, 1, 3)
            b = T(17)
            c = Polymake.QuadraticExtension{Polymake.Rational}(17)
            @test b == c
            @test c == b
            @test a != b
            @test a <= b
            @test a < b
            @test b >= a
            @test b > a
            @test a + b isa AbstractFloat
            @test b + a isa AbstractFloat
            @test a + b == b + a ≈ Float64(Polymake.QuadraticExtension{Polymake.Rational}(22, 1, 3))
            @test a - b isa AbstractFloat
            @test b - a isa AbstractFloat
            @test a - b == -(b - a) ≈ Float64(Polymake.QuadraticExtension{Polymake.Rational}(-12, 1, 3))
            @test a * b isa AbstractFloat
            @test b * a isa AbstractFloat
            @test a * b == b * a ≈ Float64(Polymake.QuadraticExtension{Polymake.Rational}(85, 17, 3))
            @test a / b isa AbstractFloat
            @test b / a isa AbstractFloat
            @test a / b ≈ 1/(b / a) ≈ Float64(Polymake.QuadraticExtension{Polymake.Rational}(5//17, 1//17, 3))
        end
    end
    
    @testset verbose=true "precise access" begin
        
        a = Polymake.QuadraticExtension{Polymake.Rational}(5, 1, 3)
        @test Polymake.generating_field_elements(a) isa NamedTuple{(:a, :b, :r), Tuple{Polymake.RationalAllocated, Polymake.RationalAllocated, Polymake.RationalAllocated}}
        t = Polymake.generating_field_elements(a)
        @test t.a == 5
        @test t.b == 1
        @test t.r == 3
        
    end
    
end
