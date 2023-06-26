using Polymake.SparseArrays

@testset verbose=true "Polymake.SparseVector" begin
    IntTypes = [Int32, Int64, UInt64, BigInt]
    FloatTypes = [Float32, Float64, BigFloat]

    for T in [Int64, Polymake.Integer, Polymake.Rational, Float64, Polymake.QuadraticExtension{Polymake.Rational}, Polymake.OscarNumber]
        @test Polymake.SparseVector{T} <: AbstractSparseVector
        @test Polymake.spzeros(T, 3) isa AbstractSparseVector
        @test Polymake.spzeros(T, 3) isa Polymake.SparseVector
        @test Polymake.spzeros(T, 3) isa Polymake.SparseVector{Polymake.to_cxx_type(T)}
        V = Polymake.spzeros(T, 4)
        V[1] = 10
        V[end] = 4
        @test V[1] isa T
        @test V[1] == 10
        @test V[end] isa T
        @test V[end] == 4
    end

    jl_v = [1, 2, 3]
    jl_s = sparsevec([0 1 0])
    @testset verbose=true "Constructors/Converts" begin
        for T in IntTypes #TODO Polymake.Integer
            @test Polymake.SparseVector(T.(jl_v)) isa Polymake.SparseVector{Polymake.to_cxx_type(Polymake.convert_to_pm_type(T))}
            @test Polymake.SparseVector(jl_v//1) isa Polymake.SparseVector{Polymake.Rational}
            @test Polymake.SparseVector(jl_v/1) isa Polymake.SparseVector{Float64}

            @test Polymake.SparseVector(T.(jl_s)) isa Polymake.SparseVector{Polymake.to_cxx_type(Polymake.convert_to_pm_type(T))}
            @test Polymake.SparseVector(jl_s//1) isa Polymake.SparseVector{Polymake.Rational}
            @test Polymake.SparseVector(jl_s/1) isa Polymake.SparseVector{Float64}

            for ElType in [Polymake.Integer, Polymake.Rational, Float64, Polymake.QuadraticExtension{Polymake.Rational}]
                for v in (jl_v, jl_v//T(1), jl_v/T(1))
                    @test Polymake.SparseVector{ElType}(v) isa Polymake.SparseVector{ElType}
                    @test convert(Polymake.SparseVector{ElType}, v) isa Polymake.SparseVector{ElType}

                    V = Polymake.SparseVector(v)
                    @test convert(Base.Vector{T}, V) isa Base.Vector{T}
                    @test jl_v == convert(Base.Vector{T}, V)
                end
                for s in (jl_s, jl_s//T(1), jl_s/T(1)) #TODO
                    @test Polymake.SparseVector{ElType}(s) isa Polymake.SparseVector{ElType}
                    @test convert(Polymake.SparseVector{ElType}, s) isa Polymake.SparseVector{ElType}

                    S = Polymake.SparseVector(s)
                    # @test convert(SparseArrays.Polymake.SparseVectorCSC{T,}, S) isa SparseArrays.Polymake.SparseVectorCSC{T}
                    # @test jl_s == convert(SparseArrays.Polymake.SparseVectorCSC{T}, S)
                end
            end

            let ElType = Polymake.OscarNumber
                for v in (jl_v, jl_v//T(1))
                    @test Polymake.SparseVector{ElType}(v) isa Polymake.SparseVector{ElType}
                    @test convert(Polymake.SparseVector{ElType}, v) isa Polymake.SparseVector{ElType}

                    V = Polymake.SparseVector(v)
                    @test convert(Base.Vector{T}, V) isa Base.Vector{T}
                    @test jl_v == convert(Base.Vector{T}, V)
                end
                for s in (jl_s, jl_s//T(1)) #TODO
                    @test Polymake.SparseVector{ElType}(s) isa Polymake.SparseVector{ElType}
                    @test convert(Polymake.SparseVector{ElType}, s) isa Polymake.SparseVector{ElType}

                    S = Polymake.SparseVector(s)
                    # @test convert(SparseArrays.Polymake.SparseVectorCSC{T,}, S) isa SparseArrays.Polymake.SparseVectorCSC{T}
                    # @test jl_s == convert(SparseArrays.Polymake.SparseVectorCSC{T}, S)
                end
            end

            for v in (jl_v, jl_v//T(1), jl_v/T(1), jl_s, jl_s//T(1), jl_s/T(1))
                V = Polymake.SparseVector(v)
                @test Polymake.convert(Polymake.PolymakeType, V) === V
                @test float.(V) isa Polymake.SparseVector{Float64}
                @test Float64.(V) isa Polymake.SparseVector{Float64}
                @test Base.Vector{Float64}(V) isa Base.Vector{Float64}
                @test convert.(Float64, V) isa Polymake.SparseVector{Float64}
            end

            let W = Polymake.SparseVector{Polymake.Rational}(jl_v)
                for T in [Base.Rational{I} for I in IntTypes]
                    @test convert(Base.Vector{T}, W) isa Base.Vector{T}
                    @test jl_v == convert(Base.Vector{T}, W)
                end
            end

            let W = Polymake.SparseVector{Polymake.Rational}(jl_s)
                for T in [Base.Rational{I} for I in IntTypes]
                    @test convert(Base.Vector{T}, W) isa Base.Vector{T}
                    @test jl_s == convert(Base.Vector{T}, W)
                end
            end

            let U = Polymake.SparseVector{Float64}(jl_v)
                for T in FloatTypes
                    @test convert(Base.Vector{T}, U) isa Base.Vector{T}
                    @test jl_v == convert(Base.Vector{T}, U)
                end
            end

            let U = Polymake.SparseVector{Float64}(jl_s)
                for T in FloatTypes
                    @test convert(Base.Vector{T}, U) isa Base.Vector{T}
                    @test jl_s == convert(Base.Vector{T}, U)
                end
            end
        end
    end

    @testset verbose=true "Low-level operations" begin
        for (E,s) in [(Int64, "long"), (Polymake.Integer, "pm::Integer"), (Polymake.Rational, "pm::Rational"), (Float64, "double"), (Polymake.QuadraticExtension{Polymake.Rational}, "pm::QuadraticExtension<pm::Rational> "), (Polymake.OscarNumber, "common::OscarNumber")]
            @testset verbose=true "Polymake.SparseVector{$E}" begin
                V = Polymake.SparseVector{E}(jl_v)

                @test eltype(V) == E

                @test_throws BoundsError V[0]
                @test_throws BoundsError V[4]

                @test length(V) == 3
                @test size(V) == (3,)

                for T in [IntTypes; Polymake.Integer]
                    V = Polymake.SparseVector{E}(jl_v) # local copy
                    setindex!(V, T(5), 1)
                    @test V isa Polymake.SparseVector{Polymake.to_cxx_type(E)}
                    @test V[T(1)] isa E
                    @test V[T(1)] == 5
                    # testing the return value of brackets operator
                    @test V[2] = T(10) isa T
                    V[2] = T(10)
                    @test V[2] == 10
                    if E == Polymake.OscarNumber
                       @test string(V) == string("pm::SparseVector<", s, ">\n(5) (10) (3)")
                    else
                       @test string(V) == string("pm::SparseVector<", s, ">\n5 10 3")
                    end
                end
                if E == Polymake.OscarNumber
                   @test string(Polymake.SparseVector{E}(jl_s)) == string("pm::SparseVector<", s, ">\n(3) (1 (1))")
                else
                   @test string(Polymake.SparseVector{E}(jl_s)) == string("pm::SparseVector<", s, ">\n(3) (1 1)")
                end
            end
        end

        @testset verbose=true "Equality" begin
            for T in [IntTypes; Polymake.Integer]
                V = Polymake.SparseVector{Polymake.Integer}(3)
                W = Polymake.SparseVector{Polymake.Rational}(3)
                U = Polymake.SparseVector{Float64}(3)
                Y = Polymake.SparseVector{Polymake.QuadraticExtension{Polymake.Rational}}(3)
                Z = Polymake.SparseVector{Polymake.OscarNumber}(3)

                #TODO T.(jl_s)
                @test (V .= T.(jl_v)) isa Polymake.SparseVector{Polymake.Integer}
                @test (V .= T.(jl_v).//1) isa Polymake.SparseVector{Polymake.Integer}

                @test (W .= T.(jl_v)) isa Polymake.SparseVector{Polymake.Rational}
                @test (W .= T.(jl_v).//1) isa Polymake.SparseVector{Polymake.Rational}

                @test (U .= T.(jl_v)) isa Polymake.SparseVector{Float64}
                @test (U .= T.(jl_v).//1) isa Polymake.SparseVector{Float64}
                
                @test (Y .= T.(jl_v)) isa Polymake.SparseVector{Polymake.QuadraticExtension{Polymake.Rational}}
                @test (Y .= T.(jl_v).//1) isa Polymake.SparseVector{Polymake.QuadraticExtension{Polymake.Rational}}

                @test (Z .= T.(jl_v)) isa Polymake.SparseVector{Polymake.OscarNumber}

                @test U == V == W == Y == Z

                # TODO:
                # @test (V .== jl_v) isa BitArray
                # @test all(V .== jl_v)
            end

            V = Polymake.SparseVector{Polymake.Integer}(jl_v)
            for S in FloatTypes
                U = Polymake.SparseVector{Float64}(3)
                @test (U .= jl_v./S(1)) isa Polymake.SparseVector{Float64}
                @test U == V
            end
        end
    end

    @testset verbose=true "Arithmetic" begin
        V = Polymake.SparseVector{Polymake.Integer}(jl_v)
        @test float.(V) isa Polymake.SparseVectorAllocated{Float64}
        # @test V[1, :] isa Polymake.SparseVectorAllocated{Polymake.Integer}
        # @test float.(V)[1, :] isa SparseVector{Float64}

        @test similar(V, Float64) isa Polymake.SparseVectorAllocated{Float64}
        @test similar(V, Float64, 10) isa Polymake.SparseVectorAllocated{Float64}
        @test similar(V, Bool, 10) isa Polymake.SparseVectorBool
        @test similar(V, Bool, 2, 2) isa Polymake.IncidenceMatrixAllocated{Polymake.NonSymmetric}

        X = Polymake.SparseVector{Int64}(jl_v)
        V = Polymake.SparseVector{Polymake.Integer}(jl_v)
        jl_w = jl_v//4
        W = Polymake.SparseVector{Polymake.Rational}(jl_w)
        jl_u = jl_v/4
        U = Polymake.SparseVector{Float64}(jl_u)
        sr2 = Polymake.QuadraticExtension{Polymake.Rational}(0, 1, 2)
        jl_y = sr2 * jl_v
        Y = Polymake.SparseVector{Polymake.QuadraticExtension{Polymake.Rational}}(jl_y)

        m = 42
        if _with_oscar
            Qx, x = QQ["x"]
            K, (a1, a2) = embedded_number_field([x^2 - 2, x^3 - 5], [(0, 2), (0, 2)])
            m = a1 + 3*a2^2 + 7
        end

        M = Polymake.OscarNumber(m)
        jl_z = M * jl_v
        Z = Polymake.SparseVector{Polymake.OscarNumber}(jl_z)

        @test -X isa Polymake.SparseVectorAllocated{Polymake.to_cxx_type(Int64)}
        @test -X == -jl_v

        @test -V isa Polymake.SparseVectorAllocated{Polymake.Integer}
        @test -V == -jl_v

        @test -W isa Polymake.SparseVectorAllocated{Polymake.Rational}
        @test -W == -jl_w

        @test -U isa Polymake.SparseVectorAllocated{Float64}
        @test -U == -jl_u
        
        @test -Y isa Polymake.SparseVector{Polymake.QuadraticExtension{Polymake.Rational}}
        @test -Y == -jl_y

        @test -Z isa Polymake.SparseVector{Polymake.OscarNumber}
        @test -Z == -jl_z

        int_scalar_types = [IntTypes; Polymake.Integer]
        rational_scalar_types = [[Base.Rational{T} for T in IntTypes]; Polymake.Rational]

        @test 2X isa Polymake.SparseVector{Polymake.to_cxx_type(Int64)}
        @test Int32(2)X isa Polymake.SparseVector{Polymake.to_cxx_type(Int64)}

        @testset verbose=true "Arithmetic1" begin
        for T in int_scalar_types
            for (vec, ElType) in ((V, Polymake.Integer), (W, Polymake.Rational), (U, Float64), (Y, Polymake.QuadraticExtension{Polymake.Rational}), (Z, Polymake.OscarNumber))
                op = *
                @test op(T(2), vec) isa Polymake.SparseVector{ElType}
                @test op(vec, T(2)) isa Polymake.SparseVector{ElType}
                @test broadcast(op, T(2), vec) isa Polymake.SparseVector{ElType}
                @test broadcast(op, vec, T(2)) isa Polymake.SparseVector{ElType}

                op = +
                @test op(vec, T.(jl_v)) isa Polymake.SparseVector{ElType}
                @test op(T.(jl_v), vec) isa Polymake.SparseVector{ElType}
                @test broadcast(op, vec, T.(jl_v)) isa Polymake.SparseVector{ElType}
                @test broadcast(op, T.(jl_v), vec) isa Polymake.SparseVector{ElType}

                @test broadcast(op, vec, T(2)) isa Polymake.SparseVector{ElType}
                @test broadcast(op, T(2), vec) isa Polymake.SparseVector{ElType}
            end

            let (op, ElType) = (//, Polymake.Rational)
                for vec in (V, W)

                    @test op(vec, T(2)) isa Polymake.SparseVector{ElType}
                    @test broadcast(op, T(2), vec) isa Polymake.SparseVector{ElType}
                    @test broadcast(op, vec, T(2)) isa Polymake.SparseVector{ElType}
                end
            end
            let (op, ElType) = (/, Float64)
                vec = U
                @test op(vec, T(2)) isa Polymake.SparseVector{ElType}
                @test broadcast(op, T(2), vec) isa Polymake.SparseVector{ElType}
                @test broadcast(op, vec, T(2)) isa Polymake.SparseVector{ElType}
            end
            let (op, ElType) = (//, Polymake.QuadraticExtension{Polymake.Rational})
                vec = Y
                @test op(vec, T(2)) isa Polymake.SparseVector{ElType}
                @test broadcast(op, T(2), vec) isa Polymake.SparseVector{ElType}
                @test broadcast(op, vec, T(2)) isa Polymake.SparseVector{ElType}
            end
        end

        end
        @testset verbose=true "Arithmetic2" begin
        for T in rational_scalar_types
            for (vec, ElType) in ((V, Polymake.Rational), (W, Polymake.Rational), (U, Float64), (Y, Polymake.QuadraticExtension{Polymake.Rational}))

                op = *
                @test op(T(2), vec) isa Polymake.SparseVector{ElType}
                @test op(vec, T(2)) isa Polymake.SparseVector{ElType}
                @test broadcast(op, T(2), vec) isa Polymake.SparseVector{ElType}
                @test broadcast(op, vec, T(2)) isa Polymake.SparseVector{ElType}

                op = +
                @test op(vec, T.(jl_v)) isa Polymake.SparseVector{ElType}
                @test op(T.(jl_v), vec) isa Polymake.SparseVector{ElType}

                @test broadcast(op, vec, T.(jl_v)) isa Polymake.SparseVector{ElType}
                @test broadcast(op, T.(jl_v), vec) isa Polymake.SparseVector{ElType}

                @test broadcast(op, T(2), vec) isa Polymake.SparseVector{ElType}
                @test broadcast(op, vec, T(2)) isa Polymake.SparseVector{ElType}

                if ElType == Float64
                    op = /
                else
                    op = //
                end

                @test op(vec, T(2)) isa Polymake.SparseVector{ElType}
                @test broadcast(op, T(2), vec) isa Polymake.SparseVector{ElType}
                @test broadcast(op, vec, T(2)) isa Polymake.SparseVector{ElType}
            end
        end
        end
        @testset verbose=true "Arithmetic3" begin
        for T in FloatTypes
            let vec = U, ElType = Float64
                op = *
                @test op(T(2), vec) isa Polymake.SparseVector{ElType}
                @test op(vec, T(2)) isa Polymake.SparseVector{ElType}
                @test broadcast(op, T(2), vec) isa Polymake.SparseVector{ElType}
                @test broadcast(op, vec, T(2)) isa Polymake.SparseVector{ElType}

                op = +
                @test op(vec, T.(jl_v)) isa Polymake.SparseVector{ElType}
                @test op(T.(jl_v), vec) isa Polymake.SparseVector{ElType}

                @test broadcast(op, vec, T.(jl_v)) isa Polymake.SparseVector{ElType}
                @test broadcast(op, T.(jl_v), vec) isa Polymake.SparseVector{ElType}

                @test broadcast(op, T(2), vec) isa Polymake.SparseVector{ElType}
                @test broadcast(op, vec, T(2)) isa Polymake.SparseVector{ElType}

                op = /
                # @test op(T(2), vec) isa Polymake.Vector{ElType}
                @test op(vec, T(2)) isa Polymake.SparseVector{ElType}
                @test broadcast(op, T(2), vec) isa Polymake.SparseVector{ElType}
                @test broadcast(op, vec, T(2)) isa Polymake.SparseVector{ElType}
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

    @testset verbose=true "findnz" begin
        jsv = sprand(10151821,.0000014)
        droptol!(jsv,Polymake._get_global_epsilon())
        psv = Polymake.SparseVector(jsv)
        je, jv = findnz(jsv)
        pe, pv = findnz(psv)
        @test je == pe
        @test jv == pv
        @test SparseArrays.nonzeroinds(psv) == je
        @test SparseArrays.nonzeros(psv) == jv
    end
end
