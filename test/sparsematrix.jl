using SparseArrays
@testset "Polymake.SparseMatrix" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]
    FloatTypes = [Float32, Float64, BigFloat]

    for T in [Int64, Polymake.Integer, Polymake.Rational, Float64]
        @test Polymake.SparseMatrix{T} <: AbstractSparseMatrix
        @test Polymake.SparseMatrix{T}(3,4) isa AbstractSparseMatrix
        @test Polymake.SparseMatrix{T}(3,4) isa Polymake.SparseMatrix
        @test Polymake.SparseMatrix{T}(3,4) isa Polymake.SparseMatrix{T}
        M = Polymake.SparseMatrix{T}(3,4)
        M[1,1] = 10
        @test M[1,1] isa T
        @test M[1,1] == 10
    end

    jl_m = [1 2 3; 4 5 6]
    jl_s = sparse([0 0 0; 0 1 0])
    @testset "Constructors/Converts" begin
        for T in IntTypes #TODO Polymake.Integer
            @test Polymake.SparseMatrix(T.(jl_m)) isa Polymake.SparseMatrix{T == Int64 ? Int64 : Polymake.Integer}
            @test Polymake.SparseMatrix(jl_m//1) isa Polymake.SparseMatrix{Polymake.Rational}
            @test Polymake.SparseMatrix(jl_m/1) isa Polymake.SparseMatrix{Float64}

            @test Polymake.SparseMatrix(T.(jl_s)) isa Polymake.SparseMatrix{T == Int64 ? Int64 : Polymake.Integer}
            @test Polymake.SparseMatrix(jl_s//1) isa Polymake.SparseMatrix{Polymake.Rational}
            @test Polymake.SparseMatrix(jl_s/1) isa Polymake.SparseMatrix{Float64}

            for ElType in [Polymake.Integer, Polymake.Rational, Float64]
                for m in [jl_m, jl_m//T(1), jl_m/T(1)]
                    @test Polymake.SparseMatrix{ElType}(m) isa Polymake.SparseMatrix{ElType}
                    @test convert(Polymake.SparseMatrix{ElType}, m) isa Polymake.SparseMatrix{ElType}

                    M = Polymake.SparseMatrix(m)
                    @test convert(Base.Matrix{T}, M) isa Base.Matrix{T}
                    @test jl_m == convert(Base.Matrix{T}, M)
                end
                for s in [jl_s, jl_s//T(1), jl_s/T(1)] #TODO
                    @test Polymake.SparseMatrix{ElType}(s) isa Polymake.SparseMatrix{ElType}
                    @test convert(Polymake.SparseMatrix{ElType}, s) isa Polymake.SparseMatrix{ElType}

                    S = Polymake.SparseMatrix(s)
                    # @test convert(SparseArrays.SparseMatrixCSC{T,}, S) isa SparseArrays.SparseMatrixCSC{T}
                    # @test jl_s == convert(SparseArrays.SparseMatrixCSC{T}, S)
                end
            end

            for m in [jl_m, jl_m//T(1), jl_m/T(1), jl_s, jl_s//T(1), jl_s/T(1)]
                M = Polymake.SparseMatrix(m)
                @test Polymake.convert(Polymake.PolymakeType, M) === M
                @test float.(M) isa Polymake.SparseMatrix{Float64}
                @test Float64.(M) isa Polymake.SparseMatrix{Float64}
                @test Base.Matrix{Float64}(M) isa Base.Matrix{Float64}
                @test convert.(Float64, M) isa Polymake.SparseMatrix{Float64}
            end

            let W = Polymake.SparseMatrix{Polymake.Rational}(jl_m)
                for T in [Base.Rational{I} for I in IntTypes]
                    @test convert(Base.Matrix{T}, W) isa Base.Matrix{T}
                    @test jl_m == convert(Base.Matrix{T}, W)
                end
            end

            let W = Polymake.SparseMatrix{Polymake.Rational}(jl_s)
                for T in [Base.Rational{I} for I in IntTypes]
                    @test convert(Base.Matrix{T}, W) isa Base.Matrix{T}
                    @test jl_s == convert(Base.Matrix{T}, W)
                end
            end

            let U = Polymake.SparseMatrix{Float64}(jl_m)
                for T in FloatTypes
                    @test convert(Base.Matrix{T}, U) isa Base.Matrix{T}
                    @test jl_m == convert(Base.Matrix{T}, U)
                end
            end

            let U = Polymake.SparseMatrix{Float64}(jl_s)
                for T in FloatTypes
                    @test convert(Base.Matrix{T}, U) isa Base.Matrix{T}
                    @test jl_s == convert(Base.Matrix{T}, U)
                end
            end
        end
    end

    @testset "Low-level operations" begin
        @testset "Polymake.SparseMatrix{Int64}" begin
            jl_m_32 = Int32.(jl_m)
            V = Polymake.SparseMatrix{Int64}(jl_m_32)
            # linear indexing:
            @test V[1] == 1
            @test V[2] == 4

            @test eltype(V) == Int64

            @test_throws BoundsError V[0, 1]
            @test_throws BoundsError V[2, 5]
            @test_throws BoundsError V[3, 1]

            @test length(V) == 6
            @test size(V) == (2,3)

            for T in [IntTypes; Polymake.Integer]
                V = Polymake.SparseMatrix{Int64}(jl_m_32) # local copy
                setindex!(V, T(5), 1, 1)
                @test V isa Polymake.SparseMatrix{Int64}
                @test V[T(1), 1] isa Int64
                @test V[1, T(1)] == 5
                # testing the return value of brackets operator
                @test V[2, 1] = T(10) isa T
                V[2, 1] = T(10)
                @test V[2, 1] == 10
                @test string(V) == "pm::SparseMatrix<long, pm::NonSymmetric>\n5 2 3\n10 5 6\n"
            end

            @test string(Polymake.SparseMatrix{Int64}(jl_s)) == "pm::SparseMatrix<long, pm::NonSymmetric>\n(3)\n(3) (1 1)\n"
        end

        @testset "Polymake.SparseMatrix{Polymake.Integer}" begin
            V = Polymake.SparseMatrix{Polymake.Integer}(jl_m)
            # linear indexing:
            @test V[1] == 1
            @test V[2] == 4

            @test eltype(V) == Polymake.Integer

            @test_throws BoundsError V[0, 1]
            @test_throws BoundsError V[2, 5]
            @test_throws BoundsError V[3, 1]

            @test length(V) == 6
            @test size(V) == (2,3)

            for T in [IntTypes; Polymake.Integer]
                V = Polymake.SparseMatrix{Polymake.Integer}(jl_m) # local copy
                setindex!(V, T(5), 1, 1)
                @test V isa Polymake.SparseMatrix{Polymake.Integer}
                @test V[T(1), 1] isa Polymake.IntegerAllocated
                @test V[1, T(1)] == 5
                # testing the return value of brackets operator
                @test V[2, 1] = T(10) isa T
                V[2, 1] = T(10)
                @test V[2, 1] == 10
                @test string(V) == "pm::SparseMatrix<pm::Integer, pm::NonSymmetric>\n5 2 3\n10 5 6\n"
            end

            @test string(Polymake.SparseMatrix{Polymake.Integer}(jl_s)) == "pm::SparseMatrix<pm::Integer, pm::NonSymmetric>\n(3)\n(3) (1 1)\n"
        end

        @testset "Polymake.SparseMatrix{Polymake.Rational}" begin
            V = Polymake.SparseMatrix{Polymake.Rational}(jl_m)
            # linear indexing:
            @test V[1] == 1//1
            @test V[2] == 4//1

            @test eltype(V) == Polymake.Rational

            @test_throws BoundsError V[0, 1]
            @test_throws BoundsError V[2, 5]
            @test_throws BoundsError V[3, 1]

            @test length(V) == 6
            @test size(V) == (2,3)

            for T in [IntTypes; Polymake.Integer]
                V = Polymake.SparseMatrix{Polymake.Rational}(jl_m) # local copy
                setindex!(V, T(5)//T(3), 1, 1)
                @test V isa Polymake.SparseMatrix{Polymake.Rational}
                @test V[T(1), 1] isa Polymake.RationalAllocated
                @test V[1, T(1)] == 5//3
                # testing the return value of brackets operator
                if T != Polymake.Integer
                    @test V[2] = T(10)//T(3) isa Base.Rational{T}
                else
                    @test V[2] = T(10)//T(3) isa Polymake.Rational
                end
                V[2] = T(10)//T(3)
                @test V[2] == 10//3
                @test string(V) == "pm::SparseMatrix<pm::Rational, pm::NonSymmetric>\n5/3 2 3\n10/3 5 6\n"
            end

            @test string(Polymake.SparseMatrix{Polymake.Rational}(jl_s)) == "pm::SparseMatrix<pm::Rational, pm::NonSymmetric>\n(3)\n(3) (1 1)\n"
        end

        @testset "Polymake.SparseMatrix{Float64}" begin
            V = Polymake.SparseMatrix{Float64}(jl_m)
            # linear indexing:
            @test V[1] == 1.0
            @test V[2] == 4.0

            @test eltype(V) == Float64

            @test_throws BoundsError V[0, 1]
            @test_throws BoundsError V[2, 5]
            @test_throws BoundsError V[3, 1]

            @test length(V) == 6
            @test size(V) == (2,3)

            for T in [IntTypes; Polymake.Integer]
                V = Polymake.SparseMatrix{Float64}(jl_m) # local copy
                for S in FloatTypes
                    setindex!(V, S(5)/T(3), 1, 1)
                    @test V isa Polymake.SparseMatrix{Float64}
                    @test V[T(1), 1] isa Float64
                    @test V[1, T(1)] ≈ S(5)/T(3)
                    # testing the return value of brackets operator
                    @test V[2] = S(10)/T(3) isa typeof(S(10)/T(3))
                    V[2] = S(10)/T(3)
                    @test V[2] ≈ S(10)/T(3)
                end
                @test string(V) == "pm::SparseMatrix<double, pm::NonSymmetric>\n1.66667 2 3\n3.33333 5 6\n"
            end

            @test string(Polymake.SparseMatrix{Float64}(jl_s)) == "pm::SparseMatrix<double, pm::NonSymmetric>\n(3)\n(3) (1 1)\n"
        end

        @testset "Equality" begin
            for T in [IntTypes; Polymake.Integer]
                V = Polymake.SparseMatrix{Polymake.Integer}(2, 3)
                W = Polymake.SparseMatrix{Polymake.Rational}(2, 3)
                U = Polymake.SparseMatrix{Float64}(2, 3)

                #TODO T.(jl_s)
                @test (V .= T.(jl_m)) isa Polymake.SparseMatrix{Polymake.Integer}
                @test (V .= T.(jl_m).//1) isa Polymake.SparseMatrix{Polymake.Integer}

                @test (W .= T.(jl_m)) isa Polymake.SparseMatrix{Polymake.Rational}
                @test (W .= T.(jl_m).//1) isa Polymake.SparseMatrix{Polymake.Rational}

                @test (U .= T.(jl_m)) isa Polymake.SparseMatrix{Float64}
                @test (U .= T.(jl_m).//1) isa Polymake.SparseMatrix{Float64}

                @test U == V == W

                # TODO:
                # @test (V .== jl_m) isa BitPolymake.Array
                # @test all(V .== jl_m)
            end

            V = Polymake.SparseMatrix{Polymake.Integer}(jl_m)
            for S in FloatTypes
                U = Polymake.SparseMatrix{Float64}(2, 3)
                @test (U .= jl_m./S(1)) isa Polymake.SparseMatrix{Float64}
                @test U == V
            end
        end
    end

    @testset "Arithmetic" begin
        V = Polymake.SparseMatrix{Polymake.Integer}(jl_m)
        @test float.(V) isa Polymake.SparseMatrixAllocated{Float64}
        # @test V[1, :] isa Polymake.SparseVectorAllocated{Polymake.Integer}
        # @test float.(V)[1, :] isa SparseVector{Float64}

        @test similar(V, Float64) isa Polymake.SparseMatrixAllocated{Float64}
        # @test similar(V, Float64, 10) isa Polymake.SparseVectorAllocated{Float64}
        @test similar(V, Float64, 10, 10) isa Polymake.SparseMatrixAllocated{Float64}

        X = Polymake.SparseMatrix{Int64}(jl_m)
        V = Polymake.SparseMatrix{Polymake.Integer}(jl_m)
        jl_w = jl_m//4
        W = Polymake.SparseMatrix{Polymake.Rational}(jl_w)
        jl_u = jl_m/4
        U = Polymake.SparseMatrix{Float64}(jl_u)

        @test -X isa Polymake.SparseMatrixAllocated{Int64}
        @test -X == -jl_m

        @test -V isa Polymake.SparseMatrixAllocated{Polymake.Integer}
        @test -V == -jl_m

        @test -W isa Polymake.SparseMatrixAllocated{Polymake.Rational}
        @test -W == -jl_w

        @test -U isa Polymake.SparseMatrixAllocated{Float64}
        @test -U == -jl_u

        int_scalar_types = [IntTypes; Polymake.Integer]
        rational_scalar_types = [[Base.Rational{T} for T in IntTypes]; Polymake.Rational]

        @test 2X isa Polymake.SparseMatrix{Polymake.Int64}
        @test Int32(2)X isa Polymake.SparseMatrix{Int64}

        for T in int_scalar_types
            for (mat, ElType) in [(V, Polymake.Integer), (W, Polymake.Rational), (U, Float64)]
                op = *
                @test op(T(2), mat) isa Polymake.SparseMatrix{ElType}
                @test op(mat, T(2)) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, T(2), mat) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, mat, T(2)) isa Polymake.SparseMatrix{ElType}

                op = +
                @test op(mat, T.(jl_m)) isa Polymake.SparseMatrix{ElType}
                @test op(T.(jl_m), mat) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, mat, T.(jl_m)) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, T.(jl_m), mat) isa Polymake.SparseMatrix{ElType}

                @test broadcast(op, mat, T(2)) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, T(2), mat) isa Polymake.SparseMatrix{ElType}
            end

            let (op, ElType) = (//, Polymake.Rational)
                for mat in [V, W]

                    @test op(mat, T(2)) isa Polymake.SparseMatrix{ElType}
                    @test broadcast(op, T(2), mat) isa Polymake.SparseMatrix{ElType}
                    @test broadcast(op, mat, T(2)) isa Polymake.SparseMatrix{ElType}
                end
            end
            let (op, ElType) = (/, Float64)
                mat = U
                @test op(mat, T(2)) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, T(2), mat) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, mat, T(2)) isa Polymake.SparseMatrix{ElType}
            end
        end

        for T in rational_scalar_types
            for (mat, ElType) in [(V, Polymake.Rational), (W, Polymake.Rational), (U, Float64)]

                op = *
                @test op(T(2), mat) isa Polymake.SparseMatrix{ElType}
                @test op(mat, T(2)) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, T(2), mat) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, mat, T(2)) isa Polymake.SparseMatrix{ElType}

                op = +
                @test op(mat, T.(jl_m)) isa Polymake.SparseMatrix{ElType}
                @test op(T.(jl_m), mat) isa Polymake.SparseMatrix{ElType}

                @test broadcast(op, mat, T.(jl_m)) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, T.(jl_m), mat) isa Polymake.SparseMatrix{ElType}

                @test broadcast(op, T(2), mat) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, mat, T(2)) isa Polymake.SparseMatrix{ElType}

                if ElType == Float64
                    op = /
                else
                    op = //
                end

                @test op(mat, T(2)) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, T(2), mat) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, mat, T(2)) isa Polymake.SparseMatrix{ElType}
            end
        end
        for T in FloatTypes
            let mat = U, ElType = Float64
                op = *
                @test op(T(2), mat) isa Polymake.SparseMatrix{ElType}
                @test op(mat, T(2)) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, T(2), mat) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, mat, T(2)) isa Polymake.SparseMatrix{ElType}

                op = +
                @test op(mat, T.(jl_m)) isa Polymake.SparseMatrix{ElType}
                @test op(T.(jl_m), mat) isa Polymake.SparseMatrix{ElType}

                @test broadcast(op, mat, T.(jl_m)) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, T.(jl_m), mat) isa Polymake.SparseMatrix{ElType}

                @test broadcast(op, T(2), mat) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, mat, T(2)) isa Polymake.SparseMatrix{ElType}

                op = /
                # @test op(T(2), mat) isa Polymake.Matrix{ElType}
                @test op(mat, T(2)) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, T(2), mat) isa Polymake.SparseMatrix{ElType}
                @test broadcast(op, mat, T(2)) isa Polymake.SparseMatrix{ElType}
            end
        end

        for T in [int_scalar_types; rational_scalar_types; FloatTypes]
            @test T(2)*X == X*T(2) == T(2) .* X == X .* T(2) == 2jl_m
            @test T(2)*V == V*T(2) == T(2) .* V == V .* T(2) == 2jl_m
            @test T(2)*W == W*T(2) == T(2) .* W == W .* T(2) == 2jl_w
            @test T(2)*U == U*T(2) == T(2) .* U == U .* T(2) == 2jl_u

            @test X + T.(jl_m) == T.(jl_m) + X == X .+ T.(jl_m) == T.(jl_m) .+ X == 2jl_m

            @test V + T.(jl_m) == T.(jl_m) + V == V .+ T.(jl_m) == T.(jl_m) .+ V == 2jl_m

            @test W + T.(4jl_w) == T.(4jl_w) + W == W .+ T.(4jl_w) == T.(4jl_w) .+ W == 5jl_w

            @test U + T.(4jl_u) == T.(4jl_u) + U == U .+ T.(4jl_u) == T.(4jl_u) .+ U == 5jl_u
        end
    end

    @testset "findnz" begin
        jsm = sprand(1015,1841,.14)
        psm = Polymake.SparseMatrix(jsm)
        jr, jc, jv = findnz(jsm)
        pr, pc, pv = findnz(psm)
        p = sortperm(pc)
        @test jr == pr[p]
        @test jc == pc[p]
        @test jv == pv[p]
    end
end
