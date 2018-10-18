@testset "pm_Vector" begin
    for T in [pm_Integer, pm_Rational]
        @test pm_Vector{T} <: AbstractVector
        @test pm_Vector{T}(3) isa AbstractVector
        @test pm_Vector{T}(3) isa pm_Vector
        @test pm_Vector{T}(3) isa pm_Vector{T}
    end

    v = [1,2,3]
    @test pm_Vector(Int32.(v)) isa pm_Vector{pm_Integer}
    @test pm_Vector(v) isa pm_Vector{pm_Integer}
    @test pm_Vector(big.(v)) isa pm_Vector{pm_Integer}
    den = 4
    @test pm_Vector(Int32.(v)//Int32(den)) isa pm_Vector{pm_Rational}
    @test pm_Vector(v//den) isa pm_Vector{pm_Rational}
    @test pm_Vector(big.(v)//big(den)) isa pm_Vector{pm_Rational}

    x = pm_Vector{pm_Integer}([0,0,0])

    @test x[1] isa pm_Integer
    @test setindex!(x, pm_Integer(4), 1) == pm_Vector([4,0,0])
    @test setindex!(x, 4, 1) == pm_Vector([4,0,0])
    @test x[1] == 4
    x[3] = 2
    @test x[3] == 2
    @test x == pm_Vector([4,0,2])

    @test_throws BoundsError x[0]
    @test_throws BoundsError x[5]

    @test length(x) == 3
    @test size(x) == (3,)

    x = pm_Vector{pm_Rational}(4)
    @test x[1] isa pm_Rational
    @test setindex!(x, pm_Rational(4,1), 1) == pm_Vector([4//1, 0//1, 0//1, 0//1])
    @test setindex!(x, 4, 1) == pm_Vector([4//1, 0//1, 0//1, 0//1])
    @test x[1] == pm_Rational(4//1)
    x[3] = 2//4
    @test x[3] == pm_Rational(1//2)
    @test x == pm_Vector([4//1, 0//1, 1//2, 0//1])

    @test_throws BoundsError x[0]
    @test_throws BoundsError x[6]

    @test length(x) == 4
    @test size(x) == (4,)

    @test sprint(show, x) == "pm::Vector<pm::Rational>\n4 0 1/2 0"
    v = [1,2,3]
    pm_v = pm_Vector{pm_Integer}(3)
    pm_v .= v
    @test pm_v == v

    @test pm_Vector(v) == pm_Vector((4*v)//4)
end
