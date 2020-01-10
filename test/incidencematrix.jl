using SparseArrays

@testset "pm_Matrix" begin
    IntTypes = [Int32, Int64, UInt64, BigInt, pm_Integer]
    FloatTypes = [Float32, Float64, BigFloat, pm_Rational]
    SymTypes = [pm_NonSymmetric, pm_Symmetric]

    for S in SymTypes
        for N in [IntTypes; FloatTypes]
            @test pm_IncidenceMatrix{S} <: AbstractSparseMatrix
            @test pm_IncidenceMatrix{S}(3,4) isa AbstractSparseMatrix
            @test pm_IncidenceMatrix{S}(3,4) isa pm_IncidenceMatrix
            @test pm_IncidenceMatrix{S}(3,4) isa pm_IncidenceMatrix{S}
            M = pm_IncidenceMatrix{S}(3,4)
            M[1,1] = N(1)
            M[end] = N(100)
            @test M[1,1] isa Bool
            @test M[1,1] == true
            @test M[end] isa Bool
            @test M[end] == M[end, end] == true
            @test M[2,3] isa Bool
            @test M[2,3] == false
            M[2,3] = N(0)
            @test M[2,3] isa Bool
            @test M[2,3] == false
        end
    end

    jl_s = [1 0 1; 0 0 0; 1 0 0]
    jl_n = [0 0 1; 1 0 0]
    @testset "Constructors/Converts" begin
        for N in [IntTypes; FloatTypes]
            @test pm_IncidenceMatrix(N.(jl_n)) isa pm_IncidenceMatrix{pm_NonSymmetric}
            @test pm_IncidenceMatrix{pm_NonSymmetric}(N.(jl_s)) isa pm_IncidenceMatrix{pm_NonSymmetric}
            @test pm_IncidenceMatrix{pm_Symmetric}(N.(jl_s)) isa pm_IncidenceMatrix{pm_Symmetric}
            @test pm_IncidenceMatrix(SparseMatrixCSC(N.(jl_n))) isa pm_IncidenceMatrix{pm_NonSymmetric}
            @test pm_IncidenceMatrix{pm_NonSymmetric}(SparseMatrixCSC(N.(jl_s))) isa pm_IncidenceMatrix{pm_NonSymmetric}
            @test pm_IncidenceMatrix{pm_Symmetric}(SparseMatrixCSC(N.(jl_s))) isa pm_IncidenceMatrix{pm_Symmetric}

            @test N.(jl_n) == convert(Matrix{N},pm_IncidenceMatrix(N.(jl_n))) == convert(Matrix{N},pm_IncidenceMatrix(SparseMatrixCSC(N.(jl_n))))
            @test N.(jl_s) == convert(Matrix{N},pm_IncidenceMatrix{pm_Symmetric}(N.(jl_s))) == convert(Matrix{N},pm_IncidenceMatrix(SparseMatrixCSC(N.(jl_s))))

            @test_throws ArgumentError pm_IncidenceMatrix{pm_Symmetric}(jl_n)
            @test_throws ArgumentError pm_IncidenceMatrix{pm_Symmetric}([0 1 0; 0 0 0; 0 0 0])
            @test_throws ArgumentError pm_IncidenceMatrix{pm_Symmetric}(SparseMatrixCSC(jl_n))
            @test_throws ArgumentError pm_IncidenceMatrix{pm_Symmetric}(SparseMatrixCSC([0 1 0; 0 0 0; 0 0 0]))
        end
    end

    @testset "Low-level operations" begin
        @testset "pm_IncidenceMatrix{pm_NonSymmetric}" begin
            N = pm_IncidenceMatrix(jl_n)
            # linear indexing:
            @test N[1] == false
            @test N[5] == true

            @test_throws BoundsError N[0, 1]
            @test_throws BoundsError N[2, 5]
            @test_throws BoundsError N[3, 1]

            @test length(N) == 6
            @test size(N) == (2,3)

            resize!(N,3,5)
            @test length(N) == 15
            @test size(N) == (3,5)
            @test N[1:2,1:3] == jl_n
            for i = 1:2
                # for j = 1:3
                #     @test N[i,j] == jl_n[i,j]
                # end
                for j = 4:5
                    @test N[i,j] == false
                end
            end
            for j = 1:5
                @test N[3,j] == false
            end

            resize!(N,2,3)
            @test size(N) == (2,3)
            @test N == jl_n

            for T in IntTypes
                N = pm_IncidenceMatrix(jl_n) # local copy
                @test setindex!(N, T(5), 1, 1) isa T
                @test N[T(1), 1] isa Bool
                @test N[1, T(1)] == true
                # testing the return value of brackets operator
                @test N[2, 2] = T(10) isa T
                N[2, 2] = T(10)
                @test N[2, 2] == true
                @test string(N) == "pm::IncidenceMatrix<pm::NonSymmetric>\n{0 2}\n{0 1}\n"
            end
        end

        @testset "pm_IncidenceMatrix{pm_Symmetric}" begin
            S = pm_IncidenceMatrix{pm_Symmetric}(jl_s)
            # linear indexing:
            @test S[1] == 1
            @test S[5] == 0

            @test_throws BoundsError S[0, 1]
            @test_throws BoundsError S[2, 5]
            @test_throws BoundsError S[4, 1]

            @test length(S) == 9
            @test size(S) == (3,3)

            for T in IntTypes
                S = pm_IncidenceMatrix{pm_Symmetric}(jl_s) # local copy
                @test setindex!(S, T(5), 3, 3) isa T
                @test S[T(3), 3] isa Bool
                @test S[3, T(3)] == 1
                # testing the return value of brackets operator
                @test S[1, 3] = T(0) isa T
                S[1, 3] = T(0)
                @test S[1, 3] == 0
                @test S[3, 1] == 0
                @test string(S) == "pm::IncidenceMatrix<pm::Symmetric>\n{0}\n{}\n{2}\n"
            end
        end
    end
end
