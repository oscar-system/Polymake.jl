@testset "Polymake.Set" begin
    IntTypes = [Int64]

    @testset "constructors" begin
        for T in IntTypes
            @test Polymake.Set{T}() isa Polymake.Set
            @test Polymake.Set{T}() isa AbstractSet
            @test Polymake.Set(T[1]) isa Polymake.Set{T}
            @test Polymake.Set(T[1,1]) isa Polymake.Set{T}
            @test Polymake.Set(T[-1,1]) isa Polymake.Set{T}
            @test Polymake.Set(Polymake.Set{T}([-1,1])) isa Polymake.Set{T}
        end
        for T in IntTypes, S in IntTypes
            @test Polymake.Set{T}(S[-1,1]) isa Polymake.Set{T}
            @test Polymake.Set{T}(Polymake.Set(S[-1,1])) isa Polymake.Set{T}
            @test Polymake.Set{T}(Polymake.Set(S[1,2])) isa Polymake.Set{T}
        end
    end

    @testset "equality" begin
        for T in IntTypes, S in IntTypes
            @test Polymake.Set{S}() == Polymake.Set{T}()
            @test Polymake.Set(T[1]) == Polymake.Set(S[1,1])
            @test Polymake.Set(T[2,2,1,1]) == Polymake.Set(S[1,2,1])
            @test Polymake.Set(T[1]) != Polymake.Set(S[2])

            A = deepcopy(Polymake.Set(T[1]))
            @test A == Polymake.Set(S[1])

            @test length(Polymake.Set([Polymake.Set(T[1,2,3]), Polymake.Set(T[1,2,3])])) == 1
            A = Polymake.Set([Polymake.Set(T[1,2,3]), Polymake.Set(T[1,2,3])])
            @test first(A) == Polymake.Set([1,2,3])
        end
    end

    @testset "conversions" begin
        for T in IntTypes
            A = Polymake.Set(T[1,2,3,1,2,3])

            @test Polymake.Vector(A) isa Polymake.Vector{T}
            @test Polymake.Vector(A) == [1,2,3]
            @test Polymake.Vector{Float64}(A) == [1.0,2.0,3.0]

            @test Polymake.Set(A) isa Polymake.Set{T}
            @test Polymake.Set(A) == Polymake.Set([1,2,3])
            @test Polymake.Set{Float64}(A) == Polymake.Set([1.0,2.0,3.0])

            for S in IntTypes
                @test Polymake.Vector{S}(A) isa Polymake.Vector{S}
                @test Polymake.Set{S}(A) isa Polymake.Set{S}
            end
        end
    end


    @testset "relations" begin

        for T in IntTypes, S in IntTypes
            @test incl(Polymake.Set(S[1]), Polymake.Set(T[1])) == 0
            @test incl(Polymake.Set(S[1]), Polymake.Set(T[1,2])) == -1
            @test incl(Polymake.Set(S[1,2]), Polymake.Set(T[1])) == 1
            @test incl(Polymake.Set(S[1,2]), Polymake.Set(T[1,3])) == 2

            # <, <=, == are based on incl; just test that they agree with the julia versions
            @test (Polymake.Set{S}() < Polymake.Set{T}()) == (Polymake.Set{S}() < Polymake.Set{T}())
            @test (Polymake.Set{T}() < Polymake.Set(S[1])) == (Polymake.Set{T}() < Polymake.Set(S[1]))
            @test (Polymake.Set(S[1]) < Polymake.Set(T[1,2])) == (Polymake.Set(S[1]) < Polymake.Set(T[1,2]))
            @test (Polymake.Set(S[1,2]) < Polymake.Set(T[1])) == (Polymake.Set(S[1,2]) < Polymake.Set(T[1]))
            @test (Polymake.Set(S[1,2]) < Polymake.Set(T[1,3]))==(Polymake.Set(S[1,2]) < Polymake.Set(T[1,3]))

            @test (Polymake.Set{S}() <= Polymake.Set{T}()) == (Polymake.Set{S}() <= Polymake.Set{T}())
            @test (Polymake.Set{T}() <= Polymake.Set(S[1])) == (Polymake.Set{T}() <= Polymake.Set(S[1]))
            @test (Polymake.Set(S[1]) <= Polymake.Set(T[1,2])) == (Polymake.Set(S[1]) <= Polymake.Set(T[1,2]))
            @test (Polymake.Set(S[1,2]) <= Polymake.Set(T[1])) == (Polymake.Set(S[1,2]) <= Polymake.Set(T[1]))
            @test (Polymake.Set(S[1,2])<=pm_Polymake.Set(T[1,3]))==(Polymake.Set(S[1,2])<=Polymake.Set(T[1,3]))
        end
    end

    @testset "basic functionality" begin
        for T in IntTypes
            A = Polymake.Set(T[1,2,3,1])
            B = Polymake.Set(T[5,6,6])

            A1 = deepcopy(A)
            swap(A, B)

            @test A == Polymake.Set([5,6])
            @test B == Polymake.Set([1,2,3])
            @test A1 == B

            A = Polymake.Set(T[1,2,3,1])
            jlA = Polymake.Set(T[1,2,3,1])

            B = Polymake.Set(T[5,6,6])
            jlB = Polymake.Set(T[5,6,6])

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

            A = Polymake.Set(T[1,2,3,1,2,3])
            b = Polymake.Set(T[5,6,6])
            @test length(A) == length(Polymake.Set([1,2,3,1,2,3]))
            @test length(B) == length(Polymake.Set([5,6,6]))
        end
    end

    @testset "elements operations" begin
        for T in IntTypes, S in IntTypes
            A = Polymake.Set(T[3,2,1,3,2,1])
            jlA = Polymake.Set(T[1,2,3,1,2,3])

            @test S(2) in A
            @test !(S(5) in A)

            @test push!(A, S(3)) == push!(jlA, S(3))
            @test push!(A, S(-1)) == push!(jlA, S(-1))
            @test (-1 in A) == (-1 in jlA)
            @test push!(A, S(-1)) == push!(jlA, S(-1))

            @test length(A) == length(jlA)
            @test A == jlA

            A = Polymake.Set(T[1,2,3,1,2,3])
            jlA = Polymake.Set(T[1,2,3,1,2,3])

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

            A_orig, B_orig = Polymake.Set(T[1,2,3]), Polymake.Set(T[2,3,4])

            @testset "union $T" begin
                let A = Polymake.Set(T[1,2,3]), B = Polymake.Set(T[2,3,4])
                    jlA, jlB = Polymake.Set(A), Polymake.Set(B)
                    @test union(A,A) == union(jlA,jlA)
                    @test union(A,B) == union(jlA,jlB) == Polymake.Set([1,2,3,4])
                    @test A == jlA && B == jlB
                    @test union(jlA, A) isa Polymake.Set
                    @test union(A, jlA) isa Polymake.Set

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
                let A = Polymake.Set(T[1,2,3]), B = Polymake.Set(T[2,3,4])
                    jlA, jlB = Polymake.Set(A), Polymake.Set(B)

                    @test A == intersect(A,A) == intersect(jlA, jlA)
                    @test intersect(A, B) == intersect(jlA, jlB)
                    @test A == jlA && B == jlB

                    @test intersect(jlA, A) isa Polymake.Set
                    @test intersect(A, jlA) isa Polymake.Set

                    # intersect!
                    @test intersect!(A, B) == intersect!(jlA, jlB)
                    @test A == Polymake.Set([2,3])# == jlA
                    @test B == jlB
                    @test intersect!(B, A) == intersect!(jlB, jlA)
                    @test B == Polymake.Set([2,3])# == jlB

                    @test (A == B) == (jlA == jlB)
                end
            end

            @testset "setdiff $T" begin
                let A = Polymake.Set(T[1,2,3]), B = Polymake.Set(T[2,3,4])
                    jlA, jlB = Polymake.Set(A), Polymake.Set(B)
                    @test isempty(setdiff(A,A)) == isempty(setdiff(jlA, jlA))
                    @test A == jlA
                    @test setdiff(A, B) == setdiff(jlA, jlB)
                    @test setdiff(B, A) == setdiff(jlB, jlA)
                    @test A == jlA && B == jlB
                    @test setdiff(jlA, A) isa Polymake.Set
                    @test setdiff(A, jlA) isa Polymake.Set

                    @test setdiff!(A, B) == setdiff!(jlA, jlB)
                    @test A == jlA && B == jlB

                    @test setdiff!(B, A) == setdiff!(jlB,jlA)
                    @test A == jlA && B == jlB

                    A = deepcopy(A_orig)
                    jlA = Polymake.Set(A)
                    @test setdiff!(B,A) == setdiff!(jlB, jlA)
                    @test A == jlA && B == jlB

                    @test (A == B) == (jlA == jlB)
                end
            end

            @testset "symdiff $T" begin
                let A = Polymake.Set(T[1,2,3]), B = Polymake.Set(T[2,3,4])
                    jlA, jlB = Polymake.Set(A), Polymake.Set(B)
                    @test isempty(symdiff(A,A)) == isempty(symdiff(jlA,jlA))
                    @test isempty(symdiff(A,B)) == isempty(symdiff(jlA,jlB))
                    @test symdiff(A,B) == symdiff(jlA, jlB)
                    @test symdiff(B,A) == symdiff(jlA, jlB)
                    @test symdiff(jlA, A) isa Polymake.Set
                    @test symdiff(A, jlA) isa Polymake.Set

                    jlA1 = deepcopy(jlA)

                    @test symdiff!(A, B) == symdiff!(jlA, jlB)
                    @test Polymake.Set(A) == Polymake.Set([1,4])# == jlA
                    @test Polymake.Set(B) == Polymake.Set([2,3,4])# == jlB

                    @test symdiff!(A, B) == symdiff!(jlA, jlB)

                    @test A == jlA && B == jlB
                    @test (A == B) == (jlA == jlB)
                end
            end
        end
    end

    @testset "polymake constructors" begin
        for T in IntTypes
            @test Polymake.range(T(-1), T(5)) == Polymake.Set(collect(-1:5))
            @test Polymake.sequence(T(-1), T(5)) == Polymake.Set(collect(-1:3))
            @test Polymake.scalar2set(T(-10)) == Polymake.Set([-10])
        end
    end
