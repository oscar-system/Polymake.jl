function pm_Array{T}(vec::AbstractVector) where T
    arr = pm_Array{T}(length(vec))
    @inbounds arr .= vec
    return arr
end

pm_Array{T}(n::Integer, elt) where T = pm_Array{T}(Int64(n), T(elt))
pm_Array(n::Integer, elt::T) where T = pm_Array{T}(Int64(n), elt)

pm_Array(vec::AbstractVector) = pm_Array{convert_to_pm_type(eltype(vec))}(vec)

pm_ArrayAllocated{T}(v) where T = pm_Array{T}(v)

Base.size(a::pm_Array) = (length(a),)

Base.@propagate_inbounds function getindex(A::pm_Array, n::Integer)
    @boundscheck 1 <= n <= length(A) || throw(BoundsError(A, n))
    return _getindex(A, convert(Int64, n))
end

Base.@propagate_inbounds function Base.setindex!(A::pm_Array{T}, val, n::Integer) where T
    @boundscheck 1 <= n <= length(A) || throw(BoundsError(A, n))
    _setindex!(A, convert(T, val), convert(Int64, n))
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

# workarounds for pm_Array{String}
pm_Array{T}(n::Integer) where T<:AbstractString = pm_Array{AbstractString}(convert(Int64, n))
pm_Array{T}(n::Integer, elt::T) where T<:AbstractString =
pm_Array{AbstractString}(convert(Int64, n), elt)

Base.@propagate_inbounds function Base.setindex!(A::pm_Array{S}, val, n::Integer) where {S<:AbstractString}
    @boundscheck 1 <= n <= length(A) || throw(BoundsError(A, n))
    _setindex!(A, string(val), convert(Int64, n))
    return A
end
