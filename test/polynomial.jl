using Polymake.SparseArrays

@testset verbose=true "Polymake.Polynomial" begin
    for C in [Int64, Polymake.Integer, Polymake.Rational, Float64, Polymake.QuadraticExtension{Polymake.Rational}]
        @test Polymake.Polynomial{C,Int64} <: Any
        @test Polymake.Polynomial{C,Int64}([1, 2],[3 4 5; 6 7 8]) isa Any
        @test Polymake.Polynomial{C,Int64}([1, 2],[3 4 5; 6 7 8]) isa Polymake.Polynomial
        @test Polymake.Polynomial{C,Int64}([1, 2],[3 4 5; 6 7 8]) isa Polymake.Polynomial{Polymake.to_cxx_type(C),Polymake.to_cxx_type(Int64)}
    end

    jl_v = [1, 2]
    jl_m = [3 4 5; 6 7 0]
    @testset verbose=true "Constructors/Converts" begin
        for C in [Int64, Polymake.Integer, Polymake.Rational, Float64]
            @test Polymake.Polynomial(C.(jl_v), jl_m) isa Polymake.Polynomial{Polymake.to_cxx_type(C),Polymake.to_cxx_type(Int64)}
            @test Polymake.Polynomial{Float64}(C.(jl_v), jl_m) isa Polymake.Polynomial{Polymake.to_cxx_type(Float64),Polymake.to_cxx_type(Int64)}
            @test Polymake.Polynomial{Polymake.Rational,Int64}(C.(jl_v), jl_m) isa Polymake.Polynomial{Polymake.Rational,Polymake.to_cxx_type(Int64)}
        end
    end

    @testset verbose=true "Low-level operations" begin
        for (C,s) in [(Int64, "long"), (Polymake.Integer, "pm::Integer"), (Polymake.Rational, "pm::Rational"), (Float64, "double"), (Polymake.QuadraticExtension{Polymake.Rational}, "pm::QuadraticExtension<pm::Rational>")]
            p = Polymake.Polynomial(C.(jl_v),jl_m)
            oldnames = Polymake.get_var_names(p)
            @test Polymake.nvars(p) == size(jl_m)[2]
            @test Polymake.nvars(p) isa Int
            # the following line is only necessary if the tests are run with an active session of Polymake
            # because variable names are global for the specific typing; ["x"] is its default value
            Polymake.set_var_names(p,["x"])
            @test string(p) == string("pm::Polynomial<", s, ", long>\n2*x_0^6*x_1^7 + x_0^3*x_1^4*x_2^5")
            Polymake.set_var_names(p,["x", "y", "z"])
            @test Polymake.get_var_names(p) == ["x", "y", "z"]
            @test string(p) == string("pm::Polynomial<", s, ", long>\n2*x^6*y^7 + x^3*y^4*z^5")
            @test Polymake.nvars(p) == size(jl_m, 2)
            @test Polymake.coefficients_as_vector(p) isa Polymake.Vector
            @test Polymake.coefficients_as_vector(p) isa Polymake.Vector{Polymake.to_cxx_type(C)}
            v = Polymake.coefficients_as_vector(p)
            perm1 = sortperm(jl_v)
            perm2 = sortperm(v)
            @test  v[perm2] == jl_v[perm1]
            @test Polymake.monomials_as_matrix(p) isa Polymake.SparseMatrix
            @test Polymake.monomials_as_matrix(p) isa Polymake.SparseMatrix{Polymake.to_cxx_type(Int64)}
            m = Polymake.monomials_as_matrix(p)
            @test m[perm2, :] == jl_m[perm1, :]
            Polymake.set_var_names(p, oldnames)
        end
    end

    @testset verbose=true "Equality" begin
        for C1 in [Int64, Polymake.Integer, Polymake.Rational, Float64, Polymake.QuadraticExtension{Polymake.Rational}], C2 in [Int64, Polymake.Integer, Polymake.Rational, Float64, Polymake.QuadraticExtension{Polymake.Rational}]
            @test Polymake.Polynomial{C1}(jl_v,jl_m) == Polymake.Polynomial{C2}(jl_v,jl_m)
        end
    end

    @testset verbose=true "Arithmetic" begin
        jl_v2 = [5, 6]
        jl_m2 = [3 4 5; 6 7 8]
        for C1 in [Int64, Polymake.Integer, Polymake.Rational, Float64, Polymake.QuadraticExtension{Polymake.Rational}]
            p = Polymake.Polynomial{C1}(jl_v,jl_m)
            for C2 in [Int64, Polymake.Integer, Polymake.Rational, Float64, Polymake.QuadraticExtension{Polymake.Rational}]
                q = Polymake.Polynomial{C2}(jl_v2,jl_m2)
                @test p + q isa Polymake.Polynomial{Polymake.to_cxx_type(promote_type(C1,C2))}
                @test p + q == Polymake.Polynomial([6, 2, 6],[3 4 5; 6 7 0; 6 7 8])
                @test p * q isa Polymake.Polynomial{Polymake.to_cxx_type(promote_type(C1,C2))}
                @test p * q == Polymake.Polynomial([12, 6, 10, 5],[12 14 8; 9 11 13; 9 11 5; 6 8 10])
                @test p - q isa Polymake.Polynomial{Polymake.to_cxx_type(promote_type(C1,C2))}
                @test p - q == Polymake.Polynomial([-4, 2, -6],[3 4 5; 6 7 0; 6 7 8])
            end
            @test p^3 isa Polymake.Polynomial{Polymake.to_cxx_type(C1)}
            @test p^3 == Polymake.Polynomial([8, 12, 6, 1],[18 21 0; 15 18 5; 12 15 10; 9 12 15])
            # @test p/2 isa Polymake.Polynomial{Polymake.to_cxx_type(C1)}
            # @test p/2 == Polymake.Polynomial{C1}(C1 <: Integer ? floor.(jl_v/2) : jl_v/2,jl_m)
            @test -p isa Polymake.Polynomial{Polymake.to_cxx_type(C1)}
            @test -p == Polymake.Polynomial(-jl_v,jl_m)
            @test p + (-p) == 0
            @test p + 8 isa Polymake.Polynomial{Polymake.to_cxx_type(C1)}
            @test 8 + p isa Polymake.Polynomial{Polymake.to_cxx_type(C1)}
            @test p + 8 == Polymake.Polynomial([jl_v; 8], [jl_m; 0 0 0])
            @test 8 + p == Polymake.Polynomial([jl_v; 8], [jl_m; 0 0 0])
            @test p - 7 isa Polymake.Polynomial{Polymake.to_cxx_type(C1)}
            @test 7 - p isa Polymake.Polynomial{Polymake.to_cxx_type(C1)}
            @test p - 7 == Polymake.Polynomial([jl_v; -7], [jl_m; 0 0 0])
            @test 7 - p == Polymake.Polynomial([-jl_v; 7], [jl_m; 0 0 0])
            @test p * 6 isa Polymake.Polynomial{Polymake.to_cxx_type(C1)}
            @test 6 * p isa Polymake.Polynomial{Polymake.to_cxx_type(C1)}
            @test p * 6 == Polymake.Polynomial(6jl_v, jl_m)
            @test 6 * p == Polymake.Polynomial(6jl_v, jl_m)
            @test 8 + p - p == 8
            @test 8 == 8 + p - p
            @test (5 * p) / 5 isa Polymake.Polynomial{Polymake.to_cxx_type(C1)}
            @test (5 * p) / 5 == p
        end
    end
