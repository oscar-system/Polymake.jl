using SparseArrays

@testset "pm_IncidenceMatrix" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]
    FloatTypes = [Float32, Float64, BigFloat]
    SymTypes = [pm_NonSymmetric, pm_Symmetric]

    for S in SymTypes
        for N in [IntTypes; FloatTypes; pm_Integer; pm_Rational]
            @test pm_IncidenceMatrix{S} <: AbstractSparseMatrix
            @test pm_IncidenceMatrix{S} <: AbstractSparseMatrix{Bool}
            @test pm_IncidenceMatrix{S}(3,4) isa AbstractSparseMatrix
            @test pm_IncidenceMatrix{S}(3,4) isa AbstractSparseMatrix{Bool}
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
        for N in [IntTypes; FloatTypes; pm_Integer; pm_Rational]
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

            for T in [IntTypes; pm_Integer]
                N = pm_IncidenceMatrix(jl_n) # local copy
                @test setindex!(N, T(5), 1, 1) isa T
                @test N[T(1), 1] isa Bool
                @test N[1, T(1)] == true
                # testing the return value of brackets operator
                @test N[2, 2] = T(10) isa T
                N[2, 2] = T(10)
                @test N[2, 2] == true
                @test string(N) == "pm::IncidenceMatrix<pm::NonSymmetric>\n{0 2}\n{0 1}\n"
                # testing the return value when asking for a single row or column
                @test row(N, T(1)) isa pm_Set{Int32}
                @test row(N, T(1)) == Set([1, 3])
                @test col(N, T(2)) isa pm_Set{Int32}
                @test col(N, T(2)) == Set([2])

                @test_throws BoundsError row(N, T(0))
                @test_throws BoundsError row(N, T(3))
                @test_throws BoundsError col(N, T(0))
                @test_throws BoundsError col(N, T(4))
            end
        end

        @testset "pm_IncidenceMatrix{pm_Symmetric}" begin
            S = pm_IncidenceMatrix{pm_Symmetric}(jl_s)
            # linear indexing:
            @test S[1] == true
            @test S[5] == false

            @test_throws BoundsError S[0, 1]
            @test_throws BoundsError S[2, 5]
            @test_throws BoundsError S[4, 1]

            @test length(S) == 9
            @test size(S) == (3,3)

            for T in [IntTypes; pm_Integer]
                S = pm_IncidenceMatrix{pm_Symmetric}(jl_s) # local copy
                @test setindex!(S, T(5), 3, 3) isa T
                @test S[T(3), 3] isa Bool
                @test S[3, T(3)] == true
                # testing the return value of brackets operator
                @test S[1, 3] = T(0) isa T
                S[1, 3] = T(0)
                @test S[1, 3] == false
                @test S[3, 1] == false
                @test string(S) == "pm::IncidenceMatrix<pm::Symmetric>\n{0}\n{}\n{2}\n"
                # testing the return value when asking for a single row or column
                @test row(S, T(2)) isa pm_Set{Int32}
                @test row(S, T(2)) == Set([])
                @test col(S, T(3)) isa pm_Set{Int32}
                @test col(S, T(3)) == Set([3])

                @test_throws BoundsError row(S, T(0))
                @test_throws BoundsError row(S, T(4))
                @test_throws BoundsError col(S, T(0))
                @test_throws BoundsError col(S, T(12345))
            end
        end
    end

    @testset "Arithmetic" begin
        for S in SymTypes
            V = pm_IncidenceMatrix{S}(jl_s)
            @test (!).(V) isa Polymake.pm_IncidenceMatrixAllocated{pm_NonSymmetric}
            @test float.(V) isa Polymake.pm_MatrixAllocated{Float64}
            @test V[1, :] isa BitArray{1}
            @test float.(V)[1, :] isa pm_Vector{Float64}

            @test similar(V, Bool) isa Polymake.pm_IncidenceMatrixAllocated{pm_NonSymmetric}
            @test similar(V, Float64) isa Polymake.pm_MatrixAllocated{Float64}
            @test similar(V, Float64, 10) isa Polymake.pm_VectorAllocated{Float64}
            @test similar(V, Float64, 10, 10) isa Polymake.pm_MatrixAllocated{Float64}

            @test (!).(V) isa Polymake.pm_IncidenceMatrixAllocated{pm_NonSymmetric}
            @test ((&).(V, (!).(V))) == zeros(3,3)
            @test ((|).(V, (!).(V))) == ones(3,3)
            @test -V isa Polymake.pm_MatrixAllocated{pm_Integer}
            @test -V == -jl_s

            int_scalar_types = [IntTypes; pm_Integer]
            rational_scalar_types = [[Rational{T} for T in IntTypes]; pm_Rational]

            @test 2V isa pm_Matrix{pm_Integer}
            @test Int32(2)V isa pm_Matrix{Int32}

            for T in int_scalar_types
                U = Polymake.promote_to_pm_type(pm_Matrix,T)

                op = *
                @test op(T(2), V) isa pm_Matrix{U}
                @test op(V, T(2)) isa pm_Matrix{U}
                @test broadcast(op, T(2), V) isa pm_Matrix{U}
                @test broadcast(op, V, T(2)) isa pm_Matrix{U}

                op = +
                @test op(V, T.(jl_s)) isa pm_Matrix{U}
                @test op(T.(jl_s), V) isa pm_Matrix{U}
                @test broadcast(op, V, T.(jl_s)) isa pm_Matrix{U}
                @test broadcast(op, T.(jl_s), V) isa pm_Matrix{U}

                @test broadcast(op, V, T(2)) isa pm_Matrix{U}
                @test broadcast(op, T(2), V) isa pm_Matrix{U}

                op = //
                @test op(V, T(2)) isa pm_Matrix{pm_Rational}
                @test broadcast(op, V, T(2)) isa pm_Matrix{pm_Rational}

                op = /
                @test op(V, T(2)) isa pm_Matrix{Float64}
                @test broadcast(op, V, T(2)) isa pm_Matrix{Float64}
            end

            for T in rational_scalar_types
                U = Polymake.promote_to_pm_type(pm_Matrix,T)

                op = *
                @test op(T(2), V) isa pm_Matrix{U}
                @test op(V, T(2)) isa pm_Matrix{U}
                @test broadcast(op, T(2), V) isa pm_Matrix{U}
                @test broadcast(op, V, T(2)) isa pm_Matrix{U}

                op = +
                @test op(V, T.(jl_s)) isa pm_Matrix{U}
                @test op(T.(jl_s), V) isa pm_Matrix{U}

                @test broadcast(op, V, T.(jl_s)) isa pm_Matrix{U}
                @test broadcast(op, T.(jl_s), V) isa pm_Matrix{U}

                @test broadcast(op, T(2), V) isa pm_Matrix{U}
                @test broadcast(op, V, T(2)) isa pm_Matrix{U}

                if U == Float64
                    op = /
                else
                    op = //
                end

                @test op(V, T(2)) isa pm_Matrix{U}
                #@test broadcast(op, T(2), V) isa pm_Matrix{U}
                @test broadcast(op, V, T(2)) isa pm_Matrix{U}
            end
            for T in FloatTypes
                U = Polymake.promote_to_pm_type(pm_Matrix,T)
                op = *
                @test op(T(2), V) isa pm_Matrix{U}
                @test op(V, T(2)) isa pm_Matrix{U}
                @test broadcast(op, T(2), V) isa pm_Matrix{U}
                @test broadcast(op, V, T(2)) isa pm_Matrix{U}

                op = +
                @test op(V, T.(jl_s)) isa pm_Matrix{U}
                @test op(T.(jl_s), V) isa pm_Matrix{U}

                @test broadcast(op, V, T.(jl_s)) isa pm_Matrix{U}
                @test broadcast(op, T.(jl_s), V) isa pm_Matrix{U}

                @test broadcast(op, T(2), V) isa pm_Matrix{U}
                @test broadcast(op, V, T(2)) isa pm_Matrix{U}

                op = /
                # @test op(T(2), V) isa pm_Matrix{U}
                @test op(V, T(2)) isa pm_Matrix{U}
                # @test broadcast(op, T(2), V) isa pm_Matrix{U}
                @test broadcast(op, V, T(2)) isa pm_Matrix{U}
            end

            for T in [int_scalar_types; rational_scalar_types; FloatTypes]
                @test T(2)*V == V*T(2) == T(2) .* V == V .* T(2) == 2jl_s

                @test V + T.(jl_s) == T.(jl_s) + V == V .+ T.(jl_s) == T.(jl_s) .+ V == 2jl_s
            end
        end
    end
end
