@testset "Polymake.HomologyGroup" begin
    
    @testset "read data" begin
        kb = Polymake.topaz.klein_bottle().HOMOLOGY
        @test Polymake.torsion(kb[1]) isa Polymake.StdList{Polymake.StdPair{Polymake.Integer, Polymake.to_cxx_type(Int64)}}
        @test Polymake.betti_number(kb[1]) isa Polymake.to_cxx_type(Int64)
        @test collect.(Polymake.torsion.(kb)) == [[], [2 => 1], []]
        @test Polymake.betti_number.(kb) == [0, 1, 0]
        t = Polymake.topaz.torus().HOMOLOGY
        @test collect.(Polymake.torsion.(t)) == [[], [], []]
        @test Polymake.betti_number.(t) == [0, 2, 1]
        rpp = Polymake.topaz.real_projective_plane().HOMOLOGY
        @test collect.(Polymake.torsion.(rpp)) == [[], [2 => 1], []]
        @test Polymake.betti_number.(rpp) == [0, 0, 0]
        cpp = Polymake.topaz.complex_projective_plane().HOMOLOGY
        @test collect.(Polymake.torsion.(cpp)) == [[], [], [], [], []]
        @test Polymake.betti_number.(cpp) == [0, 0, 1, 0, 1]
    end
    
end