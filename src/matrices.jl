function Matrix{T}(::UndefInitializer, m::Base.Integer, n::Base.Integer) where
    T <:VecOrMat_eltypes
    return Matrix{to_cxx_type(T)}(convert(Int64, m), convert(Int64,n))
end

function Matrix{Polynomial{Rational, CxxWrap.CxxLong}}(::UndefInitializer, m::Base.Integer, n::Base.Integer)
    return _same_element_matrix(Polynomial{Rational, CxxWrap.CxxLong}([0], permutedims([0])), convert(Int64, m), convert(Int64, n))
end

function Matrix{T}(mat::AbstractMatrix) where T
    res = Matrix{T}(undef, size(mat)...)
    @inbounds res .= mat
    return res
end

Matrix(mat::AbstractMatrix{T}) where T =
    Matrix{promote_to_pm_type(Matrix, T)}(mat)

Base.size(m::Matrix) = (nrows(m), ncols(m))

Base.eltype(v::Matrix{T}) where T = to_jl_type(T)

function Base.vcat(M::Matrix...)
    all(==(ncols(first(M))), ncols.(M)) || throw(DimensionMismatch("matrices must have the same number of columns"))
    T = convert_to_pm_type(Base.promote_eltype(M...))
    return reduce(_vcat, Matrix{T}.(M))
end
function Base.hcat(M::Matrix...)
    all(==(nrows(first(M))), nrows.(M)) || throw(DimensionMismatch("matrices must have the same number of rows"))
    T = convert_to_pm_type(Base.promote_eltype(M...))
    return reduce(_hcat, Matrix{T}.(M))
end

Base.@propagate_inbounds function Base.getindex(M::Matrix , i::Base.Integer, j::Base.Integer)
    @boundscheck checkbounds(M, i, j)
    return _getindex(M, convert(Int64, i), convert(Int64, j))
end

Base.@propagate_inbounds function Base.setindex!(M::Matrix{T}, val, i::Base.Integer, j::Base.Integer) where T
    @boundscheck checkbounds(M, i, j)
    _setindex!(M, convert(T, val), convert(Int64, i), convert(Int64, j))
    return M
end

#create Matrix from a sparse matrix
function Matrix(mat::AbstractSparseMatrix{T}) where T
    row, col, val = SparseArrays.findnz(mat)
    res = Matrix{T}(undef, size(mat)...)
    for (r, c, v) in zip(row, col, val)
        res[r, c] = v
    end
    return res
end
