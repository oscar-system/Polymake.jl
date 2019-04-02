@testset "Interface functions" begin
    for (args, val) in [((4,2), 5), ((pm_Integer(4), 2), 5)]
        @test call_function(:polytope, :pseudopower, args...) == val
        @test (@pm Polytope.pseudopower(args...)) == val
        @test Polytope.pseudopower(args...) == val
    end

    @test call_function(:polytope, :cube, 2) isa pm_perl_Object
    @test Polytope.cube( 2 ) isa pm_perl_Object
    @test (@pm Polytope.cube{Rational}( 3 )) isa pm_perl_Object
    c = @pm Polytope.cube{Rational}( 3 )
    cc = Polytope.cube( 3 )
    @test call_function(:polytope, :equal_polyhedra,c,cc)
    @test @pm Polytope.equal_polyhedra(c, cc)
    @test Polytope.equal_polyhedra(c, cc)

    @test Tropical.cyclic(3,5,template_parameters=["Max"]) isa pm_perl_Object

    @test (@pm Tropical.cyclic{Max}(3,5)) isa pm_perl_Object

end

@testset "Indexing helpers" begin
    X = [2, [2,3], Set([3,2,2])]
    Y = [3, [3,4], Set([4,3,3])]
    Z = [1, [1,2], Set([2,1,1])]
    @test Polymake.to_one_based_indexing(X) == Y
    @test Polymake.to_zero_based_indexing(X) == Z

    to_ZERO = Polymake.to_zero_based_indexing
    to_ONE = Polymake.to_one_based_indexing

    I_types = [Int, pm_Integer]; V_types = [Vector, pm_Vector, pm_Array]; S_types = [Set, pm_Set];

    for I in I_types, V in V_types, S in S_types
        i, v, s = X
        @test to_ONE([I(i), V(v), S(s)]) == Y
        @test to_ZERO([I(i), V(v), S(s)]) == Z
        @test to_ZERO(to_ONE([I(i), V(v), S(s)])) == X
        @test to_ONE(to_ZERO([I(i), V(v), S(s)])) == X
    end

    A = pm_Array{pm_Set{Int32}}([pm_Set(Int32[1,1,2]), pm_Set(Int32[2,3,1])])
    B = pm_Array{pm_Set{Int32}}([pm_Set(Int32[0,0,1]), pm_Set(Int32[1,2,0])])

    @test to_ZERO(A) == B
    @test to_ONE(B) == A
    @test_throws ArgumentError to_ZERO(B)
end