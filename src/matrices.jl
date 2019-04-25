@inline function pm_Matrix{T}(mat::AbstractMatrix) where T
    res = pm_Matrix{T}(size(mat)...)
    @inbounds res .= mat
    return res
end

pm_Matrix(mat::AbstractMatrix) = pm_Matrix{convert_to_pm_type(eltype(mat))}(mat)

Base.size(m::pm_Matrix) = (rows(m), cols(m))

Base.@propagate_inbounds function Base.getindex(M::pm_Matrix , i::Integer, j::Integer)
    @boundscheck 1 <= i <= rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= cols(M) || throw(BoundsError(M, [i,j]))
    return _getindex(M, Int(i), Int(j))
end

Base.@propagate_inbounds function Base.setindex!(M::pm_Matrix{T}, val, i::Integer, j::Integer) where T
    @boundscheck 1 <= i <= rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= cols(M) || throw(BoundsError(M, [i,j]))
    _setindex!(M, T(val), Int(i), Int(j))
    return M
end
