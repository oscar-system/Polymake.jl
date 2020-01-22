@testset "Polymake.Array" begin
    @testset "Polymake.Array generics: $T " for (T, elt) in [
        (Int32, 2),
        (Int64, 2),
        (Polymake.Integer, Polymake.Integer(2)),
        (Polymake.Rational, Polymake.Rational(2 //3)),
        (AbstractString, "a"),
        (Set{Int32}, Set{Int32}([1,2,1])),
        (Polymake.Matrix{Polymake.Integer}, Polymake.Matrix{Polymake.Integer}([1 0; 2 1])),
        (Polymake.Array{Int32}, Polymake.Array{Int32}(Int32[1, 2, 3])),
        (Polymake.Array{Int64}, Polymake.Array{Int64}(Int64[1, 2, 3])),
        (Polymake.Array{Polymake.Integer}, Polymake.Array{Polymake.Integer}(Polymake.Integer[1, 2, 3])),
        ]
        @test Polymake.Array{T} <: AbstractVector
        @test Polymake.Array{T}(3) isa AbstractVector
        @test Polymake.Array{T}(3) isa Polymake.Array
        @test Polymake.Array{T}(3) isa Polymake.Array{T}
        @test Polymake.Array{T}(3,elt) isa Polymake.Array{T}
        arr = Polymake.Array{T}(3,elt)
        @test length(arr) == 3
        @test eltype(arr) == T
        @test arr[1] isa T
        @test arr[1] == arr[2] == arr[3] == elt
        @test_throws BoundsError arr[0]
        @test_throws BoundsError arr[4]
        @test Polymake.Array{T}([elt, elt, elt]) == arr
        @test resize!(arr, 5) isa Polymake.Array{T}
        @test length(arr) == 5
        @test append!(arr, arr) isa Polymake.Array{T}
        @test length(arr) == 10
        @test fill!(arr, elt) == Polymake.Array{T}(10, elt)
        @test arr == Polymake.Array{T}(10, elt)
    end
    
    @testset "Polymake.Array{Polymake.Matrix{Polymake.Integer}}" begin
        elt = [1 2; 3 4]
        T = Polymake.Matrix{Polymake.Integer}
        
        @test Polymake.Array{T}([elt, 2elt]) isa Polymake.Array
        @test Polymake.Array{T}([elt, 2elt]) isa Polymake.Array{T}
        arr = Polymake.Array{T}([elt, 2elt])
        
        @test arr[1] isa T
        @test eltype(arr[1]) == Polymake.Integer
        
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
        @test fill!(A, elt) == Polymake.Array{T}(2l+2, elt)
        @test A == Polymake.Array{T}(2l+2, elt)
    end
    
    @testset "Polymake.Array{Set{Int32}}" begin
        elt = Set([1,2,3,4])
        T = Set{Int32}
        
        @test Polymake.Array{T}([elt, Set(elt .% 3)]) isa Polymake.Array
        @test Polymake.Array{T}([elt, Set(elt .% 3)]) isa Polymake.Array{T}
        arr = Polymake.Array{T}([elt, Set(elt .% 3)])
        
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
        @test fill!(A, elt) == Polymake.Array{T}(2l+2, elt)
        @test A == Polymake.Array{T}(2l+2, elt)
    end
    
end
