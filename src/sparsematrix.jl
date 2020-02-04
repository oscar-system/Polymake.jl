import SparseArrays

#functions for input of julia sparse matrix type
@inline function SparseMatrix{T}(mat::SparseArrays.SparseMatrixCSC) where T <: VecOrMat_eltypes
    (m,n) = size(mat)
    (r,c,v) = SparseArrays.findnz(mat)
    sm = SparseMatrix{T}(m,n)
    for i = 1:length(r)
        sm[r[i],c[i]] = v[i]
    end
    return sm
end


#functions for input of dense matrix type
@inline function SparseMatrix{T}(mat::AbstractMatrix) where T <: VecOrMat_eltypes
    (m,n) = size(mat)
    sm = SparseMatrix{T}(m,n)
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
# only types in Matrix_suppT are available
SparseMatrix(mat::AbstractMatrix{Int64}) = SparseMatrix{Int64}(mat)
SparseMatrix(mat::AbstractMatrix{T}) where T <: Base.Integer = SparseMatrix{Integer}(mat)
SparseMatrix(mat::AbstractMatrix{T}) where T <: Union{Base.Rational, Rational} = SparseMatrix{Rational}(mat)
SparseMatrix(mat::AbstractMatrix{T}) where T <: AbstractFloat = SparseMatrix{Float64}(mat)

SparseMatrix(mat::M) where M <: SparseMatrix{Float64} = mat
Base.size(m::SparseMatrix) = (nrows(m), ncols(m))


Base.@propagate_inbounds function Base.getindex(M::SparseMatrix , i::Base.Integer, j::Base.Integer)
    @boundscheck 1 <= i <= rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= cols(M) || throw(BoundsError(M, [i,j]))
    return _getindex(M, convert(Int64, i), convert(Int64, j))
end

Base.@propagate_inbounds function Base.setindex!(M::SparseMatrix{T}, val, i::Base.Integer, j::Base.Integer) where T
    @boundscheck 1 <= i <= rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= cols(M) || throw(BoundsError(M, [i,j]))
    _setindex!(M, convert(T, val), convert(Int64, i), convert(Int64, j))
    return val
end

function SparseArrays.findnz(mat::SparseMatrix{T}) where T <: VecOrMat_eltypes
    nzi = nzindices(mat)
    len = sum(length, nzi)
    ri = Base.Vector{Int64}(undef, len)
    ci = Base.Vector{Int64}(undef, len)
    v = Base.Vector{T}(undef, len)
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
