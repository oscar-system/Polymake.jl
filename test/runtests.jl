using PolymakeWrap
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

# write your own tests here
@testset "pm_Set" begin
    pmSet = PolymakeWrap.Polymake.pm_Set
    @test_broken pmSet() isa PolymakeWrap.Polymake.pm_Set
    @test_broken pmSet() isa PolymakeWrap.Polymake.pm_SetAllocated

    IntTypes = [(Int32, :int), (Int64, :long)]
    for (T, symb) in IntTypes
        info(T)
        @test pmSet(T[1]) isa PolymakeWrap.Polymake.pm_Set

        @test pmSet(T[1,1]) isa PolymakeWrap.Polymake.pm_Set
        @test string(pmSet(T[1])) == string(pmSet(T[1,1]))

        a = pmSet(T[1,2,3,1])
        # pm::Set<long, pm::operations::cmp>
        # {1 2 3}

        b = pmSet(T[5,6,6])
        # pm::Set<long, pm::operations::cmp>
        # {5 6}

        PolymakeWrap.swap(a, b)
        @test string(a) == "pm::Set<$(symb), pm::operations::cmp>\n{5 6}"

        PolymakeWrap.clear(a)
        @test string(a) == "pm::Set<$(symb), pm::operations::cmp>\n{}"
        @test string(b) == "pm::Set<$(symb), pm::operations::cmp>\n{1 2 3}"

        @test PolymakeWrap.empty(a)
        @test !PolymakeWrap.empty(b)

        @test PolymakeWrap.size(a) == 0
        @test PolymakeWrap.size(b) == 3

        @testset "element containment" begin
            a = pmSet(T[1,2,3,1,2,3])
            b = pmSet(T[5,6,6])
            @test PolymakeWrap.size(a) == 3
            @test PolymakeWrap.size(b) == 2

            for (S, _) in IntTypes
                @test PolymakeWrap.contains(a, S(1))
                @test PolymakeWrap.contains(a, S(2))
                @test PolymakeWrap.contains(a, S(3))

                @test !PolymakeWrap.contains(a, S(5))
                @test !PolymakeWrap.contains(a, S(6))

                @test !PolymakeWrap.contains(b, S(1))
                @test !PolymakeWrap.contains(b, S(2))
                @test !PolymakeWrap.contains(b, S(3))

                @test PolymakeWrap.contains(b, S(5))
                @test PolymakeWrap.contains(b, S(6))
            end
        a = pmSet(T[1,2,3,1,2,3])
        b = pmSet(T[5,6,6])

        @test PolymakeWrap.collect(a, 1)
        @test PolymakeWrap.collect(a, 2)
        @test PolymakeWrap.collect(a, 3)
        @test !PolymakeWrap.collect(a, 4)
        @test PolymakeWrap.size(a) == 4

        @test PolymakeWrap.collect(b, 5)
        @test PolymakeWrap.collect(b, 6)
        @test !PolymakeWrap.collect(b, 7)
        @test PolymakeWrap.collect(b, 7)
        @test PolymakeWrap.size(b) == 3
        end

    end
end
