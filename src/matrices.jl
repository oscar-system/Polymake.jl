function Matrix{T}(::UndefInitializer, m::Base.Integer, n::Base.Integer) where
    T <:VecOrMat_eltypes
    return Matrix{to_cxx_type(T)}(convert(Int64, m), convert(Int64,n))
end

function Matrix{T}(mat::AbstractMatrix) where T
    res = Matrix{T}(undef, size(mat)...)
    @inbounds res .= mat
    return res
end

# we can't use convert_to_pm_type(T) below:
# only types in VecOrMat_eltypes are available
Matrix(vec::AbstractMatrix{T}) where T <: Base.Integer = Matrix{promote_type(T,Int64) == Int64 ? Int64 : Integer}(vec)
Matrix(mat::AbstractMatrix{T}) where T <: Union{Base.Rational, Rational} = Matrix{Rational}(mat)
Matrix(mat::AbstractMatrix{T}) where T <: AbstractFloat = Matrix{Float64}(mat)

# no-copy constructor for Matrix{Float64} (it's stored as a continuous block)
Matrix(mat::M) where M <: Matrix{Float64} = mat
Base.size(m::Matrix) = (nrows(m), ncols(m))

Base.eltype(v::Matrix{T}) where T = to_jl_type(T)

Base.@propagate_inbounds function Base.getindex(M::Matrix , i::Base.Integer, j::Base.Integer)
    @boundscheck 1 <= i <= rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= cols(M) || throw(BoundsError(M, [i,j]))
    return _getindex(M, convert(Int64, i), convert(Int64, j))
end

Base.@propagate_inbounds function Base.setindex!(M::Matrix{T}, val, i::Base.Integer, j::Base.Integer) where T
    @boundscheck 1 <= i <= rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= cols(M) || throw(BoundsError(M, [i,j]))
    _setindex!(M, convert(T, val), convert(Int64, i), convert(Int64, j))
    return M
end

#create Matrix from a sparse matrix
function Matrix{T}(mat::AbstractSparseMatrix) where T <: VecOrMat_eltypes
    r,c,v = SparseArrays.findnz(mat)
    res = Matrix{T}(size(mat))
    for i = 1:length(r)
        res[r[i],c[i]] = v[i]
    end
    return res
end
