const pm_SparseMatrix_suppT = Union{Int32, pm_Integer, pm_Rational, Float64}

@inline function pm_SparseMatrix{T}(mat::AbstractMatrix) where T <: pm_SparseMatrix_suppT
    res = pm_Matrix{T}(size(mat)...)
    @inbounds res .= mat
    return pm_SparseMatrix(res)
end

# needed for broadcast
@inline function pm_SparseMatrix{T}(rows::UR, cols::UR) where {T <: pm_SparseMatrix_suppT, UR<:Base.AbstractUnitRange}
    return pm_SparseMatrix{T}(length(rows), length(cols))
end

#derive parameter from input matrix
pm_SparseMatrix(mat::pm_Matrix{T}) where T <: pm_SparseMatrix_suppT = pm_SparseMatrix{T}(mat)

# we can't use convert_to_pm_type(T) below:
# only types in pm_Matrix_suppT are available
pm_SparseMatrix(mat::AbstractMatrix{Int32}) = pm_SparseMatrix{Int32}(pm_Matrix(mat))
pm_SparseMatrix(mat::AbstractMatrix{T}) where T <: Integer = pm_SparseMatrix(pm_Matrix{pm_Integer}(mat))
pm_SparseMatrix(mat::AbstractMatrix{T}) where T <: Union{Rational, pm_Rational} = pm_SparseMatrix(pm_Matrix{pm_Rational}(mat))
pm_SparseMatrix(mat::AbstractMatrix{T}) where T <: AbstractFloat = pm_SparseMatrix(pm_Matrix{Float64}(mat))

pm_Matrix(mat::M) where M <: pm_SparseMatrix{Float64} = mat

Base.size(m::pm_SparseMatrix) = (rows(m), cols(m))

Base.@propagate_inbounds function Base.getindex(M::pm_SparseMatrix , i::Integer, j::Integer)
    @boundscheck 1 <= i <= rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= cols(M) || throw(BoundsError(M, [i,j]))
    return _getindex(M, convert(Int64, i), convert(Int64, j))
end

Base.@propagate_inbounds function Base.setindex!(M::pm_SparseMatrix{T}, val, i::Integer, j::Integer) where T
    @boundscheck 1 <= i <= rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= cols(M) || throw(BoundsError(M, [i,j]))
    _setindex!(M, convert(T, val), convert(Int64, i), convert(Int64, j))
    return M
end
