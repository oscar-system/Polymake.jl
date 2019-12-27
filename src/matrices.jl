@inline function pm_Matrix{T}(mat::AbstractMatrix) where T <: pm_VecOrMat_eltypes
    res = pm_Matrix{T}(size(mat)...)
    @inbounds res .= mat
    return res
end

# we can't use convert_to_pm_type(T) below:
# only types in pm_VecOrMat_eltypes are available
pm_Matrix(mat::AbstractMatrix{Int32}) = pm_Matrix{Int32}(mat)
pm_Matrix(mat::AbstractMatrix{T}) where T <: Integer = pm_Matrix{pm_Integer}(mat)
pm_Matrix(mat::AbstractMatrix{T}) where T <: Union{Rational, pm_Rational} = pm_Matrix{pm_Rational}(mat)
pm_Matrix(mat::AbstractMatrix{T}) where T <: AbstractFloat = pm_Matrix{Float64}(mat)

# no-copy constructor for pm_Matrix{Float64} (it's stored as a continuous block)
pm_Matrix(mat::M) where M <: pm_Matrix{Float64} = mat

Base.size(m::pm_Matrix) = (rows(m), cols(m))

Base.@propagate_inbounds function Base.getindex(M::pm_Matrix , i::Integer, j::Integer)
    @boundscheck 1 <= i <= rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= cols(M) || throw(BoundsError(M, [i,j]))
    return _getindex(M, convert(Int64, i), convert(Int64, j))
end

Base.@propagate_inbounds function Base.setindex!(M::pm_Matrix{T}, val, i::Integer, j::Integer) where T
    @boundscheck 1 <= i <= rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= cols(M) || throw(BoundsError(M, [i,j]))
    _setindex!(M, convert(T, val), convert(Int64, i), convert(Int64, j))
    return M
end

#create pm_Matrix from a sparse matrix
function pm_Matrix{T}(mat::AbstractSparseMatrix) where T <: pm_VecOrMat_eltypes
    r,c,v = SparseArrays.findnz(mat)
    res = pm_Matrix{T}(size(mat))
    for i = 1:length(r)
        res[r[i],c[i]] = v[i]
    end
    return res
end
