@testset verbose=true "Polymake.Group" begin
    @testset verbose=true "Polymake.SwitchTable" begin
        ggens = [[1,2,0,4,5,3], [2,1,0,5,4,3]]
        gp = Polymake.group.PermutationAction(GENERATORS=ggens)
        sw = Polymake.SwitchTable(gp.ALL_GROUP_ELEMENTS)
        
        v1 = convert(Polymake.PolymakeType, [64,64,64,0,0,0])
        min1 = Polymake.lex_minimize_vector(sw, v1)
        max1 = Polymake.lex_maximize_vector(sw, v1)
        @test min1 == max1
        @test first(min1) == v1
        @test first(max1) == v1
        @test first(min1) == Polymake.group.action_inv(last(min1), v1)
        @test first(max1) == Polymake.group.action_inv(last(max1), v1)
        
        v2 = convert(Polymake.PolymakeType, [32,36,44,48,32,0])
        min2 = Polymake.lex_minimize_vector(sw, v2)
        max2 = Polymake.lex_maximize_vector(sw, v2)
        @test first(min2) == v2
        @test first(min2) == Polymake.group.action_inv(last(min2), v2)
        @test first(max2) == Polymake.group.action_inv(last(max2), v2)
    end
end
