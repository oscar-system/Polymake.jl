@testset "pm_Set" begin
    IntTypes = [Int32, Int64]

    @testset "constructors" begin
        for T in IntTypes
            @test pm_Set{T}() isa pm_Set
            @test pm_Set{T}() isa AbstractSet
            @test pm_Set(T[1]) isa pm_Set{T}
            @test pm_Set(T[1,1]) isa pm_Set{T}
            @test pm_Set(T[-1,1]) isa pm_Set{T}
            @test pm_Set(Set{T}([-1,1])) isa pm_Set{T}
        end
        for T in IntTypes, S in IntTypes
            @test pm_Set{T}(S[-1,1]) isa pm_Set{T}
            @test pm_Set{T}(Set(S[-1,1])) isa pm_Set{T}
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

            @test length(Set([pm_Set(T[1,2,3]), pm_Set(T[1,2,3])])) == 1
            A = Set([pm_Set(T[1,2,3]), pm_Set(T[1,2,3])])
            @test first(A) == Set([1,2,3])
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
            @test incl(pm_Set(S[1]), pm_Set(T[1])) == 0
            @test incl(pm_Set(S[1]), pm_Set(T[1,2])) == -1
            @test incl(pm_Set(S[1,2]), pm_Set(T[1])) == 1
            @test incl(pm_Set(S[1,2]), pm_Set(T[1,3])) == 2

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
            swap(A, B)

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
            jlA = Set(T[1,2,3,1,2,3])

            @test S(2) in A
            @test !(S(5) in A)

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
            @test_throws KeyError pop!(A, S(2))
            @test_throws KeyError pop!(jlA, S(2))

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
                    @test A == jlA && B == jlB
                    @test union(jlA, A) isa Set
                    @test union(A, jlA) isa Set

                    # union!
                    @test union!(A,A) == union!(jlA,jlA)
                    @test A == jlA

                    @test union!(A,B) == union!(jlA, jlB)
                    @test A == jlA && B == jlB
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
                    @test A == jlA && B == jlB

                    @test intersect(jlA, A) isa Set
                    @test intersect(A, jlA) isa Set

                    # intersect!
                    @test intersect!(A, B) == intersect!(jlA, jlB)
                    @test A == Set([2,3])# == jlA
                    @test B == jlB
                    @test intersect!(B, A) == intersect!(jlB, jlA)
                    @test B == Set([2,3])# == jlB

                    @test (A == B) == (jlA == jlB)
                end
            end

            @testset "setdiff $T" begin
                let A = pm_Set(T[1,2,3]), B = pm_Set(T[2,3,4])
                    jlA, jlB = Set(A), Set(B)
                    @test isempty(setdiff(A,A)) == isempty(setdiff(jlA, jlA))
                    @test A == jlA
                    @test setdiff(A, B) == setdiff(jlA, jlB)
                    @test setdiff(B, A) == setdiff(jlB, jlA)
                    @test A == jlA && B == jlB
                    @test setdiff(jlA, A) isa Set
                    @test setdiff(A, jlA) isa Set

                    @test setdiff!(A, B) == setdiff!(jlA, jlB)
                    @test A == jlA && B == jlB

                    @test setdiff!(B, A) == setdiff!(jlB,jlA)
                    @test A == jlA && B == jlB

                    A = deepcopy(A_orig)
                    jlA = Set(A)
                    @test setdiff!(B,A) == setdiff!(jlB, jlA)
                    @test A == jlA && B == jlB

                    @test (A == B) == (jlA == jlB)
                end
            end

            @testset "symdiff $T" begin
                let A = pm_Set(T[1,2,3]), B = pm_Set(T[2,3,4])
                    jlA, jlB = Set(A), Set(B)
                    @test isempty(symdiff(A,A)) == isempty(symdiff(jlA,jlA))
                    @test isempty(symdiff(A,B)) == isempty(symdiff(jlA,jlB))
                    @test symdiff(A,B) == symdiff(jlA, jlB)
                    @test symdiff(B,A) == symdiff(jlA, jlB)
                    @test symdiff(jlA, A) isa Set
                    @test symdiff(A, jlA) isa Set

                    jlA1 = deepcopy(jlA)

                    @test symdiff!(A, B) == symdiff!(jlA, jlB)
                    @test Set(A) == Set([1,4])# == jlA
                    @test Set(B) == Set([2,3,4])# == jlB

                    @test symdiff!(A, B) == symdiff!(jlA, jlB)

                    @test A == jlA && B == jlB
                    @test (A == B) == (jlA == jlB)
                end
            end
        end
    end

    @testset "polymake constructors" begin
        for T in IntTypes
            @test Polymake.range(T(-1), T(5)) == pm_Set(collect(-1:5))
            @test Polymake.sequence(T(-1), T(5)) == pm_Set(collect(-1:3))
            @test Polymake.scalar2set(T(-10)) == pm_Set([-10])
        end
    end