end

@testset verbose=true "UniPolynomial" begin

   @testset verbose=true "properties" begin
      c = Polymake.polytope.cube(3,1,0)
      ehr = c.EHRHART_POLYNOMIAL
      @test Polymake.monomials_as_vector(ehr) == [0, 1, 2, 3]
      @test Polymake.coefficients_as_vector(ehr) == [1, 3, 3, 1]
    end

    for C in [Int64, Polymake.Integer, Polymake.Rational, Polymake.QuadraticExtension{Polymake.Rational}, Float64]
        @test Polymake.UniPolynomial{C,Int64} <: Any
        @test Polymake.UniPolynomial{C,Int64}([1, 2],[3, 8]) isa Polymake.UniPolynomial
        @test Polymake.UniPolynomial{C,Int64}([1, 2],[3, 8]) isa Polymake.UniPolynomial{Polymake.to_cxx_type(C),Polymake.to_cxx_type(Int64)}
    end

    jl_v = [1, 2]
    jl_m = [3, 6]
    @testset verbose=true "Constructors/Converts" begin
       for C in [Int64, Polymake.Integer, Polymake.Rational, Float64]
            @test Polymake.UniPolynomial(C.(jl_v), jl_m) isa Polymake.UniPolynomial{Polymake.to_cxx_type(C),Polymake.to_cxx_type(Int64)}
            @test Polymake.UniPolynomial{Float64}(C.(jl_v), jl_m) isa Polymake.UniPolynomial{Polymake.to_cxx_type(Float64),Polymake.to_cxx_type(Int64)}
            @test Polymake.UniPolynomial{Polymake.Rational,Int64}(C.(jl_v), jl_m) isa Polymake.UniPolynomial{Polymake.Rational,Polymake.to_cxx_type(Int64)}
        end
    end

    @testset verbose=true "Low-level operations" begin
       for (C,s) in [(Int64, "long"), (Polymake.Integer, "pm::Integer"), (Polymake.Rational, "pm::Rational"), (Polymake.QuadraticExtension{Polymake.Rational}, "pm::QuadraticExtension<pm::Rational>"), (Float64, "double")]
            p = Polymake.UniPolynomial(C.(jl_v),jl_m)
            @test Polymake.nvars(p) == 1
            @test Polymake.nvars(p) isa Int
            oldnames = Polymake.get_var_names(p)
            # the following line is only necessary if the tests are run with an active session of Polymake
            # because variable names are global for the specific typing; ["x"] is its default value
            Polymake.set_var_names(p,["x"])
            @test string(p) == string("pm::UniPolynomial<", s, ", long>\n2*x^6 + x^3")
            @test Polymake.coefficients_as_vector(p) isa Polymake.Vector
            @test Polymake.coefficients_as_vector(p) isa Polymake.Vector{Polymake.to_cxx_type(C)}
            @test Polymake.monomials_as_vector(p) isa Polymake.Vector
            @test Polymake.monomials_as_vector(p) isa Polymake.Vector{Polymake.to_cxx_type(Int64)}
            c = Polymake.coefficients_as_vector(p)
            m = Polymake.monomials_as_vector(p)
            @test p == Polymake.UniPolynomial(c,m)
            Polymake.set_var_names(p, oldnames)
        end
    end

    @testset verbose=true "Equality" begin
       for C1 in [Int64, Polymake.Integer, Polymake.Rational, Polymake.QuadraticExtension{Polymake.Rational}], C2 in [Int64, Polymake.Integer, Polymake.Rational, Polymake.QuadraticExtension{Polymake.Rational}, Float64]
            @test Polymake.UniPolynomial{C1}(jl_v,jl_m) == Polymake.UniPolynomial{C2}(jl_v,jl_m)
        end
    end

    @testset verbose=true "Arithmetic" begin
        jl_v2 = [5, 6]
        jl_m2 = [3, 6]
        for C1 in [Int64, Polymake.Integer, Polymake.Rational, Polymake.QuadraticExtension{Polymake.Rational}, Float64]
            p = Polymake.UniPolynomial{C1}(jl_v,jl_m)
            for C2 in [Int64, Polymake.Integer, Polymake.Rational, Polymake.QuadraticExtension{Polymake.Rational}, Float64]
                q = Polymake.UniPolynomial{C2}(jl_v2,jl_m2)
                @test p + q isa Polymake.UniPolynomial{Polymake.to_cxx_type(promote_type(C1,C2))}
                @test p + q == Polymake.UniPolynomial([6, 8],[3, 6])
                @test p * q isa Polymake.UniPolynomial{Polymake.to_cxx_type(promote_type(C1,C2))}
                @test p * q == Polymake.UniPolynomial([12, 6, 10, 5],[12, 9, 9, 6])
                @test p - q isa Polymake.UniPolynomial{Polymake.to_cxx_type(promote_type(C1,C2))}
                @test p - q == Polymake.UniPolynomial([-4, -4],[3, 6])
            end
            @test p^3 isa Polymake.UniPolynomial{Polymake.to_cxx_type(C1)}
            @test p^3 == Polymake.UniPolynomial([1, 6, 12, 8],[9, 12, 15, 18])
            # @test p/2 isa Polymake.UniPolynomial{Polymake.to_cxx_type(C1)}
            # @test p/2 == Polymake.UniPolynomial{C1}(C1 <: Integer ? floor.(jl_v/2) : jl_v/2,jl_m)
            @test -p isa Polymake.UniPolynomial{Polymake.to_cxx_type(C1)}
            @test -p == Polymake.UniPolynomial(-jl_v,jl_m)
            @test p + (-p) == 0
            @test p + 8 isa Polymake.UniPolynomial{Polymake.to_cxx_type(C1)}
            @test 8 + p isa Polymake.UniPolynomial{Polymake.to_cxx_type(C1)}
            @test p + 8 == Polymake.UniPolynomial([jl_v; 8], [jl_m; 0])
            @test 8 + p == Polymake.UniPolynomial([jl_v; 8], [jl_m; 0])
            @test p - 7 isa Polymake.UniPolynomial{Polymake.to_cxx_type(C1)}
            @test 7 - p isa Polymake.UniPolynomial{Polymake.to_cxx_type(C1)}
            @test p - 7 == Polymake.UniPolynomial([jl_v; -7], [jl_m; 0])
            @test 7 - p == Polymake.UniPolynomial([-jl_v; 7], [jl_m; 0])
            @test p * 6 isa Polymake.UniPolynomial{Polymake.to_cxx_type(C1)}
            @test 6 * p isa Polymake.UniPolynomial{Polymake.to_cxx_type(C1)}
            @test p * 6 == Polymake.UniPolynomial(6jl_v, jl_m)
            @test 6 * p == Polymake.UniPolynomial(6jl_v, jl_m)
            @test 8 + p - p == 8
            @test 8 == 8 + p - p
            @test (5 * p) / 5 isa Polymake.UniPolynomial{Polymake.to_cxx_type(C1)}
            @test (5 * p) / 5 == p
        end
    end
