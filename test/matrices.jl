@testset "pm_Matrix" begin
    for T in [pm_Integer, pm_Rational, Float64]
        @test pm_Matrix{T} <: AbstractMatrix
        @test pm_Matrix{T}(3,4) isa AbstractMatrix
        @test pm_Matrix{T}(3,4) isa pm_Matrix
        @test pm_Matrix{T}(3,4) isa pm_Matrix{T}
        M = pm_Matrix{T}(3,4)
        M[1,1] = 10
        @test M[1,1] isa T
        @test M[1,1] == 10
    end

    x = pm_Matrix{pm_Integer}(3,4)

    @test x[1] isa pm_Integer
    @test setindex!(x, pm_Integer(4), 1, 1) == pm_Matrix([4 0 0 0; 0 0 0 0; 0 0 0 0])
    @test x[1,1] == 4
    @test x[1] == 4

    x[2, 1] = 4
    @test x[2,1] == pm_Integer(4)
    @test x[2] == pm_Integer(4)

    @test_throws BoundsError x[0]
    @test_throws BoundsError x[13]
    @test_throws BoundsError x[0,3]
    @test_throws BoundsError x[4,1]
    @test_throws BoundsError x[4,5]

    @test length(x) == 12
    @test size(x) == (3,4)

    x = pm_Matrix{pm_Rational}(5, 2)
    @test x[1] isa pm_Rational
    setindex!(x, pm_Rational(4,1), 3, 2)
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

    @test sprint(show, x) == "pm::Matrix<pm::Rational>\n0 0\n0 0\n1/2 4\n0 0\n0 0\n"

    m = [1 2 3; 4 5 6]
    @test pm_Matrix(Int32.(m)) isa pm_Matrix{pm_Integer}
    @test pm_Matrix(m) isa pm_Matrix{pm_Integer}
    @test pm_Matrix(big.(m)) isa pm_Matrix{pm_Integer}

    den = 4
    @test pm_Matrix(Int32.(m)//Int32(den)) isa pm_Matrix{pm_Rational}
    @test pm_Matrix(m//den) isa pm_Matrix{pm_Rational}
    @test pm_Matrix(big.(m)//big(den)) isa pm_Matrix{pm_Rational}

    @test pm_Matrix(m) == pm_Matrix((den*m)//den)

    ### Conversion

    m = pm_Matrix([4 0 0 0; 0 0 0 0; 0 0 0 0])
    @test convert(Array{BigInt,2},m) == BigInt[4 0 0 0; 0 0 0 0; 0 0 0 0]

    m = pm_Matrix([4 0 0 0; 0 0 0 0; 0 0 0 0//1])
    @test convert(Array{Rational{BigInt},2},m) == Rational{BigInt}[4 0 0 0; 0 0 0 0; 0 0 0 0//1]

end
