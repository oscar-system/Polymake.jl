pm_Matrix{T}(v::AbstractMatrix) where T = pm_Matrix(convert(AbstractMatrix{T}, v))
function pm_Matrix(v::AbstractMatrix{T}) where T<:Integer
    res = pm_Matrix{pm_Integer}(size(v)...)
    res .= v
    return res
end
function pm_Matrix(v::AbstractMatrix{T}) where T<:Rational
    res = pm_Matrix{pm_Rational}(size(v)...)
    res .= v
    return res
end

Base.size(m::pm_Matrix) = (Polymake.rows(m), Polymake.cols(m))

Base.@propagate_inbounds function Base.getindex(M::pm_Matrix , i::Integer, j::Integer)
    @boundscheck 1 <= i <= Polymake.rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= Polymake.cols(M) || throw(BoundsError(M, [i,j]))
    return Polymake._getindex(M, Int(i), Int(j))
end

Base.@propagate_inbounds function Base.setindex!(M::pm_Matrix{T}, val, i::Integer, j::Integer) where T
    @boundscheck 1 <= i <= Polymake.rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= Polymake.cols(M) || throw(BoundsError(M, [i,j]))
    Polymake._setindex!(M, T(val), Int(i), Int(j))
    return M
end
