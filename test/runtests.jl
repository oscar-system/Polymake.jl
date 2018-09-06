using PolymakeWrap
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

# write your own tests here
@testset "pm_Set" begin
    pm_Set = PolymakeWrap.pm_Set
    IntTypes = [Int32, Int64]


    @testset "constructors" begin
        @test pm_Set{Int32}() isa PolymakeWrap.Polymake.pm_Set
        @test pm_Set{Int64}() isa PolymakeWrap.Polymake.pm_SetAllocated
        for T in IntTypes
            @test pm_Set(T[1]) isa PolymakeWrap.Polymake.pm_Set
            @test pm_Set(T[1,1]) isa PolymakeWrap.Polymake.pm_Set
            @test pm_Set(T[2,1]) isa PolymakeWrap.Polymake.pm_Set
            @test pm_Set(T[-1,0,-1]) isa PolymakeWrap.Polymake.pm_Set
        end
    end

    @testset "equality" begin
        @test pm_Set{Int32}() == pm_Set{Int32}()
        @test pm_Set{Int64}() == pm_Set{Int64}()

        @test pm_Set{Int32}() == pm_Set{Int64}()

        for T in IntTypes, S in IntTypes
            @test pm_Set(T[1]) == pm_Set(S[1,1])
            @test pm_Set(T[2,2,1,1]) == pm_Set(S[1,2,1])
            A = deepcopy(pm_Set(T[1]))
            @test A == pm_Set(S[1])
        end
    end

    @testset "basic functionality" begin
        for T in IntTypes
            a = pm_Set(T[1,2,3,1])
            b = pm_Set(T[5,6,6])

            a1 = deepcopy(a)
            @test a1 == pm_Set([1,2,3])

            PolymakeWrap.swap(a, b)
            @test a == pm_Set(T[5,6])
            @test b == pm_Set(T[1,2,3])
            @test a1 == pm_Set(T[1,2,3])

            a1 = deepcopy(a)
            empty!(a)
            @test a == pm_Set{T}()
            @test isempty(a)
            @test !isempty(b)

            @test length(a) == 0
            @test length(a1) == 2
            @test length(b) == 3

            a = pm_Set(T[1,2,3,1,2,3])
            b = pm_Set(T[5,6,6])
            @test length(a) == 3
            @test length(b) == 2
        end
    end

    @testset "elements operations" begin
        for T in IntTypes, S in IntTypes
            a = pm_Set(T[3,2,1,3,2,1])
            b = pm_Set(T[5,6,6])

            @test S(2) in a
            @test !(S(5) in a)

            @test !(S(3) in b)
            @test S(5) in b

            a = pm_Set(T[1,2,3,1,2,3])
            b = pm_Set(T[5,6,6])
            @test push!(a, S(3)) == pm_Set([1,2,3])
            push!(a, S(-1))
            @test -1 in a
            @test push!(a, S(-1)) == pm_Set([1,2,3, -1])

            @test length(a) == 4
            @test a == pm_Set([1,2,3,-1])

            @test push!(b, S(6)) == pm_Set([5,6])
            push!(b, S(-100))
            @test -100 in b
            @test push!(b, S(-100)) == pm_Set([5,6, -100])
            @test length(b) == 3
            @test b == pm_Set([-100,5,6])

            A = pm_Set(T[0])
            B = pm_Set(S[0,1])
            push!(A, S(1))
            @test A == B
        end
    end

    @testset "operations" begin
        for T in IntTypes

            A_orig, B_orig = pm_Set(T[1,2,3]), pm_Set(T[2,3,4])

            @testset "union $T" begin
                let A = pm_Set(T[1,2,3]), B = pm_Set(T[2,3,4])
                    @test union(A,A) == A
                    @test union(A,B) == pm_Set([1,2,3,4])
                    @test A == A_orig

                    # union!
                    union!(A,A)
                    @test A == pm_Set([1,2,3])
                    union!(B,B)
                    @test B == pm_Set([2,3,4])

                    union!(A, B)
                    @test A == pm_Set([1,2,3,4])
                    @test B == pm_Set([2,3,4])
                    union!(B, A)
                    @test B == pm_Set([1,2,3,4])
                    @test A == B
                end
            end

            @testset "intersect $T" begin
                let A = pm_Set(T[1,2,3]), B = pm_Set(T[2,3,4])
                    @test A == intersect(A,A)
                    @test intersect(A, B) == pm_Set([2,3])
                    @test intersect(B, A) == pm_Set([2,3])
                    @test A == A_orig && B == B_orig

                    # intersect!
                    intersect!(A, B)
                    @test A == pm_Set([2,3])
                    @test B == pm_Set([2,3,4])
                    intersect!(B, A)
                    @test B == pm_Set([2,3])
                    @test A == B
                end
            end

            @testset "setdiff $T" begin
                let A = pm_Set(T[1,2,3]), B = pm_Set(T[2,3,4])
                    @test isempty(setdiff(A,A))
                    @test A == A_orig
                    @test setdiff(A, B) != setdiff(B, A)
                    @test A == A_orig

                    setdiff!(A, B)
                    @test A == pm_Set([1])
                    @test B == pm_Set([2,3,4])

                    setdiff!(B, A)
                    @test B == pm_Set([2,3,4])

                    A = deepcopy(A_orig)
                    setdiff!(B,A)
                    @test B == pm_Set([4])
                    @test A == pm_Set([1,2,3])
                end
            end

            @testset "symdiff $T" begin
                let A = pm_Set(T[1,2,3]), B = pm_Set(T[2,3,4])
                    @test isempty(symdiff(A,A))
                    @test !isempty(symdiff(A,B))
                    @test symdiff(A,B) == symdiff(B,A)

                    symdiff!(A, B)
                    @test A == pm_Set([1,4])
                    @test B == pm_Set([2,3,4])

                    symdiff!(A, B)
                    @test A == A_orig

                end
            end
        end
    end

    @testset "conversions" begin
        for T in IntTypes, S in IntTypes
            A = pm_Set(T[1,2,3,1,2,3])
            B = pm_Set(S[2,3,4])

            @test Vector(A) isa Vector{T}
            @test Vector(B) isa Vector{S}
            @test Vector{S}(A) isa Vector{S}
            @test Vector{T}(B) isa Vector{T}

            @test Vector(A) == [1,2,3]
            @test Vector(B) == [2,3,4]

            @test Vector{Float64}(A) == [1.0,2.0,3.0]
        end
    end
end
