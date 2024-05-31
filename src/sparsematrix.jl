import SparseArrays

# not overloading SparseArrays.spzero on purpose
function spzeros(::Type{T}, n::Base.Integer, m::Base.Integer) where T <:VecOrMat_eltypes
    return SparseMatrix{to_cxx_type(T)}(n,m)
end

#functions for input of julia sparse matrix type
function SparseMatrix{T}(mat::SparseArrays.SparseMatrixCSC) where T
    (m,n) = size(mat)
    (r,c,v) = SparseArrays.findnz(mat)
    sm = Polymake.spzeros(T, m, n)
    for i = 1:length(r)
        sm[r[i],c[i]] = v[i]
    end
    return sm
end


#functions for input of dense matrix type
@inline function SparseMatrix{T}(mat::AbstractMatrix) where T
    (m,n) = size(mat)
    sm = Polymake.spzeros(T, m, n)
    temp = zero(T)
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

SparseMatrix(mat::AbstractMatrix{T}) where T =
    SparseMatrix{promote_to_pm_type(SparseMatrix, T)}(mat)

Base.size(m::SparseMatrix) = (nrows(m), ncols(m))

Base.eltype(::Type{<:SparseMatrix{T}}) where T = to_jl_type(T)

function Base.vcat(M::Union{SparseMatrix,Matrix}...)
    all(==(ncols(first(M))), ncols.(M)) || throw(DimensionMismatch("matrices must have the same number of columns"))
    T = convert_to_pm_type(Base.promote_eltype(M...))
    return reduce(_vcat, SparseMatrix{T}.(M))
end
function Base.hcat(M::Union{SparseMatrix,Matrix}...)
    all(==(nrows(first(M))), nrows.(M)) || throw(DimensionMismatch("matrices must have the same number of rows"))
    T = convert_to_pm_type(Base.promote_eltype(M...))
    return reduce(_hcat, SparseMatrix{T}.(M))
end

Base.@propagate_inbounds function Base.getindex(M::SparseMatrix , i::Base.Integer, j::Base.Integer)
    @boundscheck checkbounds(M, i, j)
    return _getindex(M, convert(Int64, i), convert(Int64, j))
end

Base.@propagate_inbounds function Base.setindex!(M::SparseMatrix{T}, val, i::Base.Integer, j::Base.Integer) where T
    @boundscheck checkbounds(M, i, j)
    _setindex!(M, convert(T, val), convert(Int64, i), convert(Int64, j))
    return M
end

function SparseArrays.findnz(mat::SparseMatrix{T}) where T
    nzi = nzindices(mat)
    len = sum(length, nzi)
    ri = Base.Vector{Int64}(undef, len)
    ci = Base.Vector{Int64}(undef, len)
    v = Base.Vector{to_jl_type(T)}(undef, len)
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
