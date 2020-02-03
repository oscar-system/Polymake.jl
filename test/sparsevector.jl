using SparseArrays
@testset "SparseMatrix" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]
    FloatTypes = [Float32, Float64, BigFloat]

    for T in [Int32, Integer, Rational, Float64]
        @test SparseVector{T} <: AbstractSparseVector
        @test SparseVector{T}(3) isa AbstractSparseVector
        @test SparseVector{T}(3) isa SparseVector
        @test SparseVector{T}(3) isa SparseVector{T}
        V = SparseVector{T}(4)
        V[1] = 10
        V[end] = 4
        @test V[1] isa T
        @test V[1] == 10
        @test V[end] isa T
        @test V[end] == 4
    end

    jl_v = [1, 2, 3]
    jl_s = sparsevec([0 1 0])
    @testset "Constructors/Converts" begin
        for T in IntTypes #TODO Integer
            @test SparseVector(T.(jl_v)) isa SparseVector{T == Int32 ? Int32 : Integer}
            @test SparseVector(jl_v//1) isa SparseVector{Rational}
            @test SparseVector(jl_v/1) isa SparseVector{Float64}

            @test SparseVector(T.(jl_s)) isa SparseVector{T == Int32 ? Int32 : Integer}
            @test SparseVector(jl_s//1) isa SparseVector{Rational}
            @test SparseVector(jl_s/1) isa SparseVector{Float64}

            for ElType in [Integer, Rational, Float64]
                for v in [jl_v, jl_v//T(1), jl_v/T(1)]
                    @test SparseVector{ElType}(v) isa SparseVector{ElType}
                    @test convert(SparseVector{ElType}, v) isa SparseVector{ElType}

                    V = SparseVector(v)
                    @test convert(Vector{T}, V) isa Vector{T}
                    @test jl_v == convert(Vector{T}, V)
                end
                for s in [jl_s, jl_s//T(1), jl_s/T(1)] #TODO
                    @test SparseVector{ElType}(s) isa SparseVector{ElType}
                    @test convert(SparseVector{ElType}, s) isa SparseVector{ElType}

                    S = SparseVector(s)
                    # @test convert(SparseArrays.SparseMatrixCSC{T,}, S) isa SparseArrays.SparseMatrixCSC{T}
                    # @test jl_s == convert(SparseArrays.SparseMatrixCSC{T}, S)
                end
            end

            for v in [jl_v, jl_v//T(1), jl_v/T(1), jl_s, jl_s//T(1), jl_s/T(1)]
                V = SparseVector(v)
                @test Polymake.convert(Polymake.PolymakeType, V) === V
                @test float.(V) isa SparseVector{Float64}
                @test Float64.(V) isa SparseVector{Float64}
                @test Vector{Float64}(V) isa Vector{Float64}
                @test convert.(Float64, V) isa SparseVector{Float64}
            end

            let W = SparseVector{Rational}(jl_v)
                for T in [Rational{I} for I in IntTypes]
                    @test convert(Vector{T}, W) isa Vector{T}
                    @test jl_v == convert(Vector{T}, W)
                end
            end

            let W = SparseVector{Rational}(jl_s)
                for T in [Rational{I} for I in IntTypes]
                    @test convert(Vector{T}, W) isa Vector{T}
                    @test jl_s == convert(Vector{T}, W)
                end
            end

            let U = SparseVector{Float64}(jl_v)
                for T in FloatTypes
                    @test convert(Vector{T}, U) isa Vector{T}
                    @test jl_v == convert(Vector{T}, U)
                end
            end

            let U = SparseVector{Float64}(jl_s)
                for T in FloatTypes
                    @test convert(Vector{T}, U) isa Vector{T}
                    @test jl_s == convert(Vector{T}, U)
                end
            end
        end
    end
    #
    # @testset "Low-level operations" begin
    #     @testset "SparseMatrix{Int32}" begin
    #         jl_m_32 = Int32.(jl_m)
    #         V = SparseMatrix{Int32}(jl_m_32)
    #         # linear indexing:
    #         @test V[1] == 1
    #         @test V[2] == 4
    #
    #         @test eltype(V) == Int32
    #
    #         @test_throws BoundsError V[0, 1]
    #         @test_throws BoundsError V[2, 5]
    #         @test_throws BoundsError V[3, 1]
    #
    #         @test length(V) == 6
    #         @test size(V) == (2,3)
    #
    #         for T in [IntTypes; Integer]
    #             V = SparseMatrix{Int32}(jl_m_32) # local copy
    #             setindex!(V, T(5), 1, 1)
    #             @test V isa SparseMatrix{Int32}
    #             @test V[T(1), 1] isa Int32
    #             @test V[1, T(1)] == 5
    #             # testing the return value of brackets operator
    #             @test V[2, 1] = T(10) isa T
    #             V[2, 1] = T(10)
    #             @test V[2, 1] == 10
    #             @test string(V) == "pm::SparseMatrix<int, pm::NonSymmetric>\n5 2 3\n10 5 6\n"
    #         end
    #
    #         @test string(SparseMatrix{Int32}(jl_s)) == "pm::SparseMatrix<int, pm::NonSymmetric>\n(3)\n(3) (1 1)\n"
    #     end
    #
    #     @testset "SparseMatrix{Integer}" begin
    #         V = SparseMatrix{Integer}(jl_m)
    #         # linear indexing:
    #         @test V[1] == 1
    #         @test V[2] == 4
    #
    #         @test eltype(V) == Integer
    #
    #         @test_throws BoundsError V[0, 1]
    #         @test_throws BoundsError V[2, 5]
    #         @test_throws BoundsError V[3, 1]
    #
    #         @test length(V) == 6
    #         @test size(V) == (2,3)
    #
    #         for T in [IntTypes; Integer]
    #             V = SparseMatrix{Integer}(jl_m) # local copy
    #             setindex!(V, T(5), 1, 1)
    #             @test V isa SparseMatrix{Integer}
    #             @test V[T(1), 1] isa Polymake.IntegerAllocated
    #             @test V[1, T(1)] == 5
    #             # testing the return value of brackets operator
    #             @test V[2, 1] = T(10) isa T
    #             V[2, 1] = T(10)
    #             @test V[2, 1] == 10
    #             @test string(V) == "pm::SparseMatrix<pm::Integer, pm::NonSymmetric>\n5 2 3\n10 5 6\n"
    #         end
    #
    #         @test string(SparseMatrix{Integer}(jl_s)) == "pm::SparseMatrix<pm::Integer, pm::NonSymmetric>\n(3)\n(3) (1 1)\n"
    #     end
    #
    #     @testset "SparseMatrix{Rational}" begin
    #         V = SparseMatrix{Rational}(jl_m)
    #         # linear indexing:
    #         @test V[1] == 1//1
    #         @test V[2] == 4//1
    #
    #         @test eltype(V) == Rational
    #
    #         @test_throws BoundsError V[0, 1]
    #         @test_throws BoundsError V[2, 5]
    #         @test_throws BoundsError V[3, 1]
    #
    #         @test length(V) == 6
    #         @test size(V) == (2,3)
    #
    #         for T in [IntTypes; Integer]
    #             V = SparseMatrix{Rational}(jl_m) # local copy
    #             setindex!(V, T(5)//T(3), 1, 1)
    #             @test V isa SparseMatrix{Rational}
    #             @test V[T(1), 1] isa Polymake.RationalAllocated
    #             @test V[1, T(1)] == 5//3
    #             # testing the return value of brackets operator
    #             if T != Integer
    #                 @test V[2] = T(10)//T(3) isa Rational{T}
    #             else
    #                 @test V[2] = T(10)//T(3) isa Rational
    #             end
    #             V[2] = T(10)//T(3)
    #             @test V[2] == 10//3
    #             @test string(V) == "pm::SparseMatrix<pm::Rational, pm::NonSymmetric>\n5/3 2 3\n10/3 5 6\n"
    #         end
    #
    #         @test string(SparseMatrix{Rational}(jl_s)) == "pm::SparseMatrix<pm::Rational, pm::NonSymmetric>\n(3)\n(3) (1 1)\n"
    #     end
    #
    #     @testset "SparseMatrix{Float64}" begin
    #         V = SparseMatrix{Float64}(jl_m)
    #         # linear indexing:
    #         @test V[1] == 1.0
    #         @test V[2] == 4.0
    #
    #         @test eltype(V) == Float64
    #
    #         @test_throws BoundsError V[0, 1]
    #         @test_throws BoundsError V[2, 5]
    #         @test_throws BoundsError V[3, 1]
    #
    #         @test length(V) == 6
    #         @test size(V) == (2,3)
    #
    #         for T in [IntTypes; Integer]
    #             V = SparseMatrix{Float64}(jl_m) # local copy
    #             for S in FloatTypes
    #                 setindex!(V, S(5)/T(3), 1, 1)
    #                 @test V isa SparseMatrix{Float64}
    #                 @test V[T(1), 1] isa Float64
    #                 @test V[1, T(1)] ≈ S(5)/T(3)
    #                 # testing the return value of brackets operator
    #                 @test V[2] = S(10)/T(3) isa typeof(S(10)/T(3))
    #                 V[2] = S(10)/T(3)
    #                 @test V[2] ≈ S(10)/T(3)
    #             end
    #             @test string(V) == "pm::SparseMatrix<double, pm::NonSymmetric>\n1.66667 2 3\n3.33333 5 6\n"
    #         end
    #
    #         @test string(SparseMatrix{Float64}(jl_s)) == "pm::SparseMatrix<double, pm::NonSymmetric>\n(3)\n(3) (1 1)\n"
    #     end
    #
    #     @testset "Equality" begin
    #         for T in [IntTypes; Integer]
    #             V = SparseMatrix{Integer}(2, 3)
    #             W = SparseMatrix{Rational}(2, 3)
    #             U = SparseMatrix{Float64}(2, 3)
    #
    #             #TODO T.(jl_s)
    #             @test (V .= T.(jl_m)) isa SparseMatrix{Integer}
    #             @test (V .= T.(jl_m).//1) isa SparseMatrix{Integer}
    #
    #             @test (W .= T.(jl_m)) isa SparseMatrix{Rational}
    #             @test (W .= T.(jl_m).//1) isa SparseMatrix{Rational}
    #
    #             @test (U .= T.(jl_m)) isa SparseMatrix{Float64}
    #             @test (U .= T.(jl_m).//1) isa SparseMatrix{Float64}
    #
    #             @test U == V == W
    #
    #             # TODO:
    #             # @test (V .== jl_m) isa BitArray
    #             # @test all(V .== jl_m)
    #         end
    #
    #         V = SparseMatrix{Integer}(jl_m)
    #         for S in FloatTypes
    #             U = SparseMatrix{Float64}(2, 3)
    #             @test (U .= jl_m./S(1)) isa SparseMatrix{Float64}
    #             @test U == V
    #         end
    #     end
    # end
    #
    # @testset "Arithmetic" begin
    #     V = SparseMatrix{Integer}(jl_m)
    #     @test float.(V) isa Polymake.SparseMatrixAllocated{Float64}
    #     # @test V[1, :] isa Polymake.SparseVectorAllocated{Integer}
    #     # @test float.(V)[1, :] isa SparseVector{Float64}
    #
    #     @test similar(V, Float64) isa Polymake.SparseMatrixAllocated{Float64}
    #     # @test similar(V, Float64, 10) isa Polymake.SparseVectorAllocated{Float64}
    #     @test similar(V, Float64, 10, 10) isa Polymake.SparseMatrixAllocated{Float64}
    #
    #     X = SparseMatrix{Int32}(jl_m)
    #     V = SparseMatrix{Integer}(jl_m)
    #     jl_w = jl_m//4
    #     W = SparseMatrix{Rational}(jl_w)
    #     jl_u = jl_m/4
    #     U = SparseMatrix{Float64}(jl_u)
    #
    #     @test -X isa Polymake.SparseMatrixAllocated{Int32}
    #     @test -X == -jl_m
    #
    #     @test -V isa Polymake.SparseMatrixAllocated{Integer}
    #     @test -V == -jl_m
    #
    #     @test -W isa Polymake.SparseMatrixAllocated{Rational}
    #     @test -W == -jl_w
    #
    #     @test -U isa Polymake.SparseMatrixAllocated{Float64}
    #     @test -U == -jl_u
    #
    #     int_scalar_types = [IntTypes; Integer]
    #     rational_scalar_types = [[Rational{T} for T in IntTypes]; Rational]
    #
    #     @test 2X isa SparseMatrix{Integer}
    #     @test Int32(2)X isa SparseMatrix{Int32}
    #
    #     for T in int_scalar_types
    #         for (mat, ElType) in [(V, Integer), (W, Rational), (U, Float64)]
    #             op = *
    #             @test op(T(2), mat) isa SparseMatrix{ElType}
    #             @test op(mat, T(2)) isa SparseMatrix{ElType}
    #             @test broadcast(op, T(2), mat) isa SparseMatrix{ElType}
    #             @test broadcast(op, mat, T(2)) isa SparseMatrix{ElType}
    #
    #             op = +
    #             @test op(mat, T.(jl_m)) isa SparseMatrix{ElType}
    #             @test op(T.(jl_m), mat) isa SparseMatrix{ElType}
    #             @test broadcast(op, mat, T.(jl_m)) isa SparseMatrix{ElType}
    #             @test broadcast(op, T.(jl_m), mat) isa SparseMatrix{ElType}
    #
    #             @test broadcast(op, mat, T(2)) isa SparseMatrix{ElType}
    #             @test broadcast(op, T(2), mat) isa SparseMatrix{ElType}
    #         end
    #
    #         let (op, ElType) = (//, Rational)
    #             for mat in [V, W]
    #
    #                 @test op(mat, T(2)) isa SparseMatrix{ElType}
    #                 @test broadcast(op, T(2), mat) isa SparseMatrix{ElType}
    #                 @test broadcast(op, mat, T(2)) isa SparseMatrix{ElType}
    #             end
    #         end
    #         let (op, ElType) = (/, Float64)
    #             mat = U
    #             @test op(mat, T(2)) isa SparseMatrix{ElType}
    #             @test broadcast(op, T(2), mat) isa SparseMatrix{ElType}
    #             @test broadcast(op, mat, T(2)) isa SparseMatrix{ElType}
    #         end
    #     end
    #
    #     for T in rational_scalar_types
    #         for (mat, ElType) in [(V, Rational), (W, Rational), (U, Float64)]
    #
    #             op = *
    #             @test op(T(2), mat) isa SparseMatrix{ElType}
    #             @test op(mat, T(2)) isa SparseMatrix{ElType}
    #             @test broadcast(op, T(2), mat) isa SparseMatrix{ElType}
    #             @test broadcast(op, mat, T(2)) isa SparseMatrix{ElType}
    #
    #             op = +
    #             @test op(mat, T.(jl_m)) isa SparseMatrix{ElType}
    #             @test op(T.(jl_m), mat) isa SparseMatrix{ElType}
    #
    #             @test broadcast(op, mat, T.(jl_m)) isa SparseMatrix{ElType}
    #             @test broadcast(op, T.(jl_m), mat) isa SparseMatrix{ElType}
    #
    #             @test broadcast(op, T(2), mat) isa SparseMatrix{ElType}
    #             @test broadcast(op, mat, T(2)) isa SparseMatrix{ElType}
    #
    #             if ElType == Float64
    #                 op = /
    #             else
    #                 op = //
    #             end
    #
    #             @test op(mat, T(2)) isa SparseMatrix{ElType}
    #             @test broadcast(op, T(2), mat) isa SparseMatrix{ElType}
    #             @test broadcast(op, mat, T(2)) isa SparseMatrix{ElType}
    #         end
    #     end
    #     for T in FloatTypes
    #         let mat = U, ElType = Float64
    #             op = *
    #             @test op(T(2), mat) isa SparseMatrix{ElType}
    #             @test op(mat, T(2)) isa SparseMatrix{ElType}
    #             @test broadcast(op, T(2), mat) isa SparseMatrix{ElType}
    #             @test broadcast(op, mat, T(2)) isa SparseMatrix{ElType}
    #
    #             op = +
    #             @test op(mat, T.(jl_m)) isa SparseMatrix{ElType}
    #             @test op(T.(jl_m), mat) isa SparseMatrix{ElType}
    #
    #             @test broadcast(op, mat, T.(jl_m)) isa SparseMatrix{ElType}
    #             @test broadcast(op, T.(jl_m), mat) isa SparseMatrix{ElType}
    #
    #             @test broadcast(op, T(2), mat) isa SparseMatrix{ElType}
    #             @test broadcast(op, mat, T(2)) isa SparseMatrix{ElType}
    #
    #             op = /
    #             # @test op(T(2), mat) isa Matrix{ElType}
    #             @test op(mat, T(2)) isa SparseMatrix{ElType}
    #             @test broadcast(op, T(2), mat) isa SparseMatrix{ElType}
    #             @test broadcast(op, mat, T(2)) isa SparseMatrix{ElType}
    #         end
    #     end
    #
    #     for T in [int_scalar_types; rational_scalar_types; FloatTypes]
    #         @test T(2)*X == X*T(2) == T(2) .* X == X .* T(2) == 2jl_m
    #         @test T(2)*V == V*T(2) == T(2) .* V == V .* T(2) == 2jl_m
    #         @test T(2)*W == W*T(2) == T(2) .* W == W .* T(2) == 2jl_w
    #         @test T(2)*U == U*T(2) == T(2) .* U == U .* T(2) == 2jl_u
    #
    #         @test X + T.(jl_m) == T.(jl_m) + X == X .+ T.(jl_m) == T.(jl_m) .+ X == 2jl_m
    #
    #         @test V + T.(jl_m) == T.(jl_m) + V == V .+ T.(jl_m) == T.(jl_m) .+ V == 2jl_m
    #
    #         @test W + T.(4jl_w) == T.(4jl_w) + W == W .+ T.(4jl_w) == T.(4jl_w) .+ W == 5jl_w
    #
    #         @test U + T.(4jl_u) == T.(4jl_u) + U == U .+ T.(4jl_u) == T.(4jl_u) .+ U == 5jl_u
    #     end
    # end
    #
    # @testset "findnz" begin
    #     jsm = sprand(1015,1841,.14)
    #     psm = SparseMatrix(jsm)
    #     jr, jc, jv = findnz(jsm)
    #     pr, pc, pv = findnz(psm)
    #     p = sortperm(pc)
    #     @test jr == pr[p]
    #     @test jc == pc[p]
    #     @test jv == pv[p]
    # end
end
