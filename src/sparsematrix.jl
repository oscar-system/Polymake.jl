import SparseArrays

#functions for input of julia sparse matrix type
@inline function pm_SparseMatrix{T}(mat::SparseArrays.SparseMatrixCSC) where T <: pm_VecOrMat_eltypes
    (m,n) = size(mat)
    (r,c,v) = SparseArrays.findnz(mat)
    sm = pm_SparseMatrix{T}(m,n)
    for i = 1:length(r)
        sm[r[i],c[i]] = v[i]
    end
    return sm
end


#functions for input of dense matrix type
@inline function pm_SparseMatrix{T}(mat::AbstractMatrix) where T <: pm_VecOrMat_eltypes
    (m,n) = size(mat)
    sm = pm_SparseMatrix{T}(m,n)
    temp = T(0)
    for i = 1:m
        for j = 1:n
            temp = mat[i,j]
            if !iszero(temp)
                sm[i,j] = temp
            end
        end
    end
    return sm
end

# we can't use convert_to_pm_type(T) below:
# only types in pm_Matrix_suppT are available
pm_SparseMatrix(mat::AbstractMatrix{Int32}) = pm_SparseMatrix{Int32}(mat)
pm_SparseMatrix(mat::AbstractMatrix{T}) where T <: Integer = pm_SparseMatrix{pm_Integer}(mat)
pm_SparseMatrix(mat::AbstractMatrix{T}) where T <: Union{Rational, pm_Rational} = pm_SparseMatrix{pm_Rational}(mat)
pm_SparseMatrix(mat::AbstractMatrix{T}) where T <: AbstractFloat = pm_SparseMatrix{Float64}(mat)

pm_SparseMatrix(mat::M) where M <: pm_SparseMatrix{Float64} = mat

Base.size(m::pm_SparseMatrix) = (Int(rows(m)), Int(cols(m)))

Base.@propagate_inbounds function Base.getindex(M::pm_SparseMatrix , i::Integer, j::Integer)
    @boundscheck 1 <= i <= rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= cols(M) || throw(BoundsError(M, [i,j]))
    return _getindex(M, convert(Int64, i), convert(Int64, j))
end

Base.@propagate_inbounds function Base.setindex!(M::pm_SparseMatrix{T}, val, i::Integer, j::Integer) where T
    @boundscheck 1 <= i <= rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= cols(M) || throw(BoundsError(M, [i,j]))
    _setindex!(M, convert(T, val), convert(Int64, i), convert(Int64, j))
    return val
end

function SparseArrays.findnz(mat::pm_SparseMatrix{T}) where T <: pm_VecOrMat_eltypes
    nzi = nzindices(mat)
    len = sum(length, nzi)
    ri = Vector{Int64}(undef, len)
    ci = Vector{Int64}(undef, len)
    v = Vector{T}(undef, len)
    k = 1
    for r = 1:length(nzi)
        for c in nzi[r]
            ri[k] = r
            ci[k] = c + 1
            v[k] = mat[r, c + 1]
            k += 1
        end
    end
    return (ri,ci,v)
end
