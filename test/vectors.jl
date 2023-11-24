using Polymake.CxxWrap

@testset verbose=true "Polymake.Vector" begin
    IntTypes = [Int64, BigInt]
    FloatTypes = [Float64, BigFloat]
    if isdefined(@__MODULE__, :short_test) && !short_test
       append!(IntTypes, [Int32, UInt64])
       append!(FloatTypes, [Float32])
    end

    for T in [Int64, Polymake.Integer, Polymake.Rational, Float64, Polymake.QuadraticExtension{Polymake.Rational}, Polymake.OscarNumber]
        @test Polymake.Vector{T} <: AbstractVector
        @test Polymake.Vector{T}(undef, 3) isa AbstractVector
        @test Polymake.Vector{T}(undef, 3) isa Polymake.Vector
        @test Polymake.Vector{T}(undef, 3) isa AbstractVector{<:supertype(T)}
        @test Polymake.Vector{T}(undef, 3) isa Polymake.Vector{Polymake.to_cxx_type(T)}
        V = Polymake.Vector{T}(undef, 4)
        V[1] = 10
        V[end] = 4
        @test V[1] isa T
        @test V[1] == 10
        @test V[end] isa T
        @test V[end] == 4
    end

    m = 42
    a2 = 7
    if isdefined(@__MODULE__, :_with_oscar) && _with_oscar
        # prepare instances of OscarNumber to be used for multiple tests
        Qx, x = QQ["x"]
        K, (a1, a2) = embedded_number_field([x^2 - 2, x^3 - 5], [(0, 2), (0, 2)])
        m = a1 + 3*a2^2 + 7
    end
    M = Polymake.OscarNumber(m)
    A2 = Polymake.OscarNumber(a2)
    
    jl_v = [1,2,3]
    @testset verbose=true "Constructors/Converts" begin
        @test Polymake.Vector(jl_v//1) isa Polymake.Vector{Polymake.Rational}
        @test Polymake.Vector(jl_v/1) isa Polymake.Vector{Float64}

        for T in [IntTypes; Polymake.Integer]
            @test Polymake.Vector(T.(jl_v)) isa
                Polymake.Vector{T<:Union{Int32,Int64} ? Polymake.to_cxx_type(Int64) : Polymake.Integer}

            for ElType in [Polymake.Integer, Polymake.Rational, Float64]
                for v in (jl_v, jl_v//T(1), jl_v/T(1))
                    @test Polymake.Vector{ElType}(v) isa Polymake.Vector{ElType}
                    @test convert(Polymake.Vector{ElType}, v) isa Polymake.Vector{ElType}

                    V = Polymake.Vector(v)
                    @test convert(Base.Vector{T}, V) isa Base.Vector{T}
                    @test jl_v == convert(Base.Vector{T}, V)
                end
            end

            let ElType = Polymake.OscarNumber
                for v in(jl_v, jl_v//T(1))
                    @test Polymake.Vector{ElType}(v) isa Polymake.Vector{ElType}
                    @test convert(Polymake.Vector{ElType}, v) isa Polymake.Vector{ElType}

                    V = Polymake.Vector(v)
                    @test convert(Base.Vector{T}, V) isa Base.Vector{T}
                    @test jl_v == convert(Base.Vector{T}, V)
                end
            end

            for v in (jl_v, jl_v//T(1), jl_v/T(1))
                V = Polymake.Vector(v)
                @test Polymake.convert(Polymake.PolymakeType, V) === V
                @test float.(V) isa Polymake.Vector{Float64}
                @test Float64.(V) isa Polymake.Vector{Float64}
                @test Base.Vector{Float64}(V) isa Base.Vector{Float64}
                @test convert.(Float64, V) isa Polymake.Vector{Float64}
            end

            let W = Polymake.Vector{Polymake.Rational}(jl_v)
                for T in [Base.Rational{I} for I in IntTypes]
                    @test convert(Base.Vector{T}, W) isa Base.Vector{T}
                    @test jl_v == convert(Base.Vector{T}, W)
                end
            end

            let U = Polymake.Vector{Float64}(jl_v)
                for T in FloatTypes
                    @test convert(Base.Vector{T}, U) isa Base.Vector{T}
                    @test jl_v == convert(Base.Vector{T}, U)
                end
            end
        end
    end

    @testset verbose=true "Low-level operations" begin

        @testset verbose=true "Polymake.Vector{Int64}" begin
            jl_v_32 = Int32.(jl_v)
            @test Polymake.Vector(jl_v_32) isa Polymake.Vector{Polymake.to_cxx_type(Int64)}
            V = Polymake.Vector{Int64}(jl_v_32)

            @test eltype(V) == Int64

            @test_throws BoundsError V[0]
            @test_throws BoundsError V[5]
            @test length(V) == 3
            @test size(V) == (3,)

            for T in [IntTypes; Polymake.Integer]
                V = Polymake.Vector{Int64}(jl_v_32) # local copy
                @test setindex!(V, T(5), 1) isa Polymake.Vector{Polymake.to_cxx_type(Int64)}
                @test V[T(1)] isa Int64
                @test V[T(1)] == 5
                # testing the return value of brackets operator
                @test V[2] = T(10) isa T
                V[2] = T(10)
                @test V[2] == 10
                @test string(V) == "pm::Vector<long>\n5 10 3"
            end
        end

        @testset verbose=true "Polymake.Vector{Polymake.Integer}" begin
            V = Polymake.Vector{Polymake.Integer}(jl_v)

            @test eltype(V) == Polymake.Integer

            @test_throws BoundsError V[0]
            @test_throws BoundsError V[5]

            @test length(V) == 3
            @test size(V) == (3,)

            for T in [IntTypes; Polymake.Integer]
                V = Polymake.Vector{Polymake.Integer}(jl_v) # local copy
                @test setindex!(V, T(5), 1) isa Polymake.Vector{Polymake.Integer}
                @test V[T(1)] isa Polymake.Polymake.IntegerAllocated
                @test V[T(1)] == 5
                # testing the return value of brackets operator
                @test V[2] = T(10) isa T
                V[2] = T(10)
                @test V[2] == 10
                @test string(V) == "pm::Vector<pm::Integer>\n5 10 3"
            end
        end

        @testset verbose=true "Polymake.Vector{Polymake.Rational}" begin
            V = Polymake.Vector{Polymake.Rational}(jl_v)

            @test eltype(V) == Polymake.Rational

            @test_throws BoundsError V[0]
            @test_throws BoundsError V[5]

            @test length(V) == 3
            @test size(V) == (3,)

            for T in [IntTypes; Polymake.Integer]
                @test setindex!(V, T(5)//T(3), 1) isa Polymake.Vector{Polymake.Rational}
                @test V[T(1)] isa Polymake.Polymake.RationalAllocated
                @test V[T(1)] == 5//3
                # testing the return value of brackets operator
                if T != Polymake.Integer
                    @test V[2] = T(10)//T(3) isa Base.Rational{T}
                else
                    @test V[2] = T(10)//T(3) isa Polymake.Rational
                end
                V[2] = T(10)//T(3)
                @test V[2] == 10//3
                @test string(V) == "pm::Vector<pm::Rational>\n5/3 10/3 3"
            end
        end

        @testset verbose=true "Polymake.Vector{Float64}" begin
            V = Polymake.Vector{Float64}(jl_v)

            @test eltype(V) == Float64

            @test_throws BoundsError V[0]
            @test_throws BoundsError V[5]

            @test length(V) == 3
            @test size(V) == (3,)

            for T in [IntTypes; Polymake.Integer]
                @test setindex!(V, T(5)//T(3), 1) isa Polymake.Vector{Float64}
                @test V[T(1)] isa Float64
                @test V[T(1)] ≈ 5/3
                # testing the return value of brackets operator
                @test V[2] = T(10)/T(3) isa typeof(T(10)/T(3))
                V[2] = T(10)//T(3)
                @test V[2] ≈ 10/3
                @test string(V) == "pm::Vector<double>\n1.66667 3.33333 3"
            end
            
            @testset verbose=true "Polymake.Vector{Polymake.QuadraticExtension{Polymake.Rational}}" begin
                V = Polymake.Vector{Polymake.QuadraticExtension{Polymake.Rational}}(jl_v)

                @test eltype(V) == Polymake.QuadraticExtension{Polymake.Rational}

                @test_throws BoundsError V[0]
                @test_throws BoundsError V[5]

                @test length(V) == 3
                @test size(V) == (3,)

                for T in [IntTypes; Polymake.Integer]
                    @test setindex!(V, T(5)//T(3), 1) isa Polymake.Vector{Polymake.QuadraticExtension{Polymake.Rational}}
                    @test V[T(1)] isa Polymake.QuadraticExtension{Polymake.Rational}
                    @test V[T(1)] == 5//3
                    # testing the return value of brackets operator
                    if T != Polymake.Integer
                        @test V[2] = T(10)//T(3) isa Base.Rational{T}
                    else
                        @test V[2] = T(10)//T(3) isa Polymake.Rational
                    end
                    V[2] = T(10)//T(3)
                    @test V[2] == 10//3
                    @test string(V) == "pm::Vector<pm::QuadraticExtension<pm::Rational> >\n5/3 10/3 3"
                end
            end

            @testset verbose=true "Polymake.Vector{Polymake.OscarNumber}" begin
                V = Polymake.Vector{Polymake.Polymake.OscarNumber}(jl_v)

                @test eltype(V) == Polymake.OscarNumber

                @test_throws BoundsError V[0]
                @test_throws BoundsError V[5]

                @test length(V) == 3
                @test size(V) == (3,)

                for T in [IntTypes; Polymake.Integer]
                    @test setindex!(V, M, 1) isa Polymake.Vector{Polymake.OscarNumber}
                    @test V[T(1)] isa Polymake.OscarNumber
                    @test V[T(1)] == M
                    # testing the return value of brackets operator
                    @test V[2] = A2 isa Polymake.OscarNumber
                    V[2] = A2
                    @test V[2] == A2
                    @test string(V) == string("pm::Vector<common::OscarNumber>\n(", m, ") (", a2, ") (3)")
                end
            end
            
        end

        @testset verbose=true "Equality" begin
            X = Polymake.Vector{Int64}(undef, 3)
            V = Polymake.Vector{Polymake.Integer}(undef, 3)
            W = Polymake.Vector{Polymake.Rational}(undef, 3)
            U = Polymake.Vector{Float64}(undef, 3)
            Y = Polymake.Vector{Polymake.QuadraticExtension{Polymake.Rational}}(undef, 3)
            Z = Polymake.Vector{Polymake.OscarNumber}(undef, 3)

            for T in [IntTypes; Polymake.Integer]
                @test (X .= T.(jl_v)) isa Polymake.Vector{Polymake.to_cxx_type(Int64)}
                @test (X .= T.(jl_v).//1) isa Polymake.Vector{Polymake.to_cxx_type(Int64)}

                @test (V .= T.(jl_v)) isa Polymake.Vector{Polymake.Integer}
                @test (V .= T.(jl_v).//1) isa Polymake.Vector{Polymake.Integer}

                @test (W .= T.(jl_v)) isa Polymake.Vector{Polymake.Rational}
                @test (W .= T.(jl_v).//1) isa Polymake.Vector{Polymake.Rational}

                @test (U .= T.(jl_v)) isa Polymake.Vector{Float64}
                @test (U .= T.(jl_v).//1) isa Polymake.Vector{Float64}
                
                @test (Y .= T.(jl_v)) isa Polymake.Vector{Polymake.QuadraticExtension{Polymake.Rational}}
                @test (Y .= T.(jl_v).//1) isa Polymake.Vector{Polymake.QuadraticExtension{Polymake.Rational}}

                @test (Z .= T.(jl_v)) isa Polymake.Vector{Polymake.OscarNumber}
                @test (Z .= T.(jl_v).//1) isa Polymake.Vector{Polymake.OscarNumber}

                @test X == U == V == W == Y
                @test W == Z

                # TODO:
                # @test (V .== jl_v) isa BitPolymake.Array
                # @test all(V .== jl_v)
            end

            V = Polymake.Vector{Polymake.Integer}(jl_v)
            for S in FloatTypes
                U = Polymake.Vector{Float64}(3)
                @test (U .= jl_v./S(1)) isa Polymake.Vector{Float64}
                @test U == V
            end
        end
    end

    @testset verbose=true "Arithmetic" begin
        X = Polymake.Vector{Int64}(jl_v)
        V = Polymake.Vector{Polymake.Integer}(jl_v)
        jl_w = jl_v//4
        W = Polymake.Vector{Polymake.Rational}(jl_w)
        jl_u = jl_v/4
        U = Polymake.Vector{Float64}(jl_u)
        sr2 = Polymake.QuadraticExtension{Polymake.Rational}(0, 1, 2)
        jl_y = sr2 * jl_v
        Y = Polymake.Vector{Polymake.QuadraticExtension{Polymake.Rational}}(jl_y)

        jl_z = M * jl_v
        Z = Polymake.Vector{Polymake.OscarNumber}(jl_z)

        @test similar(V, Float64) isa Polymake.Polymake.VectorAllocated{Float64}
        @test similar(V, Float64, 10) isa Polymake.Polymake.VectorAllocated{Float64}

        @test sin.(V) isa Polymake.Vector{Float64}

        @test float.(V) isa Polymake.Polymake.VectorAllocated{Float64}

        @test -X isa Polymake.Polymake.VectorAllocated{Polymake.to_cxx_type(Int64)}
        @test -X == -jl_v

        @test -V isa Polymake.Polymake.VectorAllocated{Polymake.Integer}
        @test -V == -jl_v

        @test -W isa Polymake.Polymake.VectorAllocated{Polymake.Rational}
        @test -W == -jl_w

        @test -U isa Polymake.Polymake.VectorAllocated{Float64}
        @test -U == -jl_u
        
        @test -Y isa Polymake.Polymake.Vector{Polymake.QuadraticExtension{Polymake.Rational}}
        @test -Y == -jl_y

        @test -Z isa Polymake.Vector{Polymake.OscarNumber}
        @test -Z == -jl_z

        int_scalar_types = [IntTypes; Polymake.Integer]
        rational_scalar_types = [[Base.Rational{T} for T in IntTypes]; Polymake.Rational]

        @test 2X isa Polymake.Vector{Polymake.to_cxx_type(Int64)}
        @test Int32(2)X isa Polymake.Vector{Polymake.to_cxx_type(Int64)}

        @testset verbose=true "Arithmetic1" begin
        for T in int_scalar_types
            for (vec, ElType) in ((V, Polymake.Integer), (W, Polymake.Rational), (U, Float64), (Y, Polymake.QuadraticExtension{Polymake.Rational}), (Z, Polymake.OscarNumber))
                op = *
                @test op(T(2), vec)                 isa Polymake.Vector{ElType}
                @test op(vec, T(2))                 isa Polymake.Vector{ElType}
                @test broadcast(op, T(2), vec)      isa Polymake.Vector{ElType}
                @test broadcast(op, vec, T(2))      isa Polymake.Vector{ElType}

                op = +
                @test op(vec, T.(jl_v))             isa Polymake.Vector{ElType}
                @test op(T.(jl_v), vec)             isa Polymake.Vector{ElType}
                @test broadcast(op, vec, T.(jl_v))  isa Polymake.Vector{ElType}
                @test broadcast(op, T.(jl_v), vec)  isa Polymake.Vector{ElType}

                @test broadcast(op, vec, T(2))      isa Polymake.Vector{ElType}
                @test broadcast(op, T(2), vec)      isa Polymake.Vector{ElType}
            end

            let (op, ElType) = (//, Polymake.Rational)
                for vec in (V, W)
                    @test op(vec, T(2))             isa Polymake.Vector{ElType}
                    @test broadcast(op, T(2), vec)  isa Polymake.Vector{ElType}
                    @test broadcast(op, vec, T(2))  isa Polymake.Vector{ElType}
                end
            end
            let (op, ElType) = (/, Float64)
                vec = U
                @test op(vec, T(2))                 isa Polymake.Vector{ElType}
                @test broadcast(op, T(2), vec)      isa Polymake.Vector{ElType}
                @test broadcast(op, vec, T(2))      isa Polymake.Vector{ElType}
            end
            let (op, ElType) = (//, Polymake.QuadraticExtension{Polymake.Rational})
                vec = Y
                @test op(vec, T(2))                 isa Polymake.Vector{ElType}
                @test broadcast(op, T(2), vec)      isa Polymake.Vector{ElType}
                @test broadcast(op, vec, T(2))      isa Polymake.Vector{ElType}
            end
        end

        end
        @testset verbose=true "Arithmetic2" begin
        for T in rational_scalar_types
            for (vec, ElType) in ((V, Polymake.Rational), (W, Polymake.Rational), (U, Float64), (Y, Polymake.QuadraticExtension{Polymake.Rational}))
                op = *
                @test op(T(2), vec)                 isa Polymake.Vector{ElType}
                @test op(vec, T(2))                 isa Polymake.Vector{ElType}
                @test broadcast(op, T(2), vec)      isa Polymake.Vector{ElType}
                @test broadcast(op, vec, T(2))      isa Polymake.Vector{ElType}

                if ElType == Float64
                    op = /
                else
                    op = //
                end

                # @test op(T(2), vec)               isa Polymake.Vector{ElType}
                @test op(vec, T(2))                 isa Polymake.Vector{ElType}
                @test broadcast(op, T(2), vec)      isa Polymake.Vector{ElType}
                @test broadcast(op, vec, T(2))      isa Polymake.Vector{ElType}

                op = +
                @test op(vec, T.(jl_v))             isa Polymake.Vector{ElType}
                @test op(T.(jl_v), vec)             isa Polymake.Vector{ElType}

                @test broadcast(op, vec, T.(jl_v))  isa Polymake.Vector{ElType}
                @test broadcast(op, T.(jl_v), vec)  isa Polymake.Vector{ElType}

                @test broadcast(op, T(2), vec)      isa Polymake.Vector{ElType}
                @test broadcast(op, vec, T(2))      isa Polymake.Vector{ElType}
            end
        end

        end
        @testset verbose=true "Arithmetic3" begin
        for T in FloatTypes
            let vec = U, ElType = Float64
                op = *
                @test op(T(2), vec)                 isa Polymake.Vector{ElType}
                @test op(vec, T(2))                 isa Polymake.Vector{ElType}
                @test broadcast(op, T(2), vec)      isa Polymake.Vector{ElType}
                @test broadcast(op, vec, T(2))      isa Polymake.Vector{ElType}

                op = +
                @test op(vec, T.(jl_v))             isa Polymake.Vector{ElType}
                @test op(T.(jl_v), vec)             isa Polymake.Vector{ElType}

                @test broadcast(op, vec, T.(jl_v))  isa Polymake.Vector{ElType}
                @test broadcast(op, T.(jl_v), vec)  isa Polymake.Vector{ElType}

                @test broadcast(op, T(2), vec)      isa Polymake.Vector{ElType}
                @test broadcast(op, vec, T(2))      isa Polymake.Vector{ElType}

                op = /
                # @test op(T(2), vec)               isa Polymake.Vector{ElType}
                @test op(vec, T(2))                 isa Polymake.Vector{ElType}
                @test broadcast(op, T(2), vec)      isa Polymake.Vector{ElType}
                @test broadcast(op, vec, T(2))      isa Polymake.Vector{ElType}
            end
        end

        end
        @testset verbose=true "Arithmetic4" begin
        for T in [int_scalar_types; rational_scalar_types; FloatTypes; Polymake.QuadraticExtension{Polymake.Rational}]
            @test T(2)*X == X*T(2) == T(2) .* X == X .* T(2) == 2jl_v
            @test T(2)*V == V*T(2) == T(2) .* V == V .* T(2) == 2jl_v
            @test T(2)*W == W*T(2) == T(2) .* W == W .* T(2) == 2jl_w
            @test T(2)*U == U*T(2) == T(2) .* U == U .* T(2) == 2jl_u
            @test T(2)*Y == Y*T(2) == T(2) .* Y == Y .* T(2) == 2jl_y

            @test X + T.(jl_v) == T.(jl_v) + X == X .+ T.(jl_v) == T.(jl_v) .+ X == 2jl_v

            @test V + T.(jl_v) == T.(jl_v) + V == V .+ T.(jl_v) == T.(jl_v) .+ V == 2jl_v

            @test W + T.(4jl_w) == T.(4jl_w) + W == W .+ T.(4jl_w) == T.(4jl_w) .+ W == 5jl_w

            @test U + T.(4jl_u) == T.(4jl_u) + U == U .+ T.(4jl_u) == T.(4jl_u) .+ U == 5jl_u
            
            @test Y + T.(2 * jl_v) == T.(2 * jl_v) + Y == Y .+ T.(2 * jl_v) == T.(2 * jl_v) .+ Y == (1 + sr2) * jl_y
        end

        end
        @testset verbose=true "Arithmetic5" begin
        for T in [int_scalar_types; rational_scalar_types]
            @test T(2)*Z == Z*T(2) == T(2) .* Z == Z .* T(2) == 2jl_z
            @test Z + T.(2 * jl_v) == T.(2 * jl_v) + Z == Z .+ T.(2 * jl_v) == T.(2 * jl_v) .+ Z == [Polymake.OscarNumber(m + 2), Polymake.OscarNumber(2*m + 4), Polymake.OscarNumber(3*m + 6)]
        end
        end
    end
    
    @testset verbose=true "Arithmetic6" begin
    for S in [Polymake.Rational]
        T = Polymake.Polynomial{S, Int64}
        @test Polymake.Vector{T} <: AbstractVector
        @test Polymake.Vector{T}(undef, 3) isa AbstractVector
        @test Polymake.Vector{T}(undef, 3) isa Polymake.Vector
        @test Polymake.Vector{T}(undef, 3) isa AbstractVector{<:supertype(T)}
        @test Polymake.Vector{T}(undef, 3) isa Polymake.Vector{Polymake.to_cxx_type(T)}
        V = Polymake.Vector{T}(undef, 3)
        V[1] = T([-1, 2], [0 1 1; 1 0 1])
        V[end] = T([1, 1, 1], [1 0 0; 0 1 0; 0 0 1])
        @test V[1] isa Polymake.to_cxx_type(T)
        @test V[1] == T([-1, 2], [0 1 1; 1 0 1])
        @test V[end] isa Polymake.to_cxx_type(T)
        @test V[end] == T([1, 1, 1], [1 0 0; 0 1 0; 0 0 1])

        @test eltype(V) == Polymake.Polynomial{Polymake.Rational, CxxWrap.CxxLong}

        @test_throws BoundsError V[0]
        @test_throws BoundsError V[5]

        @test length(V) == 3
        @test size(V) == (3,)

        for U in [IntTypes; Polymake.Integer]
            W = Polymake.Vector{T}(V) # local copy
            @test setindex!(W, T([2, 3], [2 3 0; 0 2 3]), 1) isa Polymake.Vector{Polymake.to_cxx_type(T)}
            @test W[U(1)] isa Polymake.to_cxx_type(T)
            @test W[U(1)] == T([2, 3], [2 3 0; 0 2 3])
            # testing the return value of brackets operator
            @test (W[3] = T([4, 5], [1 0 0; 0 0 1])) isa Polymake.to_cxx_type(T)
            W[3] = T([4, 5], [1 0 0; 0 0 1])
            @test W[3] == T([4, 5], [1 0 0; 0 0 1])
            @test string(W) == "pm::Vector<pm::Polynomial<pm::Rational, long> >\n2*x_0^2*x_1^3 + 3*x_1^2*x_2^3 0 4*x_0 + 5*x_2"
        end
    end
    end

end
