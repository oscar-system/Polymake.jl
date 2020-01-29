using SparseArrays
@testset "Polymake.Polynomial" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]
    FloatTypes = [Float32, Float64, BigFloat]
    RationalTypes = [Rational{I} for I in IntTypes]

    for C in [Int64, Polymake.Integer, Polymake.Rational, Float64]
        @test Polymake.Polynomial{C,Int64} <: Any
        @test Polymake.Polynomial{C,Int64}([1, 2],[3 4 5; 6 7 8]) isa Any
        @test Polymake.Polynomial{C,Int64}([1, 2],[3 4 5; 6 7 8]) isa Polymake.Polynomial
        @test Polymake.Polynomial{C,Int64}([1, 2],[3 4 5; 6 7 8]) isa Polymake.Polynomial{C,Int64}
        P = Polymake.Polynomial{C,Int64}([1, 2],[3 4 5; 6 7 8])
        @test Polymake.coefficients_as_vector(P) isa Polymake.Vector
        @test Polymake.coefficients_as_vector(P) isa Polymake.Vector{C}
        @test Polymake.monomials_as_matrix(P) isa Polymake.SparseMatrix
        @test Polymake.monomials_as_matrix(P) isa Polymake.SparseMatrix{Int64}
    end

    jl_v = [1, 2]
    jl_m = [3 4 5; 6 7 0]
    @testset "Constructors/Converts" begin
        for C in [Int64, Polymake.Integer, Polymake.Rational, Float64]
            @test Polymake.Polynomial(C.(jl_v), jl_m) isa Polymake.Polynomial{C,Int64}
            @test Polymake.Polynomial{Float64}(C.(jl_v), jl_m) isa Polymake.Polynomial{Float64,Int64}
            @test Polymake.Polynomial{Polymake.Rational,Int64}(C.(jl_v), jl_m) isa Polymake.Polynomial{Polymake.Rational,Int64}
        end
    end

    @testset "Low-level operations" begin
        for (C,s) in [(Int64, "long"), (Polymake.Integer, "pm::Integer"), (Polymake.Rational, "pm::Rational"), (Float64, "double")]
            p = Polymake.Polynomial(C.(jl_v),jl_m)
            @test string(p) == string("pm::Polynomial<", s, ", long>\n2*x_0^6*x_1^7 + x_0^3*x_1^4*x_2^5")
            Polymake.set_var_names(p,["x", "y", "z"])
            @test Polymake.get_var_names(p) == ["x", "y", "z"]
            @test string(p) == string("pm::Polynomial<", s, ", long>\n2*x^6*y^7 + x^3*y^4*z^5")
        end
    end

    @testset "Equality" begin
        for C1 in [Int64, Polymake.Integer, Polymake.Rational, Float64], C2 in [Int64, Polymake.Integer, Polymake.Rational, Float64]
            @test Polymake.Polynomial(C1.(jl_v),jl_m) == Polymake.Polynomial(C2.(jl_v),jl_m)
        end
    end

end
