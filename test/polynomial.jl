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
    jl_sv = sparsevec(jl_v)
    pm_v = Polymake.Vector(jl_v)
    # pm_sv = Polymake.SparseVector(jl_v) #TODO add when sparsevector is merged
    jl_m = [3 4 5; 6 7 8]
    jl_sm = sparse(jl_m)
    pm_m = Polymake.Matrix(jl_m)
    pm_sm = Polymake.SparseMatrix(jl_m)
    JuliaVecs = [(jl_v, Base.Vector), (jl_sv, SparseArrays.SparseVector)]
    JuliaMats = [(jl_m, Base.Matrix), (jl_sm, SparseArrays.SparseMatrixCSC)]
    PMVecs = [(pm_v, Polymake.Vector)] #TODO
    PMMats = [(pm_m, Polymake.Matrix)]
    @testset "Constructors/Converts" begin
        for (V, VT) in JuliaVecs, (M, MT) in JuliaMats, C in [IntTypes; FloatTypes; RationalTypes; Polymake.Integer; Polymake.Rational], E in [IntTypes; FloatTypes; RationalTypes; Polymake.Integer; Polymake.Rational], CoeffType in [Int64; Polymake.Integer; Polymake.Rational; Float64], ExpType in [Int64]
            @test Polymake.Polynomial(VT{C}(V), MT{E}(M)) isa Polymake.Polynomial{Polymake.promote_to_pm_type(Vector, C),Polymake.promote_to_pm_type(Matrix, Int64)}
            @test Polymake.Polynomial{CoeffType}(VT{C}(V), MT{E}(M)) isa Polymake.Polynomial{CoeffType,Polymake.promote_to_pm_type(Matrix, Int64)}
            @test Polymake.Polynomial{CoeffType,ExpType}(VT{C}(V), MT{E}(M)) isa Polymake.Polynomial{CoeffType,ExpType}
        end
        for (V, VT) in PMVecs, (M, MT) in PMMats, C in [Int64; Polymake.Integer; Polymake.Rational; Float64], CoeffType in [Int64; Polymake.Integer; Polymake.Rational; Float64], ExpType in [Int64]
            @test Polymake.Polynomial(VT{C}(V), MT{E}(M)) isa Polymake.Polynomial{C,E}
            @test Polymake.Polynomial{CoeffType}(VT{C}(V), MT{E}(M)) isa Polymake.Polynomial{CoeffType,E}
            @test Polymake.Polynomial{CoeffType,ExpType}(VT{C}(V), MT{E}(M)) isa Polymake.Polynomial{CoeffType,ExpType}
        end
            # for CoeffType in [Integer, Rational, Float64], ExpType in [Integer, Rational, Float64]
            #     for v in [jl_v, jl_v//T(1), jl_v/T(1)], m in [jl_m, jl_m//T(1), jl_m/T(1)]
            #         @test Polymake.Polynomial{CoeffType}(m) isa Polymake.Polynomial{CoeffType}
            #         @test Polymake.Polynomial{CoeffType}(m) isa Polymake.Polynomial{CoeffType,Int32}
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