end
@testset verbose=true "PuiseuxFraction" begin

   @testset verbose=true "properties" begin
      c = Polymake.polytope.long_and_winding(2)
      @test c.VERTICES isa Polymake.Matrix{<:Polymake.PuiseuxFraction}
      @test c.VOLUME isa Polymake.PuiseuxFraction
    end


    coeff_num = Polymake.Rational[3, 7, 7//2]
    exp_num = Polymake.Rational[2//1, 3, 5]
    coeff_den = Polymake.Rational[1//1, -1]
    exp_den = Polymake.Rational[1//1, 2]
    up_num = Polymake.UniPolynomial{Polymake.Rational,Polymake.Rational}(coeff_num, exp_num)
    up_den = Polymake.UniPolynomial{Polymake.Rational,Polymake.Rational}(coeff_den, exp_den)

    @testset verbose=true "Constructors/Converts" begin
        @test Polymake.PuiseuxFraction{Polymake.Min}(up_num, up_den) isa Polymake.PuiseuxFraction{Polymake.Min,Polymake.Rational,Polymake.Rational}
        pfmin = Polymake.PuiseuxFraction{Polymake.Min}(up_num, up_den)
        pfmax = Polymake.PuiseuxFraction{Polymake.Max}(up_num, up_den)
        @test Polymake.PuiseuxFraction{Polymake.Max}(3//7) isa Polymake.PuiseuxFraction{Polymake.Max,Polymake.Rational,Polymake.Rational}
    end

    pfmin = Polymake.PuiseuxFraction{Polymake.Min}(up_num, up_den)
    pfmax = Polymake.PuiseuxFraction{Polymake.Max}(up_num, up_den)
    pfconst = Polymake.PuiseuxFraction{Polymake.Min}(3//7)
    pfconstmax = Polymake.PuiseuxFraction{Polymake.Max}(3//7)
    @testset verbose=true "Low-level operations" begin
        @test numerator(pfmin) isa Polymake.UniPolynomial{Polymake.Rational,Polymake.Rational}
        @test denominator(pfmin) isa Polymake.UniPolynomial{Polymake.Rational,Polymake.Rational}
        oldnames = Polymake.get_var_names(pfmin)
        # the following line is only necessary if the tests are run with an active session of Polymake
        # because variable names are global for the specific typing; ["x"] is its default value
        Polymake.set_var_names(pfmin,["t"])
        @test string(pfmin) == string("pm::PuiseuxFraction<pm::Min, pm::Rational, pm::Rational>\n(-3*t -7*t^2 -7/2*t^4)/(- 1 + t)")
        @test Polymake.cmp(pfmin,pfconst) == -1
        @test Polymake.cmp(pfmax,pfconstmax) == -1
        @test pfmin < pfconst
        @test pfmin <= pfconst
        @test pfconst > pfmin
        @test pfconst >= pfmin
        @test pfmin < 4
        @test pfmin <= 4
        @test 4 > pfmin
        @test 4 >= pfmin
        @test pfmin == pfmin+0
        @test Polymake.val(pfconst) == 0
        @test Polymake.val(pfmin) == 1
        @test Polymake.val(pfmax) == 3
        Polymake.set_var_names(pfmin, oldnames)
    end

    PMin = Polymake.PuiseuxFraction{Polymake.Min,Polymake.Rational,Polymake.Rational}
    @testset verbose=true "Arithmetic" begin
        @test pfmin^3 isa PMin
        @test pfmin^3 == pfmin*pfmin*pfmin
        @test -pfmin isa PMin
        @test -pfmin == PMin(-up_num,up_den)
        @test pfmin + (-pfmin) == 0
        @test pfmin + 8 isa PMin
        @test 8 + pfmin isa PMin
        @test pfconst + 8 == PMin(3//7+8)
        @test 8 + pfconst == PMin(3//7+8)
        @test pfmin - 7 isa PMin
        @test 7 - pfmin isa PMin
        @test pfconst - 7 == PMin(3//7-7)
        @test 7 - pfconst == PMin(7//1-3//7)
        @test pfmin * 6 isa PMin
        @test 6 * pfmin isa PMin
        @test 8 + pfmin - pfmin == 8
        @test 8 == 8 + pfmin - pfmin
        @test (5 * pfmin) / 5 isa PMin
        @test (5 * pfmin) / 5 == pfmin
        @test pfconst // pfmin isa PMin
    end
end
