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
        @test pm_Set{Int32}() isa pm_Set
        @test pm_Set{Int64}() isa pm_Set
        for T in IntTypes
            @test pm_Set(T[1]) isa pm_Set{T}
            @test pm_Set(T[1,1]) isa pm_Set{T}
            @test pm_Set(T[-1,1]) isa pm_Set{T}
            @test pm_Set(Set{T}[-1,1]) isa pm_Set{T}
        end
        for T in IntTypes, S in IntTypes
            @test pm_Set{T}(S[-1,1]) isa pm_Set{T}
            @test pm_Set{T}(Set{S}[-1,1]) isa pm_Set{T}
            @test pm_Set{T}(pm_Set(S[1,2])) isa pm_Set{T}
        end
    end

    @testset "equality" begin
        for T in IntTypes, S in IntTypes
            @test pm_Set{S}() == pm_Set{T}()
            @test pm_Set(T[1]) == pm_Set(S[1,1])
            @test pm_Set(T[2,2,1,1]) == pm_Set(S[1,2,1])
            @test pm_Set(T[1]) != pm_Set(S[2])

            A = deepcopy(pm_Set(T[1]))
            @test A == pm_Set(S[1])
        end
    end

    @testset "conversions" begin
        for T in IntTypes
            A = pm_Set(T[1,2,3,1,2,3])

            @test Vector(A) isa Vector{T}
            @test Vector(A) == [1,2,3]
            @test Vector{Float64}(A) == [1.0,2.0,3.0]

            @test Set(A) isa Set{T}
            @test Set(A) == Set([1,2,3])
            @test Set{Float64}(A) == Set([1.0,2.0,3.0])

            for S in IntTypes
                @test Vector{S}(A) isa Vector{S}
                @test Set{S}(A) isa Set{S}
            end
        end
    end


    @testset "relations" begin

        for T in IntTypes, S in IntTypes
            @test PolymakeWrap.incl(pm_Set(S[1]), pm_Set(T[1])) == 0
            @test PolymakeWrap.incl(pm_Set(S[1]), pm_Set(T[1,2])) == -1
            @test PolymakeWrap.incl(pm_Set(S[1,2]), pm_Set(T[1])) == 1
            @test PolymakeWrap.incl(pm_Set(S[1,2]), pm_Set(T[1,3])) == 2

            # <, <=, == are based on incl; just test that they agree with the julia versions
            @test (pm_Set{S}() < pm_Set{T}()) == (Set{S}() < Set{T}())
            @test (pm_Set{T}() < pm_Set(S[1])) == (Set{T}() < Set(S[1]))
            @test (pm_Set(S[1]) < pm_Set(T[1,2])) == (Set(S[1]) < Set(T[1,2]))
            @test (pm_Set(S[1,2]) < pm_Set(T[1])) == (Set(S[1,2]) < Set(T[1]))
            @test (pm_Set(S[1,2]) < pm_Set(T[1,3]))==(Set(S[1,2]) < Set(T[1,3]))

            @test (pm_Set{S}() <= pm_Set{T}()) == (Set{S}() <= Set{T}())
            @test (pm_Set{T}() <= pm_Set(S[1])) == (Set{T}() <= Set(S[1]))
            @test (pm_Set(S[1]) <= pm_Set(T[1,2])) == (Set(S[1]) <= Set(T[1,2]))
            @test (pm_Set(S[1,2]) <= pm_Set(T[1])) == (Set(S[1,2]) <= Set(T[1]))
            @test (pm_Set(S[1,2])<=pm_Set(T[1,3]))==(Set(S[1,2])<=Set(T[1,3]))
        end
    end

    @testset "basic functionality" begin
        for T in IntTypes
            A = pm_Set(T[1,2,3,1])
            B = pm_Set(T[5,6,6])

            A1 = deepcopy(A)
            PolymakeWrap.swap(A, B)

            @test A == pm_Set([5,6])
            @test B == pm_Set([1,2,3])
            @test A1 == B

            A = pm_Set(T[1,2,3,1])
            jlA = Set(T[1,2,3,1])

            B = pm_Set(T[5,6,6])
            jlB = Set(T[5,6,6])

            A1 = deepcopy(A)
            jlA1 = deepcopy(jlA)
            @test empty!(A) == empty!(jlA)

            @test A == jlA
            @test isempty(A) == isempty(jlA)
            @test isempty(B) == isempty(jlB)
            @test isempty(A1) == isempty(jlA1)

            @test length(A) == length(jlA)
            @test length(A1) == length(jlA1)
            @test length(B) == length(jlB)

            A = pm_Set(T[1,2,3,1,2,3])
            b = pm_Set(T[5,6,6])
            @test length(A) == length(Set([1,2,3,1,2,3]))
            @test length(B) == length(Set([5,6,6]))
        end
    end

    @testset "elements operations" begin
        for T in IntTypes, S in IntTypes
            A = pm_Set(T[3,2,1,3,2,1])
            B = pm_Set(T[5,6,6])

            @test S(2) in A
            @test !(S(5) in A)

            @test !(S(3) in B)
            @test S(5) in B

            A = pm_Set(T[1,2,3,1,2,3])
            jlA = Set(T[1,2,3,1,2,3])
            B = pm_Set(T[5,6,6])
            jlB = Set(T[5,6,6])

            @test push!(A, S(3)) == push!(jlA, S(3))
            @test push!(A, S(-1)) == push!(jlA, S(-1))
            @test (-1 in A) == (-1 in jlA)
            @test push!(A, S(-1)) == push!(jlA, S(-1))

            @test length(A) == length(jlA)
            @test A == jlA

            A = pm_Set(T[1,2,3,1,2,3])
            jlA = Set(T[1,2,3,1,2,3])

            @test delete!(A, S(1)) == delete!(jlA, S(1))
            @test delete!(A, S(1)) == delete!(jlA, S(1))

            @test A == jlA

            @test pop!(A, S(2)) == pop!(jlA, S(2))
            @test pop!(A, S(2)) == pop!(jlA, S(2))

            @test A == jlA
            @test isempty(A) == isempty(jlA)
            @test pop!(A, S(3)) == pop!(jlA, S(3))
            @test isempty(A) == isempty(jlA)

            @test push!(A, S(4)) == push!(jlA, S(4))
            @test isempty(A) == isempty(jlA)

            @test pop!(A, S(3), 2) == pop!(jlA, S(3), 2)
            @test pop!(A, S(3), 2) != pop!(jlA, S(4), 2)
            @test A != jlA
        end
    end

    @testset "operations" begin
        for T in IntTypes

            A_orig, B_orig = pm_Set(T[1,2,3]), pm_Set(T[2,3,4])

            @testset "union $T" begin
                let A = pm_Set(T[1,2,3]), B = pm_Set(T[2,3,4])
                    jlA, jlB = Set(A), Set(B)
                    @test union(A,A) == union(jlA,jlA)
                    @test union(A,B) == union(jlA,jlB) == Set([1,2,3,4])
                    @test A == A_orig == jlA

                    # union!
                    @test union!(A,A) == union!(jlA,jlA)
                    @test A == jlA

                    @test union!(A,B) == union!(jlA, jlB)
                    @test A == jlA
                    @test B == jlB
                    @test union!(B,A) == union!(jlB, jlA)
                    @test B == jlB
                    @test (A == B) == (jlA == jlB)
                end
            end

            @testset "intersect $T" begin
                let A = pm_Set(T[1,2,3]), B = pm_Set(T[2,3,4])
                    jlA, jlB = Set(A), Set(B)

                    @test A == intersect(A,A) == intersect(jlA, jlA)
                    @test intersect(A, B) == intersect(jlA, jlB)
                    @test A == jlA
                    @test B == jlB

                    # intersect!
                    @test_broken intersect!(A, B) == intersect!(jlA, jlB)
                    @test A == Set([2,3])# == jlA
                    @test B == jlB
                    @test_broken intersect!(B, A) == intersect!(jlB, jlA)
                    @test B == Set([2,3])# == jlB
                    @test_broken (A == B) == (jlA == jlB)
                end
            end

            @testset "setdiff $T" begin
                let A = pm_Set(T[1,2,3]), B = pm_Set(T[2,3,4])
                    jlA, jlB = Set(A), Set(B)
                    @test isempty(setdiff(A,A)) == isempty(setdiff(jlA, jlA))
                    @test A == jlA
                    @test setdiff(A, B) == setdiff(jlA, jlB))
                    @test setdiff(B, A) == setdiff(jlB, jlA))
                    @test A == jlA
                    @test B == jlB

                    @test setdiff!(A, B) == setdiff!(jlA, jlB)
                    @test A == jlA
                    @test B == jlB

                    @test setdiff!(B, A) == setdiff!(jlB,jlA)
                    @test B == jlB

                    A = deepcopy(A_orig)
                    jlA = Set(A)
                    @test setdiff!(B,A) == setdiff!(jlB, jlA)
                    @test B == jlB
                    @test A == jlA
                end
            end

            @testset "symdiff $T" begin
                let A = pm_Set(T[1,2,3]), B = pm_Set(T[2,3,4])
                    jlA, jlB = Set(A), Set(B)
                    @test isempty(symdiff(A,A)) == isempty(symdiff(jlA,jlA))
                    @test isempty(symdiff(A,B)) == isempty(symdiff(jlA,jlB))
                    @test symdiff(A,B) == symdiff(jlA, jlB)
                    @test symdiff(B,A) == symdiff(jlA, jlB)

                    jlA1 = deepcopy(jlA)

                    @test_broken symdiff!(A, B) == symdiff!(jlA, jlB)
                    @test Set(A) == Set([1,4])# == jlA
                    @test Set(B) == Set([2,3,4])# == jlB

                    @test_broken symdiff!(A, B) == symdiff!(jlA, jlB)
                    @test A == jlA1
                end
            end
        end
    end

    @testset "user_constructors" begin
        for T in IntTypes
            @test PolymakeWrap.range(T(-1), T(5)) == pm_Set(collect(-1:5))
            @test PolymakeWrap.sequence(T(-1), T(5)) == pm_Set(collect(-1:3))
            @test PolymakeWrap.scalar2set(T(-10)) == pm_Set([-10])
        end
    end
end
