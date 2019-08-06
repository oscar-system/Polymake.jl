@testset "converting" begin
    @test Polymake.convert_to_pm_type(Array{Set{Int32},1}) == pm_Array{pm_Set{Int32}}
    @test Polymake.convert_to_pm_type(Array{Set{Int64},1}) == pm_Array{pm_Set{Int32}}

    y = Vector{Set{Int32}}([Set([3,3]), Set([3]), Set([1,2])])
    @test convert(Polymake.PolymakeType, y) isa pm_Array{pm_Set{Int32}}
    y = Vector{Set{Int64}}([Set([3,3]), Set([3]), Set([1,2])])
    @test convert(Polymake.PolymakeType, y) isa pm_Array{pm_Set{Int32}}
end
