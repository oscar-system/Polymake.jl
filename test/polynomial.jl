using SparseArrays
@testset "Polynomial" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]
    FloatTypes = [Float32, Float64, BigFloat]

    for C in [Int32, Integer, Rational, Float64]
        for E in [Int32, Integer, Rational, Float64]
            @test Polynomial{C,E} <: Any
            @test Polynomial{C,E}([1, 2],[3 4 5; 6 7 8]) isa Any
            @test Polynomial{C,E}([1, 2],[3 4 5; 6 7 8]) isa Polynomial
            @test Polynomial{C,E}([1, 2],[3 4 5; 6 7 8]) isa Polynomial{C,E}
            P = Polynomial{C,E}([1, 2],[3 4 5; 6 7 8])
            @test coefficients_as_vector(P) isa Vector
            @test coefficients_as_vector(P) isa Vector{C}
            @test monomials_as_matrix(P) isa SparseMatrix
            @test monomials_as_matrix(P) isa SparseMatrix{E}
        end
    end

    jl_v = [1, 2]
    jl_sv = sparsevec(jl_v)
    pm_v = Vector(jl_v)
    # pm_sv = pm_SparseVector(jl_v) #TODO add when sparsevector is merged
    jl_m = [3 4 5; 6 7 8]
    jl_sm = sparse(jl_m)
    pm_m = Matrix(jl_m)
    pm_sm = SparseMatrix(jl_m)
    VecTypes = [Vector, sparsevec, Vector]
    MatTypes = [Matrix, sparse, Matrix, SparseMatrix]
    @testset "Constructors/Converts" begin
        # Rational{I} for I in IntTypes
        for V in VecTypes, M in MatTypes, C in [IntTypes; FloatTypes; Integer; Rational], E in [IntTypes; FloatTypes; Integer; Rational]
            @test Polynomial(V(C.(jl_v)), M(E.(jl_m))) isa Polynomial{Polymake.promote_to_pm_type(Vector, C),Polymake.promote_to_pm_type(Matrix, E)}
            # @test Polynomial(V,M) isa Polynomial{S,T}
            # for CoeffType in [Integer, Rational, Float64], ExpType in [Integer, Rational, Float64]
            #     for v in [jl_v, jl_v//T(1), jl_v/T(1)] m in [jl_m, jl_m//T(1), jl_m/T(1)]
            #         @test Polynomial{CoeffType}(m) isa Polynomial{CoeffType}
            #         @test Polynomial{CoeffType}(m) isa Polynomial{CoeffType,Int32}
            #         @test convert(SparseMatrix{ElType}, m) isa SparseMatrix{ElType}
            #
            #         M = SparseMatrix(m)
            #         @test convert(Matrix{T}, M) isa Matrix{T}
            #         @test jl_m == convert(Matrix{T}, M)
            #     end
            # end
            #
            # for m in [jl_m, jl_m//T(1), jl_m/T(1), jl_s, jl_s//T(1), jl_s/T(1)]
            #     M = SparseMatrix(m)
            #     @test Polymake.convert(Polymake.PolymakeType, M) === M
            #     @test float.(M) isa SparseMatrix{Float64}
            #     @test Float64.(M) isa SparseMatrix{Float64}
            #     @test Matrix{Float64}(M) isa Matrix{Float64}
            #     @test convert.(Float64, M) isa SparseMatrix{Float64}
            # end
        end
    end

end
