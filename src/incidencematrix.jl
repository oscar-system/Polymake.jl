using SparseArrays

function IncidenceMatrix{S}(::UndefInitializer, n::Base.Integer, m::Base.Integer) where
    S <: Union{NonSymmetric, Symmetric}
    return IncidenceMatrix{S}(convert(Int64, n), convert(Int64, m))
end

function IncidenceMatrix{Symmetric}(::UndefInitializer, n::Base.Integer)
    return IncidenceMatrix{Symmetric}(convert(Int64, n), convert(Int64, n))
end

function IncidenceMatrix{NonSymmetric}(mat::AbstractMatrix)
    res = IncidenceMatrix{NonSymmetric}(undef, size(mat)...)
    if eltype(mat) != Bool && any(x->!isone(x) && !iszero(x), mat)
       throw(ArgumentError("matrix entries must be 0 or 1"))
    end
    @inbounds res .= mat
    return res
end

function IncidenceMatrix{Symmetric}(mat::AbstractMatrix)
    m,n = size(mat)
    m == n || throw(ArgumentError("a symmetric matrix needs to be quadratic"))
    res = IncidenceMatrix{Symmetric}(undef, m,n)
    for i = 1:m
        for j = 1:i
            temp = mat[i,j]
            ((temp == mat[j,i] == 0) | ((temp != 0) & (mat[j,i] != 0))) || throw(ArgumentError("input matrix is not symmetric"))
            res[i,j] = res[j,i] = temp
        end
    end
    return res
end

function IncidenceMatrix{NonSymmetric}(mat::AbstractSparseMatrix)
    res = IncidenceMatrix{NonSymmetric}(size(mat)...)
    r,c,v = findnz(mat)
    for i = 1:length(r)
        res[r[i],c[i]] = v[i]
    end
    return res
end

function IncidenceMatrix{Symmetric}(mat::AbstractSparseMatrix)
    m,n = size(mat)
    m == n || throw(ArgumentError("a symmetric matrix needs to be quadratic"))
    res = IncidenceMatrix{Symmetric}(m,n)
    r,c,v = findnz(mat)
    for i = 1:length(r)
        ((v[i] == mat[c[i],r[i]] == 0) | ((v[i] != 0) & (mat[c[i],r[i]] != 0))) || throw(ArgumentError("input matrix is not symmetric"))
        res[r[i],c[i]] = v[i]
    end
    return res
end

function IncidenceMatrix{NonSymmetric}(r::Base.Integer, c::Base.Integer, incidenceRows::AbstractVector{<:AbstractVector{<:Base.Integer}})
    res = IncidenceMatrix(r, c)
    i = 1
    for set in incidenceRows
        for j in set
            res[i,j] = 1
        end
        i = i+1
    end
    return res
end

function IncidenceMatrix{NonSymmetric}(incidenceRows::AbstractVector{<:AbstractVector{<:Base.Integer}})
    r = length(incidenceRows)
    c = maximum(x->maximum(x; init=0), incidenceRows; init=0)
    return IncidenceMatrix{NonSymmetric}(r, c, incidenceRows)
end

# set default parameter to NonSymmetric
IncidenceMatrix(x...) = IncidenceMatrix{NonSymmetric}(x...)

Base.size(m::IncidenceMatrix) = (nrows(m), ncols(m))

Base.eltype(::Type{<:IncidenceMatrix}) = Bool

Base.@propagate_inbounds function Base.getindex(M::IncidenceMatrix , i::Base.Integer, j::Base.Integer)
    @boundscheck checkbounds(M, i, j)
    return _getindex(M, convert(Int64, i), convert(Int64, j))
end

Base.@propagate_inbounds function Base.setindex!(M::IncidenceMatrix, val, i::Base.Integer, j::Base.Integer)
    @boundscheck checkbounds(M, i, j)
    _setindex!(M, !iszero(val), convert(Int64, i), convert(Int64, j))
    return val
end

Base.@propagate_inbounds function row(M::IncidenceMatrix, i::Base.Integer)
    @boundscheck checkbounds(M, i, :)
    return to_one_based_indexing(_row(M, convert(Int64, i)))
end

Base.@propagate_inbounds function col(M::IncidenceMatrix, j::Base.Integer)
    @boundscheck checkbounds(M, :, j)
    return to_one_based_indexing(_col(M, convert(Int64, j)))
end

function _findnz(M::IncidenceMatrix)
    len = sum(length, (row(M, i) for i in 1:size(M, 1)))
    ri = Base.Vector{Int64}(undef, len)
    ci = Base.Vector{Int64}(undef, len)
    k = 1
    for i in 1:size(M, 1)
        for j in row(M, i)
            ri[k] = i
            ci[k] = j
            k += 1
        end
    end
    return (ri, ci)
end

function SparseArrays.findnz(M::IncidenceMatrix)
    ri, ci = _findnz(M)
    len = length(ri)
    return (ri, ci, trues(len))
end

function Base.resize!(M::IncidenceMatrix{NonSymmetric}, m::Base.Integer, n::Base.Integer)
    m >= 0 || throw(DomainError(m, "can not resize to a negative length"))
    n >= 0 || throw(DomainError(n, "can not resize to a negative length"))
    _resize!(M,Int64(m),Int64(n))
end

function Base.resize!(M::IncidenceMatrix{Symmetric}, n::Base.Integer)
    n >= 0 || throw(DomainError(n, "can not resize to a negative length"))
    _resize!(M,Int64(n),Int64(n))
end

function Base.vcat(M::IncidenceMatrix...)
    all(==(ncols(first(M))),ncols.(M)) || throw(DimensionMismatch("matrices must have the same number of columns"))
    return reduce(_vcat, M)
end
function Base.hcat(M::IncidenceMatrix...)
    all(==(nrows(first(M))),nrows.(M)) || throw(DimensionMismatch("matrices must have the same number of rows"))
    return reduce(_hcat, M)
end

Base.show(io::IO, tp::MIME{Symbol("text/plain")}, M::IncidenceMatrix) =
    Base.show(IOContext(io), tp, M)

function Base.show(io::IOContext, ::MIME{Symbol("text/plain")}, M::IncidenceMatrix)
    m,n = size(M)
    a,b = displaysize(io)
    s = min(a - 5, m)
    print(io, "$m×$n IncidenceMatrix")
    for i in 1:s
        println(io)
        t = min(div(b, 2 + ndigits(n)) - 1, length(row(M, i)))
        print(io, " [")
        join(io, [c for c in row(M, i)][1:t], ", ")
        if (length(row(M,i)) > t)
            print(io, ", …")
        end
        print(io, "]")
    end
    if (m > s)
        print(io, "\n ⁝")
    end
end
