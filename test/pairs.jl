@testset "Polymake.StdPair" begin

    @testset "Constructors" begin
        @test Polymake.StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}() isa Polymake.StdPair
    end
    

    @testset "Low-level operations" begin
        p = Polymake.StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}(1,2) 
	@test Polymake.first(p) == 1
	@test Polymake.last(p) == 2
    end

    @testset "High-level operations" begin
        p = Polymake.StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}(1,2) 
	@test +(p...) == 3
    end
    
end
