### convert TO polymake object

pm_Array{T}(v::AbstractVector) where T = pm_Array(convert(AbstractVector{T}, v))
function pm_Array(v::AbstractVector{T}) where T 
    arr = pm_Array{T}(length(v))
    @inbounds for i in 1:length(v)
        arr[i] = v[i]
    end
    return arr
end

Base.size(a::pm_Array) = (length(a),)

Base.@propagate_inbounds function getindex(A::pm_Array, n::Integer)
    @boundscheck 1 <= n <= length(A) || throw(BoundsError(A, n))
    return _getindex(A, Int(n))
end

Base.@propagate_inbounds function Base.setindex!(A::pm_Array{T}, val, n::Integer) where T
    @boundscheck 1 <= n <= length(A) || throw(BoundsError(A, n))
    _setindex!(A, T(val), Int(n))
    return A
end

function Base.append!(A::pm_Array{T}, itr) where T
    n = length(A)
    m = length(itr)
    resize!(A, n+m)
    for i in 1:m
        A[n+i] = itr[i]
    end
    return A
end
