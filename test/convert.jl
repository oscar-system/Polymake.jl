@testset "converting" begin
    @test Polymake.convert_to_pm_type(Vector{Int}) == pm_Vector{pm_Integer}
    @test Polymake.convert_to_pm_type(Matrix{Int}) == pm_Matrix{pm_Integer}
    @test Polymake.convert_to_pm_type(Matrix{Rational{BigInt}}) == pm_Matrix{pm_Rational}
    @test Polymake.convert_to_pm_type(pm_Matrix{Rational{BigInt}}) == pm_Matrix{pm_Rational}

    @test Polymake.convert_to_pm_type(Matrix{Float32}) == pm_Matrix{Float64}

    @test Polymake.convert_to_pm_type(Vector{String}) == pm_Array{String}

    @test Polymake.convert_to_pm_type(Array{Set{Int32},1}) == pm_Array{pm_Set{Int32}}
    @test Polymake.convert_to_pm_type(Array{Set{pm_Integer},1}) == pm_Array{pm_Set{Int32}}
    @test Polymake.convert_to_pm_type(Array{Set{Int64},1}) == pm_Array{pm_Set{Int32}}

    @test Polymake.convert_to_pm_type(Vector{Vector{Int64}}) == pm_Array{pm_Array{Int64}}

    y = Vector{Set{Int32}}([Set([3,3]), Set([3]), Set([1,2])])
    @test convert(Polymake.PolymakeType, y) isa pm_Array{pm_Set{Int32}}
    y = Vector{Set{Int64}}([Set([3,3]), Set([3]), Set([1,2])])
    @test convert(Polymake.PolymakeType, y) isa pm_Array{pm_Set{Int32}}
end
