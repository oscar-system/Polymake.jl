@testset "pm_Vector" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]
    for T in [pm_Integer, pm_Rational]
        @test pm_Vector{T} <: AbstractVector
        @test pm_Vector{T}(3) isa AbstractVector
        @test pm_Vector{T}(3) isa pm_Vector
        @test pm_Vector{T}(3) isa pm_Vector{T}
    end

    jl_v = [1,2,3]
    @testset "Constructors/Converts" begin
        for T in [IntTypes; pm_Integer]
            @test pm_Vector(T.(jl_v)) isa pm_Vector{pm_Integer}
            @test pm_Vector(T.(jl_v)) isa pm_Vector{pm_Integer}
            @test pm_Vector{pm_Integer}(jl_v//T(1)) isa pm_Vector{pm_Integer}

            @test convert(Vector{T}, pm_Vector(T.(jl_v))) isa Vector{T}

            @test pm_Vector(jl_v//T(1)) isa pm_Vector{pm_Rational}
            @test pm_Vector{pm_Rational}(T.(jl_v)) isa pm_Vector{pm_Rational}

            @test Polymake.convert_to_pm(T.(jl_v)) isa pm_Vector{pm_Integer}

            @test Polymake.convert_to_pm(T.(jl_v)//1) isa pm_Vector{pm_Rational}
        end
    end

    @testset "Low-level operations" begin
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

        @testset "Equality" begin
            V = pm_Vector{pm_Integer}(3)
            W = pm_Vector{pm_Rational}(3)

            for T in [IntTypes; pm_Integer]
                @test (V .= T.(jl_v)) isa pm_Vector{pm_Integer}
                @test (V .= T.(jl_v).//1) isa pm_Vector{pm_Integer}

                @test (W .= T.(jl_v)) isa pm_Vector{pm_Rational}
                @test (W .= T.(jl_v).//1) isa pm_Vector{pm_Rational}

                @test V == W

                # TODO:
                # @test (V .== jl_v) isa BitArray
                # @test all(V .== jl_v)
            end
        end
    end

    @testset "Arithmetic" begin
        V = pm_Vector{pm_Integer}(jl_v)
        jl_w = jl_v//4
        W = pm_Vector{pm_Rational}(jl_w)


        @test -V isa Polymake.pm_VectorAllocated{pm_Integer}
        @test -V == -jl_v

        @test -W isa Polymake.pm_VectorAllocated{pm_Rational}
        @test -W == -(jl_w)

        int_scalar_types = [IntTypes; pm_Integer]
        rational_scalar_types = [[Rational{T} for T in IntTypes]; pm_Rational]

        for T in int_scalar_types
            for (vec, ElType) in [(V, pm_Integer), (W, pm_Rational)]
                op = *
                @test op(T(2), vec) isa pm_Vector{ElType}
                @test op(vec, T(2)) isa pm_Vector{ElType}
                @test broadcast(op, T(2), vec) isa pm_Vector{ElType}
                @test broadcast(op, vec, T(2)) isa pm_Vector{ElType}

                op = //
                # @test op(T(2), vec) isa pm_Vector{pm_Rational}
                @test op(vec, T(2)) isa pm_Vector{pm_Rational}
                @test broadcast(op, T(2), vec) isa pm_Vector{pm_Rational}
                @test broadcast(op, vec, T(2)) isa pm_Vector{pm_Rational}

                op = +
                @test op(vec, T.(jl_v)) isa pm_Vector{ElType}
                @test op(T.(jl_v), vec) isa pm_Vector{ElType}
                @test broadcast(op, vec, T.(jl_v)) isa pm_Vector{ElType}
                @test broadcast(op, T.(jl_v), vec) isa pm_Vector{ElType}

                @test broadcast(op, vec, T(2)) isa pm_Vector{ElType}
                @test broadcast(op, T(2), vec) isa pm_Vector{ElType}
            end
        end

        for T in rational_scalar_types
            for vec in [V, W]
                op = *
                @test op(T(2), vec) isa pm_Vector{pm_Rational}
                @test op(vec, T(2)) isa pm_Vector{pm_Rational}
                @test broadcast(op, T(2), vec) isa pm_Vector{pm_Rational}
                @test broadcast(op, vec, T(2)) isa pm_Vector{pm_Rational}

                op = //
                # @test op(T(2), vec) isa pm_Vector{pm_Rational}
                @test op(vec, T(2)) isa pm_Vector{pm_Rational}
                @test broadcast(op, T(2), vec) isa pm_Vector{pm_Rational}
                @test broadcast(op, vec, T(2)) isa pm_Vector{pm_Rational}

                op = +
                @test op(vec, T.(jl_v)) isa pm_Vector{pm_Rational}
                @test op(T.(jl_v), vec) isa pm_Vector{pm_Rational}

                @test broadcast(op, vec, T.(jl_v)) isa pm_Vector{pm_Rational}
                @test broadcast(op, T.(jl_v), vec) isa pm_Vector{pm_Rational}

                @test broadcast(op, T(2), vec) isa pm_Vector{pm_Rational}
                @test broadcast(op, vec, T(2)) isa pm_Vector{pm_Rational}
            end
        end

        for T in [int_scalar_types; rational_scalar_types]
            @test T(2)*V == V*T(2) == T(2) .* V == V .* T(2) == 2jl_v
            @test T(2)*W == W*T(2) == T(2) .* W == W .* T(2) == 2jl_w

            @test V + T.(jl_v) == T.(jl_v) + V == V .+ T.(jl_v) == T.(jl_v) .+ V == 2jl_v

            @test W + T.(4jl_w) == T.(4jl_w) + W == W .+ T.(4jl_w) == T.(4jl_w) .+ W == 5jl_w
        end
    end

end
