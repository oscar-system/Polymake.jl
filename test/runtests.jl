using PolymakeWrap
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

# write your own tests here
@testset "PolymakeWrap" begin
    include("integers.jl")
    include("rationals.jl")

    @testset "pm_Vector" begin
        pmV = PolymakeWrap.pm_Vector
        pmI = PolymakeWrap.pm_Integer
        pmR = PolymakeWrap.pm_Rational

        for T in [pmI, pmR]
            @test pmV{T} <: AbstractVector
            @test pmV{T}(3) isa AbstractVector
            @test pmV{T}(3) isa pmV
            @test pmV{T}(3) isa pmV{T}
        end

        v = [1,2,3]
        @test pmV(Int32.(v)) isa pmV{pmI}
        @test pmV(v) isa pmV{pmI}
        @test pmV(big.(v)) isa pmV{pmI}
        den = 4
        @test pmV(Int32.(v)//Int32(den)) isa pmV{pmR}
        @test pmV(v//den) isa pmV{pmR}
        @test pmV(big.(v)//big(den)) isa pmV{pmR}

        x = pmV{pmI}([0,0,0])

        @test x[1] isa pmI
        @test setindex!(x, pmI(4), 1) == pmV([4,0,0])
        @test setindex!(x, 4, 1) == pmV([4,0,0])
        @test x[1] == 4
        x[3] = 2
        @test x[3] == 2
        @test x == pmV([4,0,2])

        @test_throws BoundsError x[0]
        @test_throws BoundsError x[5]

        @test length(x) == 3
        @test size(x) == (3,)

        x = pmV{pmR}(4)
        @test x[1] isa pmR
        @test setindex!(x, pmR(4,1), 1) == pmV([4//1, 0//1, 0//1, 0//1])
        @test setindex!(x, 4, 1) == pmV([4//1, 0//1, 0//1, 0//1])
        @test x[1] == pmR(4//1)
        x[3] = 2//4
        @test x[3] == pmR(1//2)
        @test x == pmV([4//1, 0//1, 1//2, 0//1])

        @test_throws BoundsError x[0]
        @test_throws BoundsError x[6]

        @test length(x) == 4
        @test size(x) == (4,)

        @test PolymakeWrap.Polymake.show_small_obj(x) == "pm::Vector<pm::Rational>\n4 0 1/2 0"
        v = [1,2,3]
        pm_v = pmV{pmI}(3)
        pm_v .= v
        @test pm_v == v

        @test pmV(v) == pmV((4*v)//4)
    end

    @testset "pm_Matrix" begin
        pmM = PolymakeWrap.pm_Matrix
        pmI = PolymakeWrap.pm_Integer
        pmR = PolymakeWrap.pm_Rational

        for T in [pmI, pmR]
            @test pmM{T} <: AbstractMatrix
            @test pmM{T}(3,4) isa AbstractMatrix
            @test pmM{T}(3,4) isa pmM
            @test pmM{T}(3,4) isa pmM{T}
        end

        x = pmM{pmI}(3,4)

        @test x[1] isa pmI
        @test setindex!(x, pmI(4), 1, 1) == pmM([4 0 0 0; 0 0 0 0; 0 0 0 0])
        @test x[1,1] == 4
        @test x[1] == 4

        x[2, 1] = 4
        @test x[2,1] == pmI(4)
        @test x[2] == pmI(4)

        @test_throws BoundsError x[0]
        @test_throws BoundsError x[13]
        @test_throws BoundsError x[0,3]
        @test_throws BoundsError x[4,1]
        @test_throws BoundsError x[4,5]

        @test length(x) == 12
        @test size(x) == (3,4)

        x = pmM{pmR}(5, 2)
        @test x[1] isa pmR
        setindex!(x, pmR(4,1), 3, 2)
        @test x[3,2] == 4//1
        x[3] = 2//4
        @test x[3] == 1//2
        @test x[3,1] == 1//2

        @test_throws BoundsError x[0]
        @test_throws BoundsError x[11]
        @test_throws BoundsError x[2,3]
        @test_throws BoundsError x[6,2]

        @test length(x) == 10
        @test size(x) == (5,2)

        @test PolymakeWrap.Polymake.show_small_obj(x) == "pm::Matrix<pm::Rational>\n0 0\n0 0\n1/2 4\n0 0\n0 0\n"

        m = [1 2 3; 4 5 6]
        @test pmM(Int32.(m)) isa pmM{pmI}
        @test pmM(m) isa pmM{pmI}
        @test pmM(big.(m)) isa pmM{pmI}

        den = 4
        @test pmM(Int32.(m)//Int32(den)) isa pmM{pmR}
        @test pmM(m//den) isa pmM{pmR}
        @test pmM(big.(m)//big(den)) isa pmM{pmR}

        @test pmM(m) == pmM((den*m)//den)
    end

    include("sets.jl")
end
