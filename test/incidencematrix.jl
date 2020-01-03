@testset "pm_Matrix" begin
    IntTypes = [Int32, Int64, UInt64, BigInt, pm_Integer]
    FloatTypes = [Float32, Float64, BigFloat, pm_Rational]
    SymTypes = [pm_NonSymmetric, pm_Symmetric]

    for S in SymTypes
        for N in [IntTypes; FloatTypes]
            #TODO replace AbstractMatrix by pm_SparseMatrix?
            @test pm_IncidenceMatrix{S} <: AbstractMatrix
            @test pm_IncidenceMatrix{S}(3,4) isa AbstractMatrix
            @test pm_IncidenceMatrix{S}(3,4) isa pm_IncidenceMatrix
            @test pm_IncidenceMatrix{S}(3,4) isa pm_IncidenceMatrix{S}
            M = pm_IncidenceMatrix{S}(3,4)
            M[1,1] = N(1)
            M[end] = N(100)
            #TODO replace pm_Integer?
            @test M[1,1] isa pm_Integer
            @test M[1,1] == 1
            @test M[end] isa pm_Integer
            @test M[end] == M[end, end] == 1
            @test M[2,3] isa pm_Integer
            @test M[2,3] == 0
            M[2,3] = N(0)
            @test M[2,3] isa pm_Integer
            @test M[2,3] == 0
        end
    end

    jl_s = [1 0 1; 0 0 0; 1 0 0]
    jl_n = [0 0 1; 1 0 0]
    @testset "Constructors/Converts" begin
        for N in [IntTypes; FloatTypes]
            @test pm_IncidenceMatrix(N.(jl_n)) isa pm_IncidenceMatrix{pm_NonSymmetric}
            @test pm_IncidenceMatrix{pm_NonSymmetric}(N.(jl_s)) isa pm_IncidenceMatrix{pm_NonSymmetric}
            @test pm_IncidenceMatrix{pm_Symmetric}(N.(jl_s)) isa pm_IncidenceMatrix{pm_Symmetric}

            @test N.(jl_n) == convert(Matrix{N},pm_IncidenceMatrix(N.(jl_n)))
            @test N.(jl_s) == convert(Matrix{N},pm_IncidenceMatrix{pm_Symmetric}(N.(jl_s)))

            @test_throws ArgumentError pm_IncidenceMatrix{pm_Symmetric}(jl_n)
            @test_throws ArgumentError pm_IncidenceMatrix{pm_Symmetric}([0 1 0; 0 0 0; 0 0 0])
        end
    end

    @testset "Low-level operations" begin
        @testset "pm_IncidenceMatrix{pm_NonSymmetric}" begin
            N = pm_IncidenceMatrix(jl_n)
            # linear indexing:
            @test N[1] == 0
            @test N[5] == 1

            @test_throws BoundsError N[0, 1]
            @test_throws BoundsError N[2, 5]
            @test_throws BoundsError N[3, 1]

            @test length(N) == 6
            @test size(N) == (2,3)

            for T in IntTypes
                N = pm_IncidenceMatrix(jl_n) # local copy
                @test setindex!(N, T(5), 1, 1) isa T
                @test N[T(1), 1] isa pm_Integer
                @test N[1, T(1)] == 1
                # testing the return value of brackets operator
                @test N[2, 2] = T(10) isa T
                N[2, 2] = T(10)
                @test N[2, 2] == 1
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
                @test S[T(3), 3] isa pm_Integer
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
