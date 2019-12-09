const pm_SparseVector_suppT = Union{pm_Integer, pm_Rational}

@inline function pm_SparseVector{T}(vec::AbstractVector) where T <: pm_SparseVector_suppT
    res = pm_Vector{T}(size(vec)...)
    @inbounds res .= vec
    return pm_SparseVector(res)
end

pm_SparseVector(vec::pm_Vector{T}) where T <: pm_SparseVector_suppT = pm_SparseVector{T}(vec)

pm_SparseVector(vec::AbstractVector{T}) where T <: Integer = pm_SparseVector(pm_Vector{pm_Integer}(vec))
pm_SparseVector(vec::AbstractVector{T}) where T <: Union{Rational, pm_Rational} = pm_SparseVector(pm_Vector{pm_Rational}(vec))

Base.size(v::pm_SparseVector) = (length(v),)

Base.@propagate_inbounds function Base.getindex(V::pm_SparseVector, n::Integer)
    @boundscheck 1 <= n <= length(V) || throw(BoundsError(V, n))
    return _getindex(V, convert(Int64, n))
end

Base.@propagate_inbounds function Base.setindex!(V::pm_SparseVector{T}, val, n::Integer) where T
    @boundscheck 1 <= n <= length(V) || throw(BoundsError(V, n))
    _setindex!(V, convert(T, val), convert(Int64, n))
    return V
end
