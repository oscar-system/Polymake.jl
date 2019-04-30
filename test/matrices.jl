@testset "pm_Matrix" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]
    FloatTypes = [Float32, Float64, BigFloat]

    for T in [pm_Integer, pm_Rational, Float64]
        @test pm_Matrix{T} <: AbstractMatrix
        @test pm_Matrix{T}(3,4) isa AbstractMatrix
        @test pm_Matrix{T}(3,4) isa pm_Matrix
        @test pm_Matrix{T}(3,4) isa pm_Matrix{T}
        M = pm_Matrix{T}(3,4)
        M[1,1] = 10
        @test M[1,1] isa T
        @test M[1,1] == 10
    end

    jl_m = [1 2 3; 4 5 6]
    @testset "Constructors/Converts" begin
        for T in [IntTypes; pm_Integer]
            @test pm_Matrix(T.(jl_m)) isa pm_Matrix{pm_Integer}
            @test pm_Matrix(jl_m//1) isa pm_Matrix{pm_Rational}
            @test pm_Matrix(jl_m/1) isa pm_Matrix{Float64}

            for ElType in [pm_Integer, pm_Rational, Float64]
                for m in [jl_m, jl_m//T(1), jl_m/T(1)]
                    @test pm_Matrix{ElType}(m) isa pm_Matrix{ElType}
                    @test convert(pm_Matrix{ElType}, m) isa pm_Matrix{ElType}

                    M = pm_Matrix(m)
                    @test convert(Matrix{T}, M) isa Matrix{T}
                    @test jl_m == convert(Matrix{T}, M)
                end
            end

            for m in [jl_m, jl_m//T(1), jl_m/T(1)]
                M = pm_Matrix(m)
                @test Polymake.convert_to_pm(M) === M
                @test float.(M) isa pm_Matrix{Float64}
                @test Float64.(M) isa pm_Matrix{Float64}
                @test Matrix{Float64}(M) isa Matrix{Float64}
                @test convert.(Float64, M) isa pm_Matrix{Float64}
            end

            let W = pm_Matrix{pm_Rational}(jl_m)
                for T in [Rational{I} for I in IntTypes]
                    @test convert(Matrix{T}, W) isa Matrix{T}
                    @test jl_m == convert(Matrix{T}, W)
                end
            end

            let U = pm_Matrix{Float64}(jl_m)
                for T in FloatTypes
                    @test convert(Matrix{T}, U) isa Matrix{T}
                    @test jl_m == convert(Matrix{T}, U)
                end
            end
        end
    end

    @testset "Low-level operations" begin
        @testset "pm_Matrix{pm_Integer}" begin
            V = pm_Matrix{pm_Integer}(jl_m)
            # linear indexing:
            @test V[1] == 1
            @test V[2] == 4

            @test eltype(V) == pm_Integer

            @test_throws BoundsError V[0, 1]
            @test_throws BoundsError V[2, 5]
            @test_throws BoundsError V[3, 1]

            @test length(V) == 6
            @test size(V) == (2,3)

            for T in [IntTypes; pm_Integer]
                V = pm_Matrix{pm_Integer}(jl_m) # local copy
                @test setindex!(V, T(5), 1, 1) isa pm_Matrix{pm_Integer}
                @test V[T(1), 1] isa Polymake.pm_IntegerAllocated
                @test V[1, T(1)] == 5
                # testing the return value of brackets operator
                @test V[2, 1] = T(10) isa T
                V[2, 1] = T(10)
                @test V[2, 1] == 10
                @test string(V) == "pm::Matrix<pm::Integer>\n5 2 3\n10 5 6\n"
            end
        end

        @testset "pm_Matrix{pm_Rational}" begin
            V = pm_Matrix{pm_Rational}(jl_m)
            # linear indexing:
            @test V[1] == 1//1
            @test V[2] == 4//1

            @test eltype(V) == pm_Rational

            @test_throws BoundsError V[0, 1]
            @test_throws BoundsError V[2, 5]
            @test_throws BoundsError V[3, 1]

            @test length(V) == 6
            @test size(V) == (2,3)

            for T in [IntTypes; pm_Integer]
                V = pm_Matrix{pm_Rational}(jl_m) # local copy
                @test setindex!(V, T(5)//T(3), 1, 1) isa pm_Matrix{pm_Rational}
                @test V[T(1), 1] isa Polymake.pm_RationalAllocated
                @test V[1, T(1)] == 5//3
                # testing the return value of brackets operator
                if T != pm_Integer
                    @test V[2] = T(10)//T(3) isa Rational{T}
                else
                    @test V[2] = T(10)//T(3) isa pm_Rational
                end
                V[2] = T(10)//T(3)
                @test V[2] == 10//3
                @test string(V) == "pm::Matrix<pm::Rational>\n5/3 2 3\n10/3 5 6\n"
            end
        end

        @testset "pm_Matrix{Float64}" begin
            V = pm_Matrix{Float64}(jl_m)
            # linear indexing:
            @test V[1] == 1.0
            @test V[2] == 4.0

            @test eltype(V) == Float64

            @test_throws BoundsError V[0, 1]
            @test_throws BoundsError V[2, 5]
            @test_throws BoundsError V[3, 1]

            @test length(V) == 6
            @test size(V) == (2,3)

            for T in [IntTypes; pm_Integer]
                V = pm_Matrix{Float64}(jl_m) # local copy
                for S in FloatTypes
                    @test setindex!(V, S(5)/T(3), 1, 1) isa pm_Matrix{Float64}
                    @test V[T(1), 1] isa Float64
                    @test V[1, T(1)] ≈ S(5)/T(3)
                    # testing the return value of brackets operator
                    @test V[2] = S(10)/T(3) isa typeof(S(10)/T(3))
                    V[2] = S(10)/T(3)
                    @test V[2] ≈ S(10)/T(3)
                end
                @test string(V) == "pm::Matrix<double>\n1.66667 2 3\n3.33333 5 6\n"
            end
        end

        @testset "Equality" begin
            for T in [IntTypes; pm_Integer]
                V = pm_Matrix{pm_Integer}(2, 3)
                W = pm_Matrix{pm_Rational}(2, 3)
                U = pm_Matrix{Float64}(2, 3)

                @test (V .= T.(jl_m)) isa pm_Matrix{pm_Integer}
                @test (V .= T.(jl_m).//1) isa pm_Matrix{pm_Integer}

                @test (W .= T.(jl_m)) isa pm_Matrix{pm_Rational}
                @test (W .= T.(jl_m).//1) isa pm_Matrix{pm_Rational}

                @test (U .= T.(jl_m)) isa pm_Matrix{Float64}
                @test (U .= T.(jl_m).//1) isa pm_Matrix{Float64}

                @test U == V == W

                # TODO:
                # @test (V .== jl_m) isa BitArray
                # @test all(V .== jl_m)
            end

            V = pm_Matrix{pm_Integer}(jl_m)
            for S in FloatTypes
                U = pm_Matrix{Float64}(2, 3)
                @test (U .= jl_m./S(1)) isa pm_Matrix{Float64}
                @test U == V
            end
        end
    end

    @testset "Arithmetic" begin
        V = pm_Matrix{pm_Integer}(jl_m)
        jl_w = jl_m//4
        W = pm_Matrix{pm_Rational}(jl_w)
        jl_u = jl_m/4
        U = pm_Matrix{Float64}(jl_u)

        @test -V isa Polymake.pm_MatrixAllocated{pm_Integer}
        @test -V == -jl_m

        @test -W isa Polymake.pm_MatrixAllocated{pm_Rational}
        @test -W == -jl_w

        @test -U isa Polymake.pm_MatrixAllocated{Float64}
        @test -U == -jl_u

        int_scalar_types = [IntTypes; pm_Integer]
        rational_scalar_types = [[Rational{T} for T in IntTypes]; pm_Rational]

        for T in int_scalar_types
            for (mat, ElType) in [(V, pm_Integer), (W, pm_Rational), (U, Float64)]
                op = *
                @test op(T(2), mat) isa pm_Matrix{ElType}
                @test op(mat, T(2)) isa pm_Matrix{ElType}
                @test broadcast(op, T(2), mat) isa pm_Matrix{ElType}
                @test broadcast(op, mat, T(2)) isa pm_Matrix{ElType}

                op = +
                @test op(mat, T.(jl_m)) isa pm_Matrix{ElType}
                @test op(T.(jl_m), mat) isa pm_Matrix{ElType}
                @test broadcast(op, mat, T.(jl_m)) isa pm_Matrix{ElType}
                @test broadcast(op, T.(jl_m), mat) isa pm_Matrix{ElType}

                @test broadcast(op, mat, T(2)) isa pm_Matrix{ElType}
                @test broadcast(op, T(2), mat) isa pm_Matrix{ElType}
            end

            let (op, ElType) = (//, pm_Rational)
                for mat in [V, W]

                    @test op(mat, T(2)) isa pm_Matrix{ElType}
                    @test broadcast(op, T(2), mat) isa pm_Matrix{ElType}
                    @test broadcast(op, mat, T(2)) isa pm_Matrix{ElType}
                end
            end
            let (op, ElType) = (/, Float64)
                mat = U
                @test op(mat, T(2)) isa pm_Matrix{ElType}
                @test broadcast(op, T(2), mat) isa pm_Matrix{ElType}
                @test broadcast(op, mat, T(2)) isa pm_Matrix{ElType}
            end
        end

        for T in rational_scalar_types
            for (mat, ElType) in [(V, pm_Rational), (W, pm_Rational), (U, Float64)]

                op = *
                @test op(T(2), mat) isa pm_Matrix{ElType}
                @test op(mat, T(2)) isa pm_Matrix{ElType}
                @test broadcast(op, T(2), mat) isa pm_Matrix{ElType}
                @test broadcast(op, mat, T(2)) isa pm_Matrix{ElType}

                op = +
                @test op(mat, T.(jl_m)) isa pm_Matrix{ElType}
                @test op(T.(jl_m), mat) isa pm_Matrix{ElType}

                @test broadcast(op, mat, T.(jl_m)) isa pm_Matrix{ElType}
                @test broadcast(op, T.(jl_m), mat) isa pm_Matrix{ElType}

                @test broadcast(op, T(2), mat) isa pm_Matrix{ElType}
                @test broadcast(op, mat, T(2)) isa pm_Matrix{ElType}

                if ElType == Float64
                    op = /
                else
                    op = //
                end

                @test op(mat, T(2)) isa pm_Matrix{ElType}
                @test broadcast(op, T(2), mat) isa pm_Matrix{ElType}
                @test broadcast(op, mat, T(2)) isa pm_Matrix{ElType}
            end
        end
        for T in FloatTypes
            let mat = U
                ElType = Float64
                op = *
                @test op(T(2), mat) isa pm_Matrix{ElType}
                @test op(mat, T(2)) isa pm_Matrix{ElType}
                @test broadcast(op, T(2), mat) isa pm_Matrix{ElType}
                @test broadcast(op, mat, T(2)) isa pm_Matrix{ElType}

                op = +
                @test op(mat, T.(jl_m)) isa pm_Matrix{ElType}
                @test op(T.(jl_m), mat) isa pm_Matrix{ElType}

                @test broadcast(op, mat, T.(jl_m)) isa pm_Matrix{ElType}
                @test broadcast(op, T.(jl_m), mat) isa pm_Matrix{ElType}

                @test broadcast(op, T(2), mat) isa pm_Matrix{ElType}
                @test broadcast(op, mat, T(2)) isa pm_Matrix{ElType}

                op = /
                # @test op(T(2), mat) isa pm_Matrix{ElType}
                @test op(mat, T(2)) isa pm_Matrix{ElType}
                @test broadcast(op, T(2), mat) isa pm_Matrix{ElType}
                @test broadcast(op, mat, T(2)) isa pm_Matrix{ElType}
            end
        end

        for T in [int_scalar_types; rational_scalar_types; FloatTypes]
            @test T(2)*V == V*T(2) == T(2) .* V == V .* T(2) == 2jl_m
            @test T(2)*W == W*T(2) == T(2) .* W == W .* T(2) == 2jl_w
            @test T(2)*U == U*T(2) == T(2) .* U == U .* T(2) == 2jl_u

            @test V + T.(jl_m) == T.(jl_m) + V == V .+ T.(jl_m) == T.(jl_m) .+ V == 2jl_m

            @test W + T.(4jl_w) == T.(4jl_w) + W == W .+ T.(4jl_w) == T.(4jl_w) .+ W == 5jl_w

            @test W + T.(4jl_u) == T.(4jl_u) + W == W .+ T.(4jl_u) == T.(4jl_u) .+ W == 5jl_u
        end
    end
end