end

@testset "julia Polymake.Sets compatibility" begin

    @testset "Construction" begin
        let f17741 = x -> x < 0 ? 0 : 1
            @test isa(Polymake.Set(x for x = 1:3), Polymake.Set{Polymake.Int})
            @test isa(Polymake.Set(x for x = 1:3 for j = 1:1), Polymake.Set{Polymake.Int})
            @test isa(Polymake.Set(f17741(x) for x = 1:3), Polymake.Set{Polymake.Int})
            @test isa(Polymake.Set(f17741(x) for x = -1:1), AbstractSet)
        end
        let s1 = Polymake.Set([1, 2]), s2 = Polymake.Set(s1)
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
        s1 = Polymake.Set([1, 2, 1])
        s2 = Polymake.Set([2, 1, 1])
        s3 = Polymake.Set([3])
        @test hash(s1) == hash(s2)
        @test hash(s1) != hash(s3)
        d1 = Dict(Polymake.Set([3]) => 33, Polymake.Set([2]) => 22)
        d2 = Dict(Polymake.Set([2]) => 33, Polymake.Set([3]) => 22)
        @test hash(d1) != hash(d2)
    end

    @testset "equality" for eq in (isequal, ==)
        for T in [Int64]
            @test  eq(Polymake.Set{T}(), Polymake.Set{T}())
            @test !eq(Polymake.Set{T}(), Polymake.Set(T[1]))
            @test  eq(Polymake.Set{T}([1,2]), Polymake.Set(T[1,2]))
            @test !eq(Polymake.Set{T}([1,2]), Polymake.Set{T}([1,2,3]))
        end

        # Comparison of unrelated types
        for T in [Int64]
            @test  eq(Polymake.Set{T}(), Polymake.Set{Polymake.Int}())
            @test !eq(Polymake.Set{T}(), Polymake.Set{Polymake.Int}([1]))
            @test !eq(Polymake.Set{T}([1]), Polymake.Set{Polymake.Int}())
            @test  eq(Polymake.Set{T}([1,2,3]), Polymake.Set([1,2,3]))

            @test !eq(Polymake.Set{T}([1,2,3]), Polymake.Set{Polymake.Int}([1,2,3,4]))
            @test !eq(Polymake.Set{T}([1,2,3,4]), Polymake.Set{Polymake.Int}([1,2,3]))
        end
    end

    @testset "eltype, empty" begin
        s1 = empty(Polymake.Set([1,2]))
        @test isequal(s1, Polymake.Set{Polymake.Int}())
        @test ===(eltype(s1), Polymake.Int)
        s2 = empty(Polymake.Set{Polymake.Int}([2.0,3.0,4.0]))
        @test isequal(s2, Polymake.Set{Polymake.Int}())
        @test ===(eltype(s2), Polymake.Int)
        s3 = empty(Polymake.Set([1,2]),Int64)
        @test isequal(s3, Polymake.Set{Int64}())
        @test ===(eltype(s3), Int64)
    end

    @testset "isempty, length, in, push, pop, delete" begin
        # also test for no duplicates
        s = Polymake.Set{Polymake.Int}(); push!(s,1); push!(s,2); push!(s,3)
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
        @test length(Polymake.Set([2,120])) == 2
    end

    @testset "copy" begin
        data_in = (1,2,9,8,4)
        s = Polymake.Set(data_in)
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
        s = Polymake.Set([1])
        @test isequal(sizehint!(s, 10), Polymake.Set([1]))
        @test isequal(empty!(s), Polymake.Set{Polymake.Int}())
    end

    @testset "iteration" begin
        x = (7, 8, 4, 5, 4, 8)
        for data_in = [x, Polymake.Set(x), collect(x)]
            s = Polymake.Set(data_in)

            s_new = Polymake.Set{Polymake.Int}()
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
        S = Polymake.Set{Polymake.Int}
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
        @test union(S(Polymake.Int[]), S()) isa S
        @test union([1], S()) isa Polymake.Vector{Polymake.Int}
    end

    @testset "intersect" begin
        S = Polymake.Set{Polymake.Int}
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
        @test intersect([1], S()) isa Polymake.Vector{Polymake.Int}
    end

    @testset "setdiff" begin
        S = Polymake.Set{Polymake.Int}
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
        @test setdiff([1], S()) isa Polymake.Vector{Polymake.Int}

        s = S([1,3,5,7])
        setdiff!(s,(3,5))
        @test isequal(s,Polymake.Set([1,7]))
        s = S([1,2,3,4])
        setdiff!(s, Polymake.Set([2,4,5,6]))
        @test isequal(s,Polymake.Set([1,3]))
    end

    @testset "ordering" begin
        S = Polymake.Set{Polymake.Int}
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
        S = Polymake.Set{Polymake.Int}
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
        @test symdiff([1], S()) isa Polymake.Vector{Polymake.Int}
    end

    @testset "filter(f, ::pm_Polymake.Set), first" begin
        S = Polymake.Set{Polymake.Int}
        s = S([1,2,3,4])
        @test s !== filter( isodd, s) == S([1,3])
        @test s === filter!(isodd, s) == S([1,3])
        @test_throws ArgumentError first(S())
        @test first(S(2)) == 2
    end

    @testset "pop!" begin
        s = Polymake.Set(1:5)
        @test 2 in s
        @test pop!(s, 2) == 2
        @test !(2 in s)
        @test_throws KeyError pop!(s, 2)
        @test pop!(s, 2, ()) == ()
        @test 3 in s
        @test pop!(s, 3, ()) == 3
        @test !(3 in s)
        @test pop!(Polymake.Set(1:2), 2, nothing) == 2
    end

    @testset "replace! & replace" begin
        s = Polymake.Set([1, 2, 3])
        @test replace(x -> x > 1 ? 2x : x, s) == Polymake.Set([1, 4, 6])
        for count = (1, 0x1, big(1))
            @test replace(x -> x > 1 ? 2x : x, s, count=count) in [Polymake.Set([1, 4, 3]), Polymake.Set([1, 2, 6])]
        end
        @test replace(s, 1=>4) == Polymake.Set([2, 3, 4])
        @test replace!(s, 1=>2) === s
        @test s == Polymake.Set([2, 3])
        @test replace!(x->2x, s, count=0x1) in [Polymake.Set([4, 3]), Polymake.Set([2, 6])]

        # test collisions with AbstractSet/AbstractDict
        @test replace!(x->2x, Polymake.Set([3, 6])) == Polymake.Set([6, 12])
        @test replace!(x->2x, Polymake.Set([1:20;])) == Polymake.Set([2:2:40;])
    end

    @testset "⊆, ⊊, ⊈, ⊇, ⊋, ⊉, <, <=, issetequal" begin
        a = [1, 2]
        b = [2, 1, 3]
        for C = (Polymake.Set{Int64})
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

            for D = (Polymake.Set{Int64})
                @test issetequal(A, D(A))
                @test !issetequal(A, D(B))
            end
        end
    end
end
