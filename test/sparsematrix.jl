@testset "pm_SparseMatrix" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]
    FloatTypes = [Float32, Float64, BigFloat]

    for T in [Int32, pm_Integer, pm_Rational, Float64]
        # @test pm_SparseMatrix{T} <: AbstractSparseMatrix
        # @test pm_SparseMatrix{T}(3,4) isa AbstractSparseMatrix
        @test pm_SparseMatrix{T}(3,4) isa pm_SparseMatrix
        @test pm_SparseMatrix{T}(3,4) isa pm_SparseMatrix{T}
        M = pm_SparseMatrix{T}(3,4)
        M[1,1] = 10
        @test M[1,1] isa T
        @test M[1,1] == 10
    end

    jl_m = [1 2 3; 4 5 6]
    @testset "Constructors/Converts" begin
        for T in [IntTypes; pm_Integer]
            @test pm_SparseMatrix(T.(jl_m)) isa pm_SparseMatrix{T == Int32 ? Int32 : pm_Integer}
            @test pm_SparseMatrix(jl_m//1) isa pm_SparseMatrix{pm_Rational}
            @test pm_SparseMatrix(jl_m/1) isa pm_SparseMatrix{Float64}

            for ElType in [pm_Integer, pm_Rational, Float64]
                for m in [jl_m, jl_m//T(1), jl_m/T(1)]
                    @test pm_SparseMatrix{ElType}(m) isa pm_SparseMatrix{ElType}
                    @test convert(pm_SparseMatrix{ElType}, m) isa pm_SparseMatrix{ElType}

                    M = pm_SparseMatrix(m)
                    @test convert(Matrix{T}, M) isa Matrix{T}
                    @test jl_m == convert(Matrix{T}, M)
                end
            end
        #
        #     for m in [jl_m, jl_m//T(1), jl_m/T(1)]
        #         M = pm_SparseMatrix(m)
        #         @test Polymake.convert(Polymake.PolymakeType, M) === M
        #         @test float.(M) isa pm_SparseMatrix{Float64}
        #         @test Float64.(M) isa pm_SparseMatrix{Float64}
        #         @test Matrix{Float64}(M) isa Matrix{Float64}
        #         @test convert.(Float64, M) isa pm_Matrix{Float64}
        #     end
        #
        #     let W = pm_Matrix{pm_Rational}(jl_m)
        #         for T in [Rational{I} for I in IntTypes]
        #             @test convert(Matrix{T}, W) isa Matrix{T}
        #             @test jl_m == convert(Matrix{T}, W)
        #         end
        #     end
        #
        #     let U = pm_Matrix{Float64}(jl_m)
        #         for T in FloatTypes
        #             @test convert(Matrix{T}, U) isa Matrix{T}
        #             @test jl_m == convert(Matrix{T}, U)
        #         end
        #     end
        end
    end

end
