@testset "Polymake.StdPair" begin
    @testset "Constructors" begin
        @test Polymake.StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}() isa Polymake.StdPair
    end
    

    @testset "Low-level operations" begin
        p = Polymake.StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}(1,2) 
        @test Polymake.first(p) == 1
        @test Polymake.last(p) == 2
        @test p == Polymake.StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}(1,2)
        @test p == Pair(1, 2)
    end

    @testset "High-level operations" begin
        p = Polymake.StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}(1,2) 
        @test +(p...) == 3
    end
    
    @testset "FUNDAMENTAL_GROUP" begin
        t = Polymake.topaz.torus()
        p1 = t.FUNDAMENTAL_GROUP
        @test p1 isa Polymake.StdPair{CxxWrap.CxxLong, Polymake.StdList{Polymake.StdList{Polymake.StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}}}}
        @test first(p1) == 15
        r = last(p1)
        @test r isa Polymake.StdList{Polymake.StdList{Polymake.StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}}}
        @test length(r) == 14
        l = collect(r)[13]
        @test l isa Polymake.StdList{Polymake.StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}}
        @test length(l) == 3
        @test collect(l) == [4 => 1, 13 => 1, 11 => -1]
    end
    
end