end

@testset "julia Sets compatibility" begin

    @testset "Construction" begin
        let f17741 = x -> x < 0 ? 0 : 1
            @test isa(pm_Set(x for x = 1:3), pm_Set{Int})
            @test isa(pm_Set(x for x = 1:3 for j = 1:1), pm_Set{Int})
            @test isa(pm_Set(f17741(x) for x = 1:3), pm_Set{Int})
            @test isa(pm_Set(f17741(x) for x = -1:1), AbstractSet)
        end
        let s1 = pm_Set([1, 2]), s2 = pm_Set(s1)
            @test s1 == s2
            x = pop!(s1)
            @test s1 != s2
            @test !(x in s1)
            @test x in s2
            push!(s1, 3)
            push!(s2, 4)
            @test 3 in s1
            @test !(3 in s2)
            @test !(4 in s1)
            @test 4 in s2
        end
    end

    @testset "hash" begin
        s1 = pm_Set([1, 2, 1])
        s2 = pm_Set([2, 1, 1])
        s3 = pm_Set([3])
        @test hash(s1) == hash(s2)
        @test hash(s1) != hash(s3)
        d1 = Dict(pm_Set([3]) => 33, pm_Set([2]) => 22)
        d2 = Dict(pm_Set([2]) => 33, pm_Set([3]) => 22)
        @test hash(d1) != hash(d2)
    end

    @testset "equality" for eq in (isequal, ==)
        for T in [Int32, Int64]
            @test  eq(pm_Set{T}(), pm_Set{T}())
            @test !eq(pm_Set{T}(), pm_Set(T[1]))
            @test  eq(pm_Set{T}([1,2]), pm_Set(T[1,2]))
            @test !eq(pm_Set{T}([1,2]), pm_Set{T}([1,2,3]))
        end

        # Comparison of unrelated types
        for T in [Int32, Int64]
            @test  eq(pm_Set{T}(), pm_Set{Int}())
            @test !eq(pm_Set{T}(), pm_Set{Int}([1]))
            @test !eq(pm_Set{T}([1]), pm_Set{Int}())
            @test  eq(pm_Set{T}([1,2,3]), pm_Set([1,2,3]))

            @test !eq(pm_Set{T}([1,2,3]), pm_Set{Int}([1,2,3,4]))
            @test !eq(pm_Set{T}([1,2,3,4]), pm_Set{Int}([1,2,3]))
        end
    end

    @testset "eltype, empty" begin
        s1 = empty(pm_Set([1,2]))
        @test isequal(s1, pm_Set{Int}())
        @test ===(eltype(s1), Int)
        s2 = empty(pm_Set{Int}([2.0,3.0,4.0]))
        @test isequal(s2, pm_Set{Int}())
        @test ===(eltype(s2), Int)
        s3 = empty(pm_Set([1,2]),Int32)
        @test isequal(s3, pm_Set{Int32}())
        @test ===(eltype(s3), Int32)
    end

    @testset "isempty, length, in, push, pop, delete" begin
        # also test for no duplicates
        s = pm_Set{Int}(); push!(s,1); push!(s,2); push!(s,3)
        @test !isempty(s)
        @test in(1,s)
        @test in(2,s)
        @test length(s) == 3
        push!(s,1); push!(s,2); push!(s,3)
        @test length(s) == 3
        @test pop!(s,1) == 1
        @test !in(1,s)
        @test in(2,s)
        @test length(s) == 2
        @test_throws KeyError pop!(s,1)
        @test pop!(s,1,:foo) == :foo
        @test length(delete!(s,2)) == 1
        @test !in(1,s)
        @test !in(2,s)
        @test pop!(s) == 3
        @test length(s) == 0
        @test isempty(s)
        @test_throws ArgumentError pop!(s)
        @test length(pm_Set([2,120])) == 2
    end

    @testset "copy" begin
        data_in = (1,2,9,8,4)
        s = pm_Set(data_in)
        c = copy(s)
        @test isequal(s,c)
        v = pop!(s)
        @test !in(v,s)
        @test  in(v,c)
        push!(s,100)
        push!(c,200)
        @test !in(100,c)
        @test !in(200,s)
    end

    @testset "sizehint, empty" begin
        s = pm_Set([1])
        @test isequal(sizehint!(s, 10), pm_Set([1]))
        @test isequal(empty!(s), pm_Set{Int}())
    end

    @testset "iteration" begin
        x = (7, 8, 4, 5, 4, 8)
        for data_in = [x, Set(x), collect(x)]
            s = pm_Set(data_in)

            s_new = pm_Set{Int}()
            for el in s
                push!(s_new, el)
            end
            @test isequal(s, s_new)

            t = tuple(s...)
            @test length(t) == length(s)
            for e in t
                @test in(e,s)
            end
        end
    end

    @testset "union" begin
        S = pm_Set{Int}
        s = ∪(S([1,2]), S([3,4]))
        @test s == S([1,2,3,4])
        s = union(S([5,6,7,8]), S([7,8,9]))
        @test s == S([5,6,7,8,9])
        s = S([1,3,5,7])
        union!(s, (2,3,4,5))
        @test s == S([1,3,5,7,2,4])
        let s1 = S([1, 2, 3])
            @test s1 !== union(s1) == s1
            @test s1 !== union(s1, 2:4) == S([1,2,3,4])
            @test s1 !== union(s1, [2,3,4]) == S([1,2,3,4])
            @test s1 !== union(s1, [2,3,4], S([5])) == S([1,2,3,4,5])
            @test s1 === union!(s1, [2,3,4], S([5])) == S([1,2,3,4,5])
        end

        @test union(S([1]), S()) isa S
        @test union(S(Int[]), S()) isa S
        @test union([1], S()) isa Vector{Int}
    end

    @testset "intersect" begin
        S = pm_Set{Int}
        s = S([1,2]) ∩ S([3,4])
        @test s == S()
        s = intersect(S([5,6,7,8]), S([7,8,9]))
        @test s == S([7,8])
        @test intersect(S([2,3,1]), S([4,2,3]), S([5,4,3,2])) == S([2,3])
        let s1 = S([1,2,3])
            @test s1 !== intersect(s1) == s1
            @test s1 !== intersect(s1, 2:10) == S([2,3])
            @test s1 !== intersect(s1, [2,3,4]) == S([2,3])
            @test s1 !== intersect(s1, [2,3,4], 3:4) == S([3])
            @test s1 === intersect!(s1, [2,3,4], 3:4) == S([3])
        end

        @test intersect(S([1]), S()) isa S
        @test intersect(S(), S([])) isa S
        @test intersect([1], S()) isa Vector{Int}
    end

    @testset "setdiff" begin
        S = pm_Set{Int}
        @test setdiff(S([1,2,3]), S())        == S([1,2,3])
        @test setdiff(S([1,2,3]), S([1]))     == S([2,3])
        @test setdiff(S([1,2,3]), S([1,2]))   == S([3])
        @test setdiff(S([1,2,3]), S([1,2,3])) == S()
        @test setdiff(S([1,2,3]), S([4]))     == S([1,2,3])
        @test setdiff(S([1,2,3]), S([4,1]))   == S([2,3])
        let s1 = S([1, 2, 3])
            @test s1 !== setdiff(s1) == s1
            @test s1 !== setdiff(s1, 2:10) == S([1])
            @test s1 !== setdiff(s1, [2,3,4]) == S([1])
            @test s1 !== setdiff(s1, S([2,3,4]), S([1])) == S()
            @test s1 === setdiff!(s1, S([2,3,4]), S([1])) == S()
        end

        @test setdiff(S([1]), S()) isa S
        @test setdiff(S([1]), S([])) isa S
        @test setdiff([1], S()) isa Vector{Int}

        s = S([1,3,5,7])
        setdiff!(s,(3,5))
        @test isequal(s,Set([1,7]))
        s = S([1,2,3,4])
        setdiff!(s, Set([2,4,5,6]))
        @test isequal(s,Set([1,3]))
    end

    @testset "ordering" begin
        S = pm_Set{Int}
        @test S() < S([1])
        @test S([1]) < S([1,2])
        @test !(S([3]) < S([1,2]))
        @test !(S([3]) > S([1,2]))
        @test S([1,2,3]) > S([1,2])
        @test !(S([3]) <= S([1,2]))
        @test !(S([3]) >= S([1,2]))
        @test S([1]) <= S([1,2])
        @test S([1,2]) <= S([1,2])
        @test S([1,2]) >= S([1,2])
        @test S([1,2,3]) >= S([1,2])
        @test !(S([1,2,3]) >= S([1,2,4]))
        @test !(S([1,2,3]) <= S([1,2,4]))
    end

    @testset "issubset, symdiff" begin
        S = pm_Set{Int}
        for (l,r) in ((S([1,2]),     S([3,4])),
                      (S([5,6,7,8]), S([7,8,9])),
                      (S([1,2]),     S([3,4])),
                      (S([5,6,7,8]), S([7,8,9])),
                      (S([1,2,3]),   S()),
                      (S([1,2,3]),   S([1])),
                      (S([1,2,3]),   S([1,2])),
                      (S([1,2,3]),   S([1,2,3])),
                      (S([1,2,3]),   S([4])),
                      (S([1,2,3]),   S([4,1])))
            @test issubset(intersect(l,r), l)
            @test issubset(intersect(l,r), r)
            @test issubset(l, union(l,r))
            @test issubset(r, union(l,r))
            @test union(intersect(l,r),symdiff(l,r)) == union(l,r)
        end
        @test ⊆(S([1]), S([1,2]))
        @test ⊊(S([1]), S([1,2]))
        @test !⊊(S([1]), S([1]))
        @test ⊈(S([1]), S([2]))
        @test ⊇(S([1,2]), S([1]))
        @test ⊋(S([1,2]), S([1]))
        @test !⊋(S([1]), S([1]))
        @test ⊉(S([1]), S([2]))

        let s1 = S([1,2,3,4])
            @test s1 !== symdiff(s1) == s1
            @test s1 !== symdiff(s1, S([2,4,5,6])) == S([1,3,5,6])
            @test s1 !== symdiff(s1, S([2,4,5,6]), [1,6,7]) == S([3,5,7])
            @test s1 === symdiff!(s1, S([2,4,5,6]), [1,6,7]) == S([3,5,7])
        end
        @test symdiff(S([1,2,3,4]), S([2,4,5,6])) == S([1,3,5,6])
        @test symdiff(S([1]), S()) isa S
        @test symdiff(S([]), S()) isa S
        @test symdiff([1], S()) isa Vector{Int}
    end

    @testset "filter(f, ::pm_Set), first" begin
        S = pm_Set{Int}
        s = S([1,2,3,4])
        @test s !== filter( isodd, s) == S([1,3])
        @test s === filter!(isodd, s) == S([1,3])
        @test_throws ArgumentError first(S())
        @test first(S(2)) == 2
    end

    @testset "pop!" begin
        s = pm_Set(1:5)
        @test 2 in s
        @test pop!(s, 2) == 2
        @test !(2 in s)
        @test_throws KeyError pop!(s, 2)
        @test pop!(s, 2, ()) == ()
        @test 3 in s
        @test pop!(s, 3, ()) == 3
        @test !(3 in s)
        @test pop!(Set(1:2), 2, nothing) == 2
    end

    @testset "replace! & replace" begin
        s = pm_Set([1, 2, 3])
        @test replace(x -> x > 1 ? 2x : x, s) == pm_Set([1, 4, 6])
        for count = (1, 0x1, big(1))
            @test replace(x -> x > 1 ? 2x : x, s, count=count) in [pm_Set([1, 4, 3]), pm_Set([1, 2, 6])]
        end
        @test replace(s, 1=>4) == pm_Set([2, 3, 4])
        @test replace!(s, 1=>2) === s
        @test s == pm_Set([2, 3])
        @test replace!(x->2x, s, count=0x1) in [pm_Set([4, 3]), pm_Set([2, 6])]

        # test collisions with AbstractSet/AbstractDict
        @test replace!(x->2x, pm_Set([3, 6])) == pm_Set([6, 12])
        @test replace!(x->2x, pm_Set([1:20;])) == pm_Set([2:2:40;])
    end

    @testset "⊆, ⊊, ⊈, ⊇, ⊋, ⊉, <, <=, issetequal" begin
        a = [1, 2]
        b = [2, 1, 3]
        for C = (pm_Set{Int64}, pm_Set{Int32})
            A = C(a)
            B = C(b)
            @test A ⊆ B
            @test A ⊊ B
            @test !(A ⊈ B)
            @test !(A ⊇ B)
            @test !(A ⊋ B)
            @test A ⊉ B
            @test !(B ⊆ A)
            @test !(B ⊊ A)
            @test B ⊈ A
            @test B ⊇ A
            @test B ⊋ A
            @test !(B ⊉ A)
            @test !issetequal(A, B)
            @test !issetequal(B, A)
            @test A <= B
            @test A <  B
            @test !(A >= B)
            @test !(A >  B)
            @test !(B <= A)
            @test !(B <  A)
            @test B >= A
            @test B >  A

            for D = (pm_Set{Int64}, pm_Set{Int32})
                @test issetequal(A, D(A))
                @test !issetequal(A, D(B))
            end
        end
    end
end
