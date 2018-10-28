@testset "pm_Array" begin
    @testset "pm_Array generics: $T " for (T, elt) in [
        (Int32, 2), 
        (Int64, 2),
        (AbstractString, "a"),
        (pm_Set{Int32}, pm_Set{Int32}([1,2,1])), 
        (pm_Matrix{pm_Integer}, pm_Matrix{pm_Integer}([1 0; 2 1])),
        ]
        @test pm_Array{T} <: AbstractVector
        @test pm_Array{T}(3) isa AbstractVector
        @test pm_Array{T}(3) isa pm_Array
        @test pm_Array{T}(3) isa pm_Array{T}
        @test pm_Array{T}(3,elt) isa pm_Array{T}
        arr = pm_Array{T}(3,elt)
        @test length(arr) == 3
        @test eltype(arr) == T
        @test arr[1] isa T
        @test arr[1] == arr[2] == arr[3] == elt
        @test_throws BoundsError arr[0]
        @test_throws BoundsError arr[4]
        @test pm_Array{T}([elt, elt, elt]) == arr
        @test resize!(arr, 5) isa pm_Array{T}
        @test length(arr) == 5
        @test append!(arr, arr) isa pm_Array{T}
        @test length(arr) == 10
        @test fill!(arr, elt) == pm_Array{T}(10, elt)
        @test arr == pm_Array{T}(10, elt)
    end
    
    @testset "pm_Array{pm_Matrix{pm_Integer}}" begin
        elt = [1 2; 3 4]
        T = pm_Matrix{pm_Integer}
        
        @test pm_Array{T}([elt, 2elt]) isa pm_Array
        @test pm_Array{T}([elt, 2elt]) isa pm_Array{T}
        arr = pm_Array{T}([elt, 2elt])
        
        @test arr[1] isa T
        @test eltype(arr[1]) == pm_Integer
        
        v = T(2,2) # initialized as 0-matrix
        @test setindex!(arr, v, 2) == [elt, zeros(Int, 2,2)]
        @test arr[2] == v

        arr[2] = [1 1]
        @test arr[2] == [1 1]
        @test eltype(arr) == T

        @test length(arr) == 2
        @test size(arr) == (2,)
        
        l = length(arr)

        A = append!(deepcopy(arr), arr)
        @test A != arr
        @test length(A) == 2l
        @test A[1] == A[l+1] && A[l] == A[2l]
        
        append!(A, [[1 2 3], [1 2]])
        @test A[end] == [1 2]
        @test A[end-1] == [1 2 3]
        @test length(A) == 2l+2
        @test fill!(A, elt) == pm_Array{T}(2l+2, elt)
        @test A == pm_Array{T}(2l+2, elt)
    end
    
    @testset "pm_Array{pm_Set{Int32}}" begin
        elt = Set([1,2,3,4])
        T = pm_Set{Int32}
        
        @test pm_Array{T}([elt, Set(elt .% 3)]) isa pm_Array
        @test pm_Array{T}([elt, Set(elt .% 3)]) isa pm_Array{T}
        arr = pm_Array{T}([elt, Set(elt .% 3)])
        
        @test arr[1] isa T
        @test eltype(arr[1]) <: Int32
        
        v = T() # empty Set
        @test setindex!(arr, v, 2) == [elt, Set()]
        @test arr[2] == v
        
        arr[2] = Set([1 1])
        @test arr[2] == Set([1,1])
        @test eltype(arr) == T
        
        @test length(arr) == 2
        @test size(arr) == (2,)
        
        l = length(arr)
        
        A = append!(deepcopy(arr), arr)
        @test A != arr
        @test length(A) == 2l
        @test A[1] == A[l+1] && A[l] == A[2l]
        
        append!(A, [[1 2 3], [1 2]])
        @test A[end] == Set([1 2])
        @test A[end-1] == Set([1 2 3])
        @test length(A) == 2l+2
        @test fill!(A, elt) == pm_Array{T}(2l+2, elt)
        @test A == pm_Array{T}(2l+2, elt)
    end
    
end
