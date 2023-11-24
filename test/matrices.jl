@testset verbose=true "Polymake.Matrix" begin
    IntTypes = [Int64, BigInt]
    FloatTypes = [Float64, BigFloat]
    if isdefined(@__MODULE__, :short_test) && !short_test
       append!(IntTypes, [Int32, UInt64])
       append!(FloatTypes, [Float32])
    end

    for T in [Int64, Polymake.Integer, Polymake.Rational, Float64, Polymake.QuadraticExtension{Polymake.Rational}, Polymake.OscarNumber]
        @test Polymake.Matrix{T} <: AbstractMatrix
        @test Polymake.Matrix{T}(undef, 3,4) isa AbstractMatrix
        @test Polymake.Matrix{T}(undef, 3,4) isa Polymake.Matrix
        @test Polymake.Matrix{T}(undef, 3,4) isa Polymake.Matrix{<:supertype(T)}
        @test Polymake.Matrix{T}(undef, 3,4) isa Polymake.Matrix{Polymake.to_cxx_type(T)}
        M = Polymake.Matrix{T}(undef, 3,4)
        M[1,1] = 10
        M[end] = 100
        @test M[1,1] isa T
        @test M[1,1] == 10
        @test M[end] isa T
        @test M[end] == M[end, end] == 100
    end

    m = 42
    a2 = 7
    if _with_oscar
        # prepare instances of OscarNumber to be used for multiple tests
        Qx, x = QQ["x"]
        K, (a1, a2) = embedded_number_field([x^2 - 2, x^3 - 5], [(0, 2), (0, 2)])
        m = a1 + 3*a2^2 + 7
    end
    Mon = Polymake.OscarNumber(m)
    A2 = Polymake.OscarNumber(a2)
    
    jl_m = [1 2 3; 4 5 6]
    @testset verbose=true "Constructors/Converts" begin
        @test Polymake.Matrix(jl_m//1) isa Polymake.Matrix{Polymake.Rational}
        @test Polymake.Matrix(jl_m/1) isa Polymake.Matrix{Float64}

        for T in [IntTypes; Polymake.Integer]
            @test Polymake.Matrix(T.(jl_m)) isa
                Polymake.Matrix{T<:Union{Int32,Int64} ? Polymake.to_cxx_type(Int64) : Polymake.Integer}

            for ElType in [Polymake.Integer, Polymake.Rational, Float64, Polymake.QuadraticExtension{Polymake.Rational}]
                for m in (jl_m, jl_m//T(1), jl_m/T(1))
                    @test Polymake.Matrix{ElType}(m) isa Polymake.Matrix{ElType}
                    @test convert(Polymake.Matrix{ElType}, m) isa Polymake.Matrix{ElType}

                    M = Polymake.Matrix(m)
                    @test convert(Base.Matrix{T}, M) isa Base.Matrix{T}
                    @test jl_m == convert(Base.Matrix{T}, M)
                end
            end

            for m in (jl_m, jl_m//T(1), jl_m/T(1))
                M = Polymake.Matrix(m)
                @test Polymake.convert(Polymake.PolymakeType, M) === M
                @test float.(M) isa Polymake.Matrix{Float64}
                @test Float64.(M) isa Polymake.Matrix{Float64}
                @test Base.Matrix{Float64}(M) isa Base.Matrix{Float64}
                @test convert.(Float64, M) isa Polymake.Matrix{Float64}
            end

            let W = Polymake.Matrix{Polymake.Rational}(jl_m)
                for T in [Base.Rational{I} for I in IntTypes]
                    @test convert(Base.Matrix{T}, W) isa Base.Matrix{T}
                    @test jl_m == convert(Base.Matrix{T}, W)
                end
            end

            let U = Polymake.Matrix{Float64}(jl_m)
                for T in FloatTypes
                    @test convert(Base.Matrix{T}, U) isa Base.Matrix{T}
                    @test jl_m == convert(Base.Matrix{T}, U)
                end
            end

            let Z = Polymake.Matrix{Polymake.OscarNumber}(jl_m)
                for T in [Polymake.Integer, Polymake.Rational, Polymake.QuadraticExtension{Polymake.Rational}]
                    @test convert(Base.Matrix{T}, Z) isa Base.Matrix{T}
                    @test jl_m == convert(Base.Matrix{T}, Z)
                end
            end
        end
    end

    @testset verbose=true "Low-level operations" begin
        @testset verbose=true "Polymake.Matrix{Int64}" begin
            jl_m_32 = Int32.(jl_m)
            @test Polymake.Matrix(jl_m_32) isa
                Polymake.Matrix{Polymake.to_cxx_type(Int64)}
            M = Polymake.Matrix{Int64}(jl_m_32)

            # linear indexing:
            @test M[1] == 1
            @test M[2] == 4

            @test eltype(M) == Int64

            @test_throws BoundsError M[0, 1]
            @test_throws BoundsError M[2, 5]
            @test_throws BoundsError M[3, 1]

            @test length(M) == 6
            @test size(M) == (2,3)

            for T in [IntTypes; Polymake.Integer]
                M = Polymake.Matrix{Int64}(jl_m_32) # local copy
                @test setindex!(M, T(5), 1, 1) isa Polymake.Matrix{Polymake.to_cxx_type(Int64)}
                @test M[T(1), 1] isa Int64
                @test M[1, T(1)] == 5
                # testing the return value of brackets operator
                @test M[2, 1] = T(10) isa T
                M[2, 1] = T(10)
                @test M[2, 1] == 10
                @test string(M) == "pm::Matrix<long>\n5 2 3\n10 5 6\n"
            end
        end

        @testset verbose=true "Polymake.Matrix{Polymake.Integer}" begin
            V = Polymake.Matrix{Polymake.Integer}(jl_m)
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
                V = Polymake.Matrix{Polymake.Integer}(jl_m) # local copy
                @test setindex!(V, T(5), 1, 1) isa Polymake.Matrix{Polymake.Integer}
                @test V[T(1), 1] isa Polymake.Polymake.IntegerAllocated
                @test V[1, T(1)] == 5
                # testing the return value of brackets operator
                @test V[2, 1] = T(10) isa T
                V[2, 1] = T(10)
                @test V[2, 1] == 10
                @test string(V) == "pm::Matrix<pm::Integer>\n5 2 3\n10 5 6\n"
            end
        end

        @testset verbose=true "Polymake.Matrix{Polymake.Rational}" begin
            V = Polymake.Matrix{Polymake.Rational}(jl_m)
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
                V = Polymake.Matrix{Polymake.Rational}(jl_m) # local copy
                @test setindex!(V, T(5)//T(3), 1, 1) isa Polymake.Matrix{Polymake.Rational}
                @test V[T(1), 1] isa Polymake.Polymake.RationalAllocated
                @test V[1, T(1)] == 5//3
                # testing the return value of brackets operator
                @test V[2] = T(10)//T(3) isa typeof(T(10)//T(3))
                V[2] = T(10)//T(3)
                @test V[2] == 10//3
                @test string(V) == "pm::Matrix<pm::Rational>\n5/3 2 3\n10/3 5 6\n"
            end
        end
        
        @testset verbose=true "Polymake.Matrix{Polymake.QuadraticExtension{Polymake.Rational}}" begin
            V = Polymake.Matrix{Polymake.QuadraticExtension{Polymake.Rational}}(jl_m)
            # linear indexing:
            @test V[1] == 1//1
            @test V[2] == 4//1

            @test eltype(V) == Polymake.QuadraticExtension{Polymake.Rational}

            @test_throws BoundsError V[0, 1]
            @test_throws BoundsError V[2, 5]
            @test_throws BoundsError V[3, 1]

            @test length(V) == 6
            @test size(V) == (2,3)

            for T in [IntTypes; Polymake.Integer]
                V = Polymake.Matrix{Polymake.QuadraticExtension{Polymake.Rational}}(jl_m) # local copy
                @test setindex!(V, T(5)//T(3), 1, 1) isa Polymake.Matrix{Polymake.QuadraticExtension{Polymake.Rational}}
                @test V[T(1), 1] isa Polymake.QuadraticExtension{Polymake.Rational}
                @test V[1, T(1)] == 5//3
                # testing the return value of brackets operator
                @test V[2] = T(10)//T(3) isa typeof(T(10)//T(3))
                V[2] = T(10)//T(3)
                @test V[2] == 10//3
                @test string(V) == "pm::Matrix<pm::QuadraticExtension<pm::Rational> >\n5/3 2 3\n10/3 5 6\n"
            end
        end

        @testset verbose=true "Polymake.Matrix{Polymake.OscarNumber}" begin
            V = Polymake.Matrix{Polymake.OscarNumber}(jl_m)
            # linear indexing:
            @test V[1] == 1
            @test V[2] == 4

            @test eltype(V) == Polymake.OscarNumber

            @test_throws BoundsError V[0, 1]
            @test_throws BoundsError V[2, 5]
            @test_throws BoundsError V[3, 1]

            @test length(V) == 6
            @test size(V) == (2,3)

            for T in [IntTypes; Polymake.Integer]
                V = Polymake.Matrix{Polymake.OscarNumber}(jl_m) # local copy
                @test setindex!(V, Mon, 1, 1) isa Polymake.Matrix{Polymake.OscarNumber}
                @test V[T(1), 1] isa Polymake.OscarNumber
                @test V[1, T(1)] == Mon
                # testing the return value of brackets operator
                @test V[2] = A2 isa Polymake.OscarNumber
                V[2] = A2
                @test V[2] == A2
                @test string(V) == string("pm::Matrix<common::OscarNumber>\n(", m, ") (2) (3)\n(", a2, ") (5) (6)\n")
            end
        end

        @testset verbose=true "Polymake.Matrix{Float64}" begin
            V = Polymake.Matrix{Float64}(jl_m)
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
                V = Polymake.Matrix{Float64}(jl_m) # local copy
                for S in FloatTypes
                    @test setindex!(V, S(5)/T(3), 1, 1) isa Polymake.Matrix{Float64}
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

        @testset verbose=true "Equality" begin
            for T in [IntTypes; Polymake.Integer]
                X = Polymake.Matrix{Int64}(undef, 2, 3)
                V = Polymake.Matrix{Polymake.Integer}(undef, 2, 3)
                W = Polymake.Matrix{Polymake.Rational}(undef, 2, 3)
                U = Polymake.Matrix{Float64}(undef, 2, 3)
                Y = Polymake.Matrix{Polymake.QuadraticExtension{Polymake.Rational}}(undef, 2, 3)
                Z = Polymake.Matrix{Polymake.OscarNumber}(undef, 2, 3)

                @test (X .= T.(jl_m)) isa Polymake.Matrix{Polymake.to_cxx_type(Int64)}
                @test (X .= T.(jl_m).//1) isa Polymake.Matrix{Polymake.to_cxx_type(Int64)}

                @test (V .= T.(jl_m)) isa Polymake.Matrix{Polymake.Integer}
                @test (V .= T.(jl_m).//1) isa Polymake.Matrix{Polymake.Integer}

                @test (W .= T.(jl_m)) isa Polymake.Matrix{Polymake.Rational}
                @test (W .= T.(jl_m).//1) isa Polymake.Matrix{Polymake.Rational}

                @test (U .= T.(jl_m)) isa Polymake.Matrix{Float64}
                @test (U .= T.(jl_m).//1) isa Polymake.Matrix{Float64}
                
                @test (Y .= T.(jl_m)) isa Polymake.Matrix{Polymake.QuadraticExtension{Polymake.Rational}}
                @test (Y .= T.(jl_m).//1) isa Polymake.Matrix{Polymake.QuadraticExtension{Polymake.Rational}}

                @test (Z .= T.(jl_m)) isa Polymake.Matrix{Polymake.OscarNumber}

                @test X == U == V == W == Y
                @test W == Z

                # TODO:
                # @test (V .== jl_m) isa BitPolymake.Array
                # @test all(V .== jl_m)
            end

            V = Polymake.Matrix{Polymake.Integer}(jl_m)
            for S in FloatTypes
                U = Polymake.Matrix{Float64}(2, 3)
                @test (U .= jl_m./S(1)) isa Polymake.Matrix{Float64}
                @test U == V
            end
        end
    end

    @testset verbose=true "Arithmetic" begin
        V = Polymake.Matrix{Polymake.Integer}(jl_m)
        @test float.(V) isa Polymake.Polymake.MatrixAllocated{Float64}
        @test V[1, :] isa Polymake.Polymake.VectorAllocated{Polymake.Integer}
        @test float.(V)[1, :] isa Polymake.Vector{Float64}

        @test similar(V, Float64) isa Polymake.Polymake.MatrixAllocated{Float64}
        @test similar(V, Float64, 10) isa Polymake.Polymake.VectorAllocated{Float64}
        @test similar(V, Float64, 10, 10) isa Polymake.Polymake.MatrixAllocated{Float64}

        X = Polymake.Matrix{Int64}(jl_m)
        V = Polymake.Matrix{Polymake.Integer}(jl_m)
        jl_w = jl_m//4
        W = Polymake.Matrix{Polymake.Rational}(jl_w)
        jl_u = jl_m/4
        U = Polymake.Matrix{Float64}(jl_u)
        sr2 = Polymake.QuadraticExtension{Polymake.Rational}(0, 1, 2)
        jl_y = sr2 * jl_m
        Y = Polymake.Matrix{Polymake.QuadraticExtension{Polymake.Rational}}(jl_y)

        jl_z = broadcast(*, Mon, jl_m)
        Z = Polymake.Matrix{Polymake.OscarNumber}(jl_z)

        @test -X isa Polymake.Polymake.MatrixAllocated{Polymake.to_cxx_type(Int64)}
        @test -X == -jl_m

        @test -V isa Polymake.Polymake.MatrixAllocated{Polymake.Integer}
        @test -V == -jl_m

        @test -W isa Polymake.Polymake.MatrixAllocated{Polymake.Rational}
        @test -W == -jl_w

        @test -U isa Polymake.Polymake.MatrixAllocated{Float64}
        @test -U == -jl_u
        
        @test -Y isa Polymake.Matrix{Polymake.QuadraticExtension{Polymake.Rational}}
        @test -Y == -jl_y

        @test -Z isa Polymake.Matrix{Polymake.OscarNumber}
        @test -Z == -jl_z

        @test vcat(W,V) isa Polymake.Polymake.MatrixAllocated{Polymake.Rational}
        @test vcat(W,V) == Polymake.Matrix{Polymake.Rational}([1//4 1//2 3//4; 1 5//4 3//2; 1 2 3; 4 5 6])
        @test hcat(W,V) == Polymake.Matrix{Polymake.Rational}([1//4 1//2 3//4 1 2 3; 1 5//4 3//2 4 5 6])

        int_scalar_types = [IntTypes; Polymake.Integer]
        rational_scalar_types = [[Base.Rational{T} for T in IntTypes]; Polymake.Rational]

        @test 2X isa Polymake.Matrix{Polymake.to_cxx_type(Int64)}
        @test Int32(2)X isa Polymake.Matrix{Polymake.to_cxx_type(Int64)}

        @testset verbose=true "Arithmetic1" begin
        for T in int_scalar_types
            for (mat, ElType) in ((V, Polymake.Integer), (W, Polymake.Rational), (U, Float64), (Y, Polymake.QuadraticExtension{Polymake.Rational}), (Z, Polymake.OscarNumber))
                op = *
                @test op(T(2), mat) isa Polymake.Matrix{ElType}
                @test op(mat, T(2)) isa Polymake.Matrix{ElType}
                @test broadcast(op, T(2), mat) isa Polymake.Matrix{ElType}
                @test broadcast(op, mat, T(2)) isa Polymake.Matrix{ElType}

                op = +
                @test op(mat, T.(jl_m)) isa Polymake.Matrix{ElType}
                @test op(T.(jl_m), mat) isa Polymake.Matrix{ElType}
                @test broadcast(op, mat, T.(jl_m)) isa Polymake.Matrix{ElType}
                @test broadcast(op, T.(jl_m), mat) isa Polymake.Matrix{ElType}

                @test broadcast(op, mat, T(2)) isa Polymake.Matrix{ElType}
                @test broadcast(op, T(2), mat) isa Polymake.Matrix{ElType}
            end

            let (op, ElType) = (//, Polymake.Rational)
                for mat in (V, W)

                    @test op(mat, T(2)) isa Polymake.Matrix{ElType}
                    @test broadcast(op, T(2), mat) isa Polymake.Matrix{ElType}
                    @test broadcast(op, mat, T(2)) isa Polymake.Matrix{ElType}
                end
            end
            let (op, ElType) = (//, Polymake.QuadraticExtension{Polymake.Rational})
                
                @test op(Y, T(2)) isa Polymake.Matrix{ElType}
                @test broadcast(op, T(2), Y) isa Polymake.Matrix{ElType}
                @test broadcast(op, Y, T(2)) isa Polymake.Matrix{ElType}
                    
            end
            let (op, ElType) = (/, Float64)
                mat = U
                @test op(mat, T(2)) isa Polymake.Matrix{ElType}
                @test broadcast(op, T(2), mat) isa Polymake.Matrix{ElType}
                @test broadcast(op, mat, T(2)) isa Polymake.Matrix{ElType}
            end
        end
        end

        @testset verbose=true "Arithmetic2" begin
        for T in rational_scalar_types
            for (mat, ElType) in ((V, Polymake.Rational), (W, Polymake.Rational), (U, Float64), (Y, Polymake.QuadraticExtension{Polymake.Rational}))

                op = *
                @test op(T(2), mat) isa Polymake.Matrix{ElType}
                @test op(mat, T(2)) isa Polymake.Matrix{ElType}
                @test broadcast(op, T(2), mat) isa Polymake.Matrix{ElType}
                @test broadcast(op, mat, T(2)) isa Polymake.Matrix{ElType}

                op = +
                @test op(mat, T.(jl_m)) isa Polymake.Matrix{ElType}
                @test op(T.(jl_m), mat) isa Polymake.Matrix{ElType}

                @test broadcast(op, mat, T.(jl_m)) isa Polymake.Matrix{ElType}
                @test broadcast(op, T.(jl_m), mat) isa Polymake.Matrix{ElType}

                @test broadcast(op, T(2), mat) isa Polymake.Matrix{ElType}
                @test broadcast(op, mat, T(2)) isa Polymake.Matrix{ElType}

                if ElType == Float64
                    op = /
                else
                    op = //
                end

                @test op(mat, T(2)) isa Polymake.Matrix{ElType}
                @test broadcast(op, T(2), mat) isa Polymake.Matrix{ElType}
                @test broadcast(op, mat, T(2)) isa Polymake.Matrix{ElType}
            end
        end
        end
        @testset verbose=true "Arithmetic3" begin
        for T in FloatTypes
            let mat = U, ElType = Float64
                op = *
                @test op(T(2), mat) isa Polymake.Matrix{ElType}
                @test op(mat, T(2)) isa Polymake.Matrix{ElType}
                @test broadcast(op, T(2), mat) isa Polymake.Matrix{ElType}
                @test broadcast(op, mat, T(2)) isa Polymake.Matrix{ElType}

                op = +
                @test op(mat, T.(jl_m)) isa Polymake.Matrix{ElType}
                @test op(T.(jl_m), mat) isa Polymake.Matrix{ElType}

                @test broadcast(op, mat, T.(jl_m)) isa Polymake.Matrix{ElType}
                @test broadcast(op, T.(jl_m), mat) isa Polymake.Matrix{ElType}

                @test broadcast(op, T(2), mat) isa Polymake.Matrix{ElType}
                @test broadcast(op, mat, T(2)) isa Polymake.Matrix{ElType}

                op = /
                # @test op(T(2), mat) isa Polymake.Matrix{ElType}
                @test op(mat, T(2)) isa Polymake.Matrix{ElType}
                @test broadcast(op, T(2), mat) isa Polymake.Matrix{ElType}
                @test broadcast(op, mat, T(2)) isa Polymake.Matrix{ElType}
            end
        end
        
        end
        @testset verbose=true "Arithmetic4" begin
        let T = Polymake.QuadraticExtension{Polymake.Rational}, mat = Y, ElType = Polymake.QuadraticExtension{Polymake.Rational}
            op = *
            @test op(T(2), mat) isa Polymake.Matrix{ElType}
            @test op(mat, T(2)) isa Polymake.Matrix{ElType}
            @test broadcast(op, T(2), mat) isa Polymake.Matrix{ElType}
            @test broadcast(op, mat, T(2)) isa Polymake.Matrix{ElType}

            op = +
            @test op(mat, T.(jl_m)) isa Polymake.Matrix{ElType}
            @test op(T.(jl_m), mat) isa Polymake.Matrix{ElType}

            @test broadcast(op, mat, T.(jl_m)) isa Polymake.Matrix{ElType}
            @test broadcast(op, T.(jl_m), mat) isa Polymake.Matrix{ElType}

            @test broadcast(op, T(2), mat) isa Polymake.Matrix{ElType}
            @test broadcast(op, mat, T(2)) isa Polymake.Matrix{ElType}

            op = //
            # @test op(T(2), mat) isa Polymake.Matrix{ElType}
            @test op(mat, T(2)) isa Polymake.Matrix{ElType}
            @test broadcast(op, T(2), mat) isa Polymake.Matrix{ElType}
            @test broadcast(op, mat, T(2)) isa Polymake.Matrix{ElType}
        end

        end
        @testset verbose=true "Arithmetic5" begin
        for T in [int_scalar_types; rational_scalar_types; FloatTypes; Polymake.QuadraticExtension{Polymake.Rational}]
            @test T(2)*X == X*T(2) == T(2) .* X == X .* T(2) == 2jl_m
            @test T(2)*V == V*T(2) == T(2) .* V == V .* T(2) == 2jl_m
            @test T(2)*W == W*T(2) == T(2) .* W == W .* T(2) == 2jl_w
            @test T(2)*U == U*T(2) == T(2) .* U == U .* T(2) == 2jl_u
            @test T(2)*Y == Y*T(2) == T(2) .* Y == Y .* T(2) == 2jl_y

            @test X + T.(jl_m) == T.(jl_m) + X == X .+ T.(jl_m) == T.(jl_m) .+ X == 2jl_m

            @test V + T.(jl_m) == T.(jl_m) + V == V .+ T.(jl_m) == T.(jl_m) .+ V == 2jl_m

            @test W + T.(4jl_w) == T.(4jl_w) + W == W .+ T.(4jl_w) == T.(4jl_w) .+ W == 5jl_w

            @test U + T.(4jl_u) == T.(4jl_u) + U == U .+ T.(4jl_u) == T.(4jl_u) .+ U == 5jl_u
            
            @test Y + T.(2 * jl_m) == T.(2 * jl_m) + Y == Y .+ T.(2 * jl_m) == T.(2 * jl_m) .+ Y == (1 + sr2) * jl_y
        end

        end
        @testset verbose=true "Arithmetic5" begin
        for T in [int_scalar_types; rational_scalar_types]
            @test T(2)*Z == Z*T(2) == T(2) .* Z == Z .* T(2) == 2jl_z
            @test Z + T.(2 * jl_m) == T.(2 * jl_m) + Z == Z .+ T.(2 * jl_m) == T.(2 * jl_m) .+ Z == [Polymake.OscarNumber(m + 2) Polymake.OscarNumber(2*m + 4) Polymake.OscarNumber(3*m + 6); Polymake.OscarNumber(4*m + 8) Polymake.OscarNumber(5*m + 10) Polymake.OscarNumber(6*m + 12)]
        end
        end
    end
    
    @testset verbose=true "Arithmetic6" begin
    for S in [Polymake.Rational]
        T = Polymake.Polynomial{S, CxxWrap.CxxLong}
        @test Polymake.Matrix{T} <: AbstractMatrix
        @test Polymake.Matrix{T}(undef, 3,4) isa AbstractMatrix
        @test Polymake.Matrix{T}(undef, 3,4) isa Polymake.Matrix
        @test Polymake.Matrix{T}(undef, 3,4) isa Polymake.Matrix{<:supertype(T)}
        @test Polymake.Matrix{T}(undef, 3,4) isa Polymake.Matrix{Polymake.to_cxx_type(T)}
        M = Polymake.Matrix{T}(undef, 3,4)
        M[1,1] = T([-1, 2], [0 1 1; 1 0 1])
        M[end] = T([1, 1, 1], [1 0 0; 0 1 0; 0 0 1])
        @test M[1,1] isa T
        @test M[1,1] == T([-1, 2], [0 1 1; 1 0 1])
        @test M[end] isa T
        @test M[end] == M[end, end] == T([1, 1, 1], [1 0 0; 0 1 0; 0 0 1])

        @test eltype(M) == Polymake.Polynomial{Polymake.Rational, CxxWrap.CxxLong}

        @test_throws BoundsError M[0, 1]
        @test_throws BoundsError M[2, 5]

        @test length(M) == 12
        @test size(M) == (3,4)

        for U in [IntTypes; Polymake.Integer]
            V = Polymake.Matrix{T}(M) # local copy
            @test setindex!(V, T([2, 3], [2 3 0; 0 2 3]), 1, 1) isa Polymake.Matrix{T}
            @test V[U(1), 1] isa T
            @test V[1, U(1)] == T([2, 3], [2 3 0; 0 2 3])
            # testing the return value of brackets operator
            @test (V[2, 1] = T([4, 5], [1 0 0; 0 0 1])) isa T
            V[2, 1] = T([4, 5], [1 0 0; 0 0 1])
            @test V[2, 1] == T([4, 5], [1 0 0; 0 0 1])
            @test string(V) == "pm::Matrix<pm::Polynomial<pm::Rational, long> >\n2*x_0^2*x_1^3 + 3*x_1^2*x_2^3 0 0 0\n4*x_0 + 5*x_2 0 0 0\n0 0 0 x_0 + x_1 + x_2\n"
        end
    end
    end
    
end
