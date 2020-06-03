@testset "Polymake.StdList" begin

    @testset "Constructors" begin
        
	l = Polymake.StdList{Polymake.StdPair{Int64, Int64}}()
        @test l isa Polymake.StdList
	k = Polymake.StdList{Polymake.StdPair{Int64, Int64}}(l)
	@test k isa Polymake.StdList

    end

    @testset "List operations" begin
	l = Polymake.StdList{Polymake.StdPair{Int, Int}}()
	p = Polymake.StdPair(4,2)
	push!(l,p)
	@test Polymake.length(l) == 1;
	q = Polymake.StdPair(1,2)
	Polymake.pushfirst!(l, q)
	a = collect(l)
	@test a[1] == (1=>2)
	@test a[2] == (4=>2)
	
	Polymake.empty!(l)
	@test Polymake.isempty(l) == true;
    end
   
end
