using SparseArrays
@testset "pm_Polynomial" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]
    FloatTypes = [Float32, Float64, BigFloat]

    for C in [Int32, pm_Integer, pm_Rational, Float64]
        for E in [Int32, pm_Integer, pm_Rational, Float64]
            @test pm_Polynomial{C,E} <: Any
            @test pm_Polynomial{C,E}([1, 2],[3 4 5; 6 7 8]) isa Any
            @test pm_Polynomial{C,E}([1, 2],[3 4 5; 6 7 8]) isa pm_Polynomial
            @test pm_Polynomial{C,E}([1, 2],[3 4 5; 6 7 8]) isa pm_Polynomial{C,E}
            P = pm_Polynomial{C,E}([1, 2],[3 4 5; 6 7 8])
            @test coefficients_as_vector(P) isa pm_Vector
            @test coefficients_as_vector(P) isa pm_Vector{C}
            @test monomials_as_matrix(P) isa pm_SparseMatrix
            @test monomials_as_matrix(P) isa pm_SparseMatrix{E}
        end
    end

    jl_v = [1, 2]
    jl_sv = sparsevec(jl_v)
    pm_v = pm_Vector(jl_v)
    # pm_sv = pm_SparseVector(jl_v) #TODO add when pm_sparsevector is merged
    jl_m = [3 4 5; 6 7 8]
    jl_sm = SparseMatrixCSC{Int32,Int32}(jl_m)
    pm_m = pm_Matrix(jl_m)
    pm_sm = pm_SparseMatrix(jl_m)
    TestVecs = [jl_v, jl_sv] #TODO add pm_sv
    TestMats = [jl_m]
    @testset "Constructors/Converts" begin
        for A in TestVecs, B in TestMats, C in [IntTypes; pm_Integer], E in [IntTypes; pm_Integer], (V,S) in [(C.(A), C == Int32 ? Int32 : pm_Integer), (A//1, pm_Rational), (A/1, Float64)], (M,T) in [(E.(B), E == Int32 ? Int32 : pm_Integer), (B//1, pm_Rational), (B/1, Float64)]
            @test pm_Polynomial(V,M) isa pm_Polynomial{S,T}
            # for CoeffType in [pm_Integer, pm_Rational, Float64], ExpType in [pm_Integer, pm_Rational, Float64]
            #     for v in [jl_v, jl_v//T(1), jl_v/T(1)] m in [jl_m, jl_m//T(1), jl_m/T(1)]
            #         @test pm_Polynomial{CoeffType}(m) isa pm_Polynomial{CoeffType}
            #         @test pm_Polynomial{CoeffType}(m) isa pm_Polynomial{CoeffType,Int32}
            #         @test convert(pm_SparseMatrix{ElType}, m) isa pm_SparseMatrix{ElType}
            #
            #         M = pm_SparseMatrix(m)
            #         @test convert(Matrix{T}, M) isa Matrix{T}
            #         @test jl_m == convert(Matrix{T}, M)
            #     end
            # end
            #
            # for m in [jl_m, jl_m//T(1), jl_m/T(1), jl_s, jl_s//T(1), jl_s/T(1)]
            #     M = pm_SparseMatrix(m)
            #     @test Polymake.convert(Polymake.PolymakeType, M) === M
            #     @test float.(M) isa pm_SparseMatrix{Float64}
            #     @test Float64.(M) isa pm_SparseMatrix{Float64}
            #     @test Matrix{Float64}(M) isa Matrix{Float64}
            #     @test convert.(Float64, M) isa pm_SparseMatrix{Float64}
            # end
        end
    end

end
