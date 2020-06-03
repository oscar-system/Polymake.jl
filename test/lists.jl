@testset "Polymake.StdList" begin
    @testset "Constructors" begin
        
        l = Polymake.StdList{Polymake.StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}}()
        @test l isa Polymake.StdList
        k = Polymake.StdList{Polymake.StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}}(l)
        @test k isa Polymake.StdList

    end

    @testset "List operations" begin
        l = Polymake.StdList{Polymake.StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}}()
        p = Polymake.StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}(4,2) 
        push!(l,p)
        @test Polymake.length(l) == 1;
        q = Polymake.StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}(1,2) 
        Polymake.pushfirst!(l, q)
        a = collect(l)
        @test a[1] == (1=>2)
        @test a[2] == (4=>2)
        
        Polymake.empty!(l)
        @test Polymake.isempty(l) == true;
    end 
end
