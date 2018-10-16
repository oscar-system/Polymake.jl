### convert TO polymake object

pm_Array{T}(v::AbstractVector) where T = pm_Array(convert(AbstractVector{T}, v))
pm_Array(v::AbstractVector{T}) where T = Polymake._new_array(v)

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
