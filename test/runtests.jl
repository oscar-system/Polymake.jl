using PolymakeWrap
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

# write your own tests here
@testset "PolymakeWrap" begin
    @testset "pm_Integer" begin
        pmI = PolymakeWrap.pm_Integer
        
        @test pmI(Int32(3)) isa Number
        @test pmI(Int32(3)) isa Integer
        @test pmI(Int32(3)) isa pmI
        x = pmI(Int32(3))
    
        @test pmI(3) isa Number
        @test pmI(3) isa Integer
        @test pmI(3) isa pmI
        y = pmI(3)
        
        @test pmI(big(3)) isa Number
        @test pmI(big(3)) isa Integer
        @test pmI(big(3)) isa pmI
        z = pmI(big(3))
        
        @test x == y == z
        @test x != pmI(4)
        str(a::pmI) = PolymakeWrap.Polymake.show_small_obj(a)
        @test str(x) == str(y) == str(y) == "pm::Integer\n3" 
    end
    
    @testset "pm_Rational" begin
        pmR = PolymakeWrap.pm_Rational
        
        function test_rational(num, den)
            @test pmR(num, den) isa Number
            @test pmR(num, den) isa Real
            @test pmR(num, den) isa pmR
            x = pmR(num, den)
            @test numerator(x) isa PolymakeWrap.pm_Integer
            @test numerator(x) == PolymakeWrap.pm_Integer(num)
            @test denominator(x) isa PolymakeWrap.pm_Integer
            @test denominator(x) == PolymakeWrap.pm_Integer(den)
            return x
        end
    
        x = test_rational(Int32(4), Int32(3))
        y = test_rational(4,3)
        z = test_rational(big(4), big(3))
        
        @test x == y == z
        @test x != pmR(4,4)
        
        str(a::pmR) = PolymakeWrap.Polymake.show_small_obj(a)
        @test str(x) == str(y) == str(y) == "pm::Rational\n4/3"
        
    end
    
    @testset "pm_Vector" begin
        pmV = PolymakeWrap.pm_Vector
        pmI = PolymakeWrap.pm_Integer
        
        @test pmV{pmI} <: AbstractVector
        @test pmV{pmI}(3) isa AbstractVector
        @test pmV{pmI}(3) isa pmV
        @test pmV{pmI}(3) isa pmV{pmI}
        x = pmV{pmI}(3)
        @test x[1] isa pmI
        @test x[1] == pmI(0)
        @test setindex!(x, pmI(4), 1) == pmI(4)
        @test setindex!(x, 4, 1) == pmI(4)
        @test x[1] == pmI(4)
        x[3] = 2
        @test x[3] == pmI(2)
        
        @test_throws BoundsError x[0]
        @test_throws BoundsError x[5]
        
        @test length(x) == 3
        @test size(x) == (3,)
        @test PolymakeWrap.Polymake.show_small_obj(x) == "pm::Vector<pm::Integer>\n4 0 2"
    end

    include("sets.jl")
end
