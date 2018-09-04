using PolymakeWrap
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

# write your own tests here
@testset "pm_Set" begin
    pm_Set = PolymakeWrap.Polymake.pm_Set
    IntTypes = [Int32, Int64]


    @testset "constructors" begin
        @test pm_Set{Int32}() isa PolymakeWrap.Polymake.pm_Set
        @test pm_Set{Int64}() isa PolymakeWrap.Polymake.pm_SetAllocated
        for T in IntTypes
            @test pm_Set(T[1]) isa PolymakeWrap.Polymake.pm_Set
            @test pm_Set(T[1,1]) isa PolymakeWrap.Polymake.pm_Set
            @test pm_Set(T[2,1]) isa PolymakeWrap.Polymake.pm_Set
        end
    end

    @testset "equality" begin
        @test pm_Set{Int32}() == pm_Set{Int32}()
        @test pm_Set{Int64}() == pm_Set{Int64}()

        @test pm_Set{Int32}() == pm_Set{Int64}()

        for T in IntTypes, S in IntTypes
            @test pm_Set(T[1]) == pm_Set(S[1,1])
            @test pm_Set(T[2,2,1,1]) == pm_Set(S[1,2,1])
        end
    end

    @testset "basic functionality" begin
        for T in IntTypes
            a = pm_Set(T[1,2,3,1])
            b = pm_Set(T[5,6,6])

            PolymakeWrap.swap(a, b)
            @test a == pm_Set(T[5,6])

            PolymakeWrap.clear(a)
            @test a == pm_Set{T}()
            @test b == pm_Set(T[1, 2, 3])

            @test PolymakeWrap.empty(a)
            @test !PolymakeWrap.empty(b)

            @test PolymakeWrap.size(a) == 0
            @test PolymakeWrap.size(b) == 3

            a = pm_Set(T[1,2,3,1,2,3])
            b = pm_Set(T[5,6,6])
            @test PolymakeWrap.size(a) == 3
            @test PolymakeWrap.size(b) == 2
        end
    end

    @testset "element containment" begin
        for T in IntTypes, S in IntTypes
            a = pm_Set(T[3,2,1,3,2,1])
            b = pm_Set(T[5,6,6])

            @test PolymakeWrap.contains(a, S(2))
            @test !PolymakeWrap.contains(a, S(5))

            @test !PolymakeWrap.contains(b, S(3))
            @test PolymakeWrap.contains(b, S(5))

            a = pm_Set(T[1,2,3,1,2,3])
            b = pm_Set(T[5,6,6])

            @test PolymakeWrap.collect(a, S(3))
            @test !PolymakeWrap.collect(a, S(4))
            @test PolymakeWrap.collect(a, S(4))
            @test PolymakeWrap.size(a) == 4
            @test a == pm_Set([1,2,3,4])

            @test PolymakeWrap.collect(b, S(6))
            @test !PolymakeWrap.collect(b, S(7))
            @test PolymakeWrap.collect(b, S(7))
            @test PolymakeWrap.size(b) == 3
            @test b == pm_Set([5,6,7])
        end
    end

    end
end
