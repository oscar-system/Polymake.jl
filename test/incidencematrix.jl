using SparseArrays

@testset "IncidenceMatrix" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]
    FloatTypes = [Float32, Float64, BigFloat]
    SymTypes = [Polymake.NonSymmetric, Polymake.Symmetric]

    for S in SymTypes
        for N in [IntTypes; FloatTypes; Polymake.Integer; Polymake.Rational]
            @test Polymake.IncidenceMatrix{S} <: AbstractSparseMatrix
            @test Polymake.IncidenceMatrix{S} <: AbstractSparseMatrix{Polymake.to_cxx_type(Bool)}
            @test Polymake.IncidenceMatrix{S}(3,4) isa AbstractSparseMatrix
            @test Polymake.IncidenceMatrix{S}(3,4) isa AbstractSparseMatrix{Polymake.to_cxx_type(Bool)}
            @test Polymake.IncidenceMatrix{S}(3,4) isa Polymake.IncidenceMatrix
            @test Polymake.IncidenceMatrix{S}(3,4) isa Polymake.IncidenceMatrix{S}
            M = Polymake.IncidenceMatrix{S}(3,4)
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
        inc = [[1,2,4],[3,5]]
        @test Polymake.IncidenceMatrix{Polymake.NonSymmetric}(inc) isa Polymake.IncidenceMatrix{Polymake.NonSymmetric}
        M = Polymake.IncidenceMatrix{Polymake.NonSymmetric}(inc)
        @test M[1,1] == true
        @test M[2,1] == false
        @test M[1,1] isa Bool
        @test size(M) == (2,5)
        for N in [IntTypes; FloatTypes; Polymake.Integer; Polymake.Rational]
            @test Polymake.IncidenceMatrix(N.(jl_n)) isa Polymake.IncidenceMatrix{Polymake.NonSymmetric}
            @test Polymake.IncidenceMatrix{Polymake.NonSymmetric}(N.(jl_s)) isa Polymake.IncidenceMatrix{Polymake.NonSymmetric}
            @test Polymake.IncidenceMatrix{Polymake.Symmetric}(N.(jl_s)) isa Polymake.IncidenceMatrix{Polymake.Symmetric}
            @test Polymake.IncidenceMatrix(SparseMatrixCSC(N.(jl_n))) isa Polymake.IncidenceMatrix{Polymake.NonSymmetric}
            @test Polymake.IncidenceMatrix{Polymake.NonSymmetric}(SparseMatrixCSC(N.(jl_s))) isa Polymake.IncidenceMatrix{Polymake.NonSymmetric}
            @test Polymake.IncidenceMatrix{Polymake.Symmetric}(SparseMatrixCSC(N.(jl_s))) isa Polymake.IncidenceMatrix{Polymake.Symmetric}

            @test N.(jl_n) == convert(Base.Matrix{N},Polymake.IncidenceMatrix(N.(jl_n))) == convert(Base.Matrix{N},Polymake.IncidenceMatrix(SparseMatrixCSC(N.(jl_n))))
            @test N.(jl_s) == convert(Base.Matrix{N},Polymake.IncidenceMatrix{Polymake.Symmetric}(N.(jl_s))) == convert(Base.Matrix{N},Polymake.IncidenceMatrix(SparseMatrixCSC(N.(jl_s))))

            @test_throws ArgumentError Polymake.IncidenceMatrix{Polymake.Symmetric}(jl_n)
            @test_throws ArgumentError Polymake.IncidenceMatrix{Polymake.Symmetric}([0 1 0; 0 0 0; 0 0 0])
            @test_throws ArgumentError Polymake.IncidenceMatrix{Polymake.Symmetric}(SparseMatrixCSC(jl_n))
            @test_throws ArgumentError Polymake.IncidenceMatrix{Polymake.Symmetric}(SparseMatrixCSC([0 1 0; 0 0 0; 0 0 0]))
        end
    end

    @testset "Low-level operations" begin
        @testset "Polymake.IncidenceMatrix{Polymake.NonSymmetric}" begin
            N = Polymake.IncidenceMatrix(jl_n)
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

            ri, ci, v = findnz(N)
            @test ri == [1, 2]
            @test ci == [3, 1]
            @test v == [true, true]
            nzi, v = findnz(N[1, :])
            @test nzi == [3]
            @test v == [true]

            for T in [IntTypes; Polymake.Integer]
                N = Polymake.IncidenceMatrix(jl_n) # local copy
                @test setindex!(N, T(5), 1, 1) isa T
                @test N[T(1), 1] isa Bool
                @test N[1, T(1)] == true
                # testing the return value of brackets operator
                @test N[2, 2] = T(10) isa T
                N[2, 2] = T(10)
                @test N[2, 2] == true
                @test string(N) == "2×3 IncidenceMatrix\n[1, 3]\n[1, 2]\n"
                # testing the return value when asking for a single row or column
                @test Polymake.row(N, T(1)) isa Polymake.Set{Polymake.to_cxx_type(Int)}
                @test Polymake.row(N, T(1)) == Set([1, 3])
                @test Polymake.col(N, T(2)) isa Polymake.Set{Polymake.to_cxx_type(Int)}
                @test Polymake.col(N, T(2)) == Set([2])

                @test_throws BoundsError Polymake.row(N, T(0))
                @test_throws BoundsError Polymake.row(N, T(3))
                @test_throws BoundsError Polymake.col(N, T(0))
                @test_throws BoundsError Polymake.col(N, T(4))
            end
        end

        @testset "Polymake.IncidenceMatrix{Polymake.Symmetric}" begin
            S = Polymake.IncidenceMatrix{Polymake.Symmetric}(jl_s)
            # linear indexing:
            @test S[1] == true
            @test S[5] == false

            @test_throws BoundsError S[0, 1]
            @test_throws BoundsError S[2, 5]
            @test_throws BoundsError S[4, 1]

            @test length(S) == 9
            @test size(S) == (3,3)

            for T in [IntTypes; Polymake.Integer]
                S = Polymake.IncidenceMatrix{Polymake.Symmetric}(jl_s) # local copy
                @test setindex!(S, T(5), 3, 3) isa T
                @test S[T(3), 3] isa Bool
                @test S[3, T(3)] == true
                # testing the return value of brackets operator
                @test S[1, 3] = T(0) isa T
                S[1, 3] = T(0)
                @test S[1, 3] == false
                @test S[3, 1] == false
                @test string(S) == "3×3 IncidenceMatrix\n[1]\n[]\n[3]\n"
                # testing the return value when asking for a single row or column
                @test Polymake.row(S, T(2)) isa Polymake.Set{Polymake.to_cxx_type(Int)}
                @test Polymake.row(S, T(2)) == Set([])
                @test Polymake.col(S, T(3)) isa Polymake.Set{Polymake.to_cxx_type(Int)}
                @test Polymake.col(S, T(3)) == Set([3])

                @test_throws BoundsError Polymake.row(S, T(0))
                @test_throws BoundsError Polymake.row(S, T(4))
                @test_throws BoundsError Polymake.col(S, T(0))
                @test_throws BoundsError Polymake.col(S, T(12345))
            end
        end
    end

    @testset "Arithmetic" begin
        for S in SymTypes
            V = Polymake.IncidenceMatrix{S}(jl_s)
            @test (!).(V) isa Polymake.IncidenceMatrixAllocated{Polymake.NonSymmetric}
            @test float.(V) isa Polymake.MatrixAllocated{Float64}
            @test V[1, :] isa Polymake.SparseVectorBool
            @test float.(V)[1, :] isa Polymake.Vector{Float64}

            @test similar(V, Bool) isa Polymake.IncidenceMatrixAllocated{Polymake.NonSymmetric}
            @test similar(V, Float64) isa Polymake.MatrixAllocated{Float64}
            @test similar(V, Float64, 10) isa Polymake.VectorAllocated{Float64}
            @test similar(V, Float64, 10, 10) isa Polymake.MatrixAllocated{Float64}

            @test (!).(V) isa Polymake.IncidenceMatrixAllocated{Polymake.NonSymmetric}
            @test ((&).(V, (!).(V))) == zeros(3,3)
            @test ((|).(V, (!).(V))) == ones(3,3)
            @test -V isa Polymake.MatrixAllocated{Polymake.to_cxx_type(Int)}
            @test -V == -jl_s

            int_scalar_types = [IntTypes; Polymake.Integer]
            rational_scalar_types = [[Base.Rational{T} for T in IntTypes]; Polymake.Rational]

            @test 2V isa Polymake.Matrix{Polymake.to_cxx_type(Int)}
            @test Int32(2)V isa Polymake.Matrix{Polymake.to_cxx_type(Int)}

            for T in int_scalar_types
                U = Polymake.promote_to_pm_type(Polymake.Matrix, T)
                U = Polymake.to_cxx_type(U)

                op = *
                @test op(T(2), V) isa Polymake.Matrix{U}
                @test op(V, T(2)) isa Polymake.Matrix{U}
                @test broadcast(op, T(2), V) isa Polymake.Matrix{U}
                @test broadcast(op, V, T(2)) isa Polymake.Matrix{U}

                op = +
                @test op(V, T.(jl_s)) isa Polymake.Matrix{U}
                @test op(T.(jl_s), V) isa Polymake.Matrix{U}
                @test broadcast(op, V, T.(jl_s)) isa Polymake.Matrix{U}
                @test broadcast(op, T.(jl_s), V) isa Polymake.Matrix{U}

                @test broadcast(op, V, T(2)) isa Polymake.Matrix{U}
                @test broadcast(op, T(2), V) isa Polymake.Matrix{U}

                op = //
                @test op(V, T(2)) isa Polymake.Matrix{Polymake.Rational}
                @test broadcast(op, V, T(2)) isa Polymake.Matrix{Polymake.Rational}

                op = /
                @test op(V, T(2)) isa Polymake.Matrix{Float64}
                @test broadcast(op, V, T(2)) isa Polymake.Matrix{Float64}
            end

            for T in rational_scalar_types
                U = Polymake.promote_to_pm_type(Polymake.Matrix,T)

                op = *
                @test op(T(2), V) isa Polymake.Matrix{U}
                @test op(V, T(2)) isa Polymake.Matrix{U}
                @test broadcast(op, T(2), V) isa Polymake.Matrix{U}
                @test broadcast(op, V, T(2)) isa Polymake.Matrix{U}

                op = +
                @test op(V, T.(jl_s)) isa Polymake.Matrix{U}
                @test op(T.(jl_s), V) isa Polymake.Matrix{U}

                @test broadcast(op, V, T.(jl_s)) isa Polymake.Matrix{U}
                @test broadcast(op, T.(jl_s), V) isa Polymake.Matrix{U}

                @test broadcast(op, T(2), V) isa Polymake.Matrix{U}
                @test broadcast(op, V, T(2)) isa Polymake.Matrix{U}

                if U == Float64
                    op = /
                else
                    op = //
                end

                @test op(V, T(2)) isa Polymake.Matrix{U}
                #@test broadcast(op, T(2), V) isa Polymake.Matrix{U}
                @test broadcast(op, V, T(2)) isa Polymake.Matrix{U}
            end
            for T in FloatTypes
                U = Polymake.promote_to_pm_type(Polymake.Matrix,T)
                op = *
                @test op(T(2), V) isa Polymake.Matrix{U}
                @test op(V, T(2)) isa Polymake.Matrix{U}
                @test broadcast(op, T(2), V) isa Polymake.Matrix{U}
                @test broadcast(op, V, T(2)) isa Polymake.Matrix{U}

                op = +
                @test op(V, T.(jl_s)) isa Polymake.Matrix{U}
                @test op(T.(jl_s), V) isa Polymake.Matrix{U}

                @test broadcast(op, V, T.(jl_s)) isa Polymake.Matrix{U}
                @test broadcast(op, T.(jl_s), V) isa Polymake.Matrix{U}

                @test broadcast(op, T(2), V) isa Polymake.Matrix{U}
                @test broadcast(op, V, T(2)) isa Polymake.Matrix{U}

                op = /
                # @test op(T(2), V) isa Polymake.Matrix{U}
                @test op(V, T(2)) isa Polymake.Matrix{U}
                # @test broadcast(op, T(2), V) isa Polymake.Matrix{U}
                @test broadcast(op, V, T(2)) isa Polymake.Matrix{U}
            end

            for T in [int_scalar_types; rational_scalar_types; FloatTypes]
                @test T(2)*V == V*T(2) == T(2) .* V == V .* T(2) == 2jl_s

                @test V + T.(jl_s) == T.(jl_s) + V == V .+ T.(jl_s) == T.(jl_s) .+ V == 2jl_s
            end
        end
    end

    @test graph.Graph(ADJACENCY=Polymake.IncidenceMatrix(jl_s)) isa Polymake.BigObject

end
