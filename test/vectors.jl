@testset "pm_Vector" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]
    FloatTypes = [Float32, Float64, BigFloat]

    for T in [Int32, pm_Integer, pm_Rational, Float64]
        @test pm_Vector{T} <: AbstractVector
        @test pm_Vector{T}(3) isa AbstractVector
        @test pm_Vector{T}(3) isa pm_Vector
        @test pm_Vector{T}(3) isa pm_Vector{T}
        V = pm_Vector{T}(4)
        V[1] = 10
        V[end] = 4
        @test V[1] isa T
        @test V[1] == 10
        @test V[end] isa T
        @test V[end] == 4
    end

    jl_v = [1,2,3]
    @testset "Constructors/Converts" begin
        @test pm_Vector(jl_v//1) isa pm_Vector{pm_Rational}
        @test pm_Vector(jl_v/1) isa pm_Vector{Float64}

        for T in [IntTypes; pm_Integer]
            @test pm_Vector(T.(jl_v)) isa pm_Vector{T == Int32 ? Int32 : pm_Integer}

            for ElType in [pm_Integer, pm_Rational, Float64]
                for v in [jl_v, jl_v//T(1), jl_v/T(1)]
                    @test pm_Vector{ElType}(v) isa pm_Vector{ElType}
                    @test convert(pm_Vector{ElType}, v) isa pm_Vector{ElType}

                    V = pm_Vector(v)
                    @test convert(Vector{T}, V) isa Vector{T}
                    @test jl_v == convert(Vector{T}, V)
                end
            end

            for v in [jl_v, jl_v//T(1), jl_v/T(1)]
                V = pm_Vector(v)
                @test Polymake.convert(Polymake.PolymakeType, V) === V
                @test float.(V) isa pm_Vector{Float64}
                @test Float64.(V) isa pm_Vector{Float64}
                @test Vector{Float64}(V) isa Vector{Float64}
                @test convert.(Float64, V) isa pm_Vector{Float64}
            end

            let W = pm_Vector{pm_Rational}(jl_v)
                for T in [Rational{I} for I in IntTypes]
                    @test convert(Vector{T}, W) isa Vector{T}
                    @test jl_v == convert(Vector{T}, W)
                end
            end

            let U = pm_Vector{Float64}(jl_v)
                for T in FloatTypes
                    @test convert(Vector{T}, U) isa Vector{T}
                    @test jl_v == convert(Vector{T}, U)
                end
            end
        end
    end

    @testset "Low-level operations" begin

        @testset "pm_Vector{Int32}" begin
            jl_v_32 = Int32.(jl_v)
            @test pm_Vector(jl_v_32) isa pm_Vector{Int32}
            V = pm_Vector{Int32}(jl_v_32)

            @test eltype(V) == Int32

            @test_throws BoundsError V[0]
            @test_throws BoundsError V[5]
            @test length(V) == 3
            @test size(V) == (3,)

            for T in [IntTypes; pm_Integer]
                V = pm_Vector{Int32}(jl_v_32) # local copy
                @test setindex!(V, T(5), 1) isa pm_Vector{Int32}
                @test V[T(1)] isa Int32
                @test V[T(1)] == 5
                # testing the return value of brackets operator
                @test V[2] = T(10) isa T
                V[2] = T(10)
                @test V[2] == 10
                @test string(V) == "pm::Vector<int>\n5 10 3"
            end
        end

        @testset "pm_Vector{pm_Integer}" begin
            V = pm_Vector{pm_Integer}(jl_v)

            @test eltype(V) == pm_Integer

            @test_throws BoundsError V[0]
            @test_throws BoundsError V[5]

            @test length(V) == 3
            @test size(V) == (3,)

            for T in [IntTypes; pm_Integer]
                V = pm_Vector{pm_Integer}(jl_v) # local copy
                @test setindex!(V, T(5), 1) isa pm_Vector{pm_Integer}
                @test V[T(1)] isa Polymake.pm_IntegerAllocated
                @test V[T(1)] == 5
                # testing the return value of brackets operator
                @test V[2] = T(10) isa T
                V[2] = T(10)
                @test V[2] == 10
                @test string(V) == "pm::Vector<pm::Integer>\n5 10 3"
            end
        end

        @testset "pm_Vector{pm_Rational}" begin
            V = pm_Vector{pm_Rational}(jl_v)

            @test eltype(V) == pm_Rational

            @test_throws BoundsError V[0]
            @test_throws BoundsError V[5]

            @test length(V) == 3
            @test size(V) == (3,)

            for T in [IntTypes; pm_Integer]
                @test setindex!(V, T(5)//T(3), 1) isa pm_Vector{pm_Rational}
                @test V[T(1)] isa Polymake.pm_RationalAllocated
                @test V[T(1)] == 5//3
                # testing the return value of brackets operator
                if T != pm_Integer
                    @test V[2] = T(10)//T(3) isa Rational{T}
                else
                    @test V[2] = T(10)//T(3) isa pm_Rational
                end
                V[2] = T(10)//T(3)
                @test V[2] == 10//3
                @test string(V) == "pm::Vector<pm::Rational>\n5/3 10/3 3"
            end
        end

        @testset "pm_Vector{Float64}" begin
            V = pm_Vector{Float64}(jl_v)

            @test eltype(V) == Float64

            @test_throws BoundsError V[0]
            @test_throws BoundsError V[5]

            @test length(V) == 3
            @test size(V) == (3,)

            for T in [IntTypes; pm_Integer]
                @test setindex!(V, T(5)//T(3), 1) isa pm_Vector{Float64}
                @test V[T(1)] isa Float64
                @test V[T(1)] ≈ 5/3
                # testing the return value of brackets operator
                @test V[2] = T(10)/T(3) isa typeof(T(10)/T(3))
                V[2] = T(10)//T(3)
                @test V[2] ≈ 10/3
                @test string(V) == "pm::Vector<double>\n1.66667 3.33333 3"
            end
        end

        @testset "Equality" begin
            X = pm_Vector{Int32}(3)
            V = pm_Vector{pm_Integer}(3)
            W = pm_Vector{pm_Rational}(3)
            U = pm_Vector{Float64}(3)

            for T in [IntTypes; pm_Integer]
                @test (X .= T.(jl_v)) isa pm_Vector{Int32}
                @test (X .= T.(jl_v).//1) isa pm_Vector{Int32}

                @test (V .= T.(jl_v)) isa pm_Vector{pm_Integer}
                @test (V .= T.(jl_v).//1) isa pm_Vector{pm_Integer}

                @test (W .= T.(jl_v)) isa pm_Vector{pm_Rational}
                @test (W .= T.(jl_v).//1) isa pm_Vector{pm_Rational}

                @test (U .= T.(jl_v)) isa pm_Vector{Float64}
                @test (U .= T.(jl_v).//1) isa pm_Vector{Float64}

                @test X == U == V == W

                # TODO:
                # @test (V .== jl_v) isa BitArray
                # @test all(V .== jl_v)
            end

            V = pm_Vector{pm_Integer}(jl_v)
            for S in FloatTypes
                U = pm_Vector{Float64}(3)
                @test (U .= jl_v./S(1)) isa pm_Vector{Float64}
                @test U == V
            end
        end
    end

    @testset "Arithmetic" begin
        X = pm_Vector{Int32}(jl_v)
        V = pm_Vector{pm_Integer}(jl_v)
        jl_w = jl_v//4
        W = pm_Vector{pm_Rational}(jl_w)
        jl_u = jl_v/4
        U = pm_Vector{Float64}(jl_u)

        @test similar(V, Float64) isa Polymake.pm_VectorAllocated{Float64}
        @test similar(V, Float64, 10) isa Polymake.pm_VectorAllocated{Float64}

        @test sin.(V) isa pm_Vector{Float64}

        @test float.(V) isa Polymake.pm_VectorAllocated{Float64}

        @test -X isa Polymake.pm_VectorAllocated{Int32}
        @test -X == -jl_v

        @test -V isa Polymake.pm_VectorAllocated{pm_Integer}
        @test -V == -jl_v

        @test -W isa Polymake.pm_VectorAllocated{pm_Rational}
        @test -W == -jl_w

        @test -U isa Polymake.pm_VectorAllocated{Float64}
        @test -U == -jl_u

        int_scalar_types = [IntTypes; pm_Integer]
        rational_scalar_types = [[Rational{T} for T in IntTypes]; pm_Rational]

        @test 2X isa pm_Vector{pm_Integer}
        @test Int32(2)X isa pm_Vector{Int32}

        for T in int_scalar_types
            for (vec, ElType) in [(V, pm_Integer), (W, pm_Rational), (U, Float64)]
                op = *
                @test op(T(2), vec)                 isa pm_Vector{ElType}
                @test op(vec, T(2))                 isa pm_Vector{ElType}
                @test broadcast(op, T(2), vec)      isa pm_Vector{ElType}
                @test broadcast(op, vec, T(2))      isa pm_Vector{ElType}

                op = +
                @test op(vec, T.(jl_v))             isa pm_Vector{ElType}
                @test op(T.(jl_v), vec)             isa pm_Vector{ElType}
                @test broadcast(op, vec, T.(jl_v))  isa pm_Vector{ElType}
                @test broadcast(op, T.(jl_v), vec)  isa pm_Vector{ElType}

                @test broadcast(op, vec, T(2))      isa pm_Vector{ElType}
                @test broadcast(op, T(2), vec)      isa pm_Vector{ElType}
            end

            let (op, ElType) = (//, pm_Rational)
                for vec in [V, W]
                    @test op(vec, T(2))             isa pm_Vector{ElType}
                    @test broadcast(op, T(2), vec)  isa pm_Vector{ElType}
                    @test broadcast(op, vec, T(2))  isa pm_Vector{ElType}
                end
            end
            let (op, ElType) = (/, Float64)
                vec = U
                @test op(vec, T(2))                 isa pm_Vector{ElType}
                @test broadcast(op, T(2), vec)      isa pm_Vector{ElType}
                @test broadcast(op, vec, T(2))      isa pm_Vector{ElType}
            end
        end

        for T in rational_scalar_types
            for (vec, ElType) in [(V, pm_Rational), (W, pm_Rational), (U, Float64)]
                op = *
                @test op(T(2), vec)                 isa pm_Vector{ElType}
                @test op(vec, T(2))                 isa pm_Vector{ElType}
                @test broadcast(op, T(2), vec)      isa pm_Vector{ElType}
                @test broadcast(op, vec, T(2))      isa pm_Vector{ElType}

                if ElType == Float64
                    op = /
                else
                    op = //
                end

                # @test op(T(2), vec)               isa pm_Vector{ElType}
                @test op(vec, T(2))                 isa pm_Vector{ElType}
                @test broadcast(op, T(2), vec)      isa pm_Vector{ElType}
                @test broadcast(op, vec, T(2))      isa pm_Vector{ElType}

                op = +
                @test op(vec, T.(jl_v))             isa pm_Vector{ElType}
                @test op(T.(jl_v), vec)             isa pm_Vector{ElType}

                @test broadcast(op, vec, T.(jl_v))  isa pm_Vector{ElType}
                @test broadcast(op, T.(jl_v), vec)  isa pm_Vector{ElType}

                @test broadcast(op, T(2), vec)      isa pm_Vector{ElType}
                @test broadcast(op, vec, T(2))      isa pm_Vector{ElType}
            end
        end

        for T in FloatTypes
            let vec = U, ElType = Float64
                op = *
                @test op(T(2), vec)                 isa pm_Vector{ElType}
                @test op(vec, T(2))                 isa pm_Vector{ElType}
                @test broadcast(op, T(2), vec)      isa pm_Vector{ElType}
                @test broadcast(op, vec, T(2))      isa pm_Vector{ElType}

                op = +
                @test op(vec, T.(jl_v))             isa pm_Vector{ElType}
                @test op(T.(jl_v), vec)             isa pm_Vector{ElType}

                @test broadcast(op, vec, T.(jl_v))  isa pm_Vector{ElType}
                @test broadcast(op, T.(jl_v), vec)  isa pm_Vector{ElType}

                @test broadcast(op, T(2), vec)      isa pm_Vector{ElType}
                @test broadcast(op, vec, T(2))      isa pm_Vector{ElType}

                op = /
                # @test op(T(2), vec)               isa pm_Vector{ElType}
                @test op(vec, T(2))                 isa pm_Vector{ElType}
                @test broadcast(op, T(2), vec)      isa pm_Vector{ElType}
                @test broadcast(op, vec, T(2))      isa pm_Vector{ElType}
            end
        end

        for T in [int_scalar_types; rational_scalar_types; FloatTypes]
            @test T(2)*X == X*T(2) == T(2) .* X == X .* T(2) == 2jl_v
            @test T(2)*V == V*T(2) == T(2) .* V == V .* T(2) == 2jl_v
            @test T(2)*W == W*T(2) == T(2) .* W == W .* T(2) == 2jl_w
            @test T(2)*U == U*T(2) == T(2) .* U == U .* T(2) == 2jl_u

            @test X + T.(jl_v) == T.(jl_v) + X == X .+ T.(jl_v) == T.(jl_v) .+ X == 2jl_v

            @test V + T.(jl_v) == T.(jl_v) + V == V .+ T.(jl_v) == T.(jl_v) .+ V == 2jl_v

            @test W + T.(4jl_w) == T.(4jl_w) + W == W .+ T.(4jl_w) == T.(4jl_w) .+ W == 5jl_w

            @test U + T.(4jl_u) == T.(4jl_u) + U == U .+ T.(4jl_u) == T.(4jl_u) .+ U == 5jl_u
        end
    end

end
