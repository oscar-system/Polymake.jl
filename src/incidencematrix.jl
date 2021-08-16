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

function IncidenceMatrix{NonSymmetric}(TrueIndices::Base.Array{Base.Array{Int64,1},1}) where T
    m = length(TrueIndices)
    n = maximum([maximum(set) for set in TrueIndices])
    res = IncidenceMatrix(m, n)
    i = 1
    for set in TrueIndices
        for j in set
            res[i,j] = 1
        end
        i = i+1
    end
   return res
end

# set default parameter to NonSymmetric
IncidenceMatrix(x...) = IncidenceMatrix{NonSymmetric}(x...)

Base.size(m::IncidenceMatrix) = (nrows(m), ncols(m))

Base.eltype(::IncidenceMatrix) = Bool

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
    len = sum(([length(row(M, i)) for i in 1:size(M, 1)]))
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

function Base.show(io::IO, ::MIME"text/plain", M::IncidenceMatrix)
    m,n = size(M)
    print(io, "$m×$n IncidenceMatrix\n")
    for i in 1:min(20, size(M, 1))
        print(io, "($i) - ")
        join(io, [i for i in M[i,:].s][1:min(20,length(M[i,:].s))], ", ")
        if (length(M[i,:]) > 20)
            print(io, ", …")
        end
        print(io, "\n")
    end
    if (size(M, 1) > 20)
        print(io, "⁝")
    end
end

function Base.show(io::IOContext, ::MIME{Symbol("text/plain")}, M::IncidenceMatrix)
    m,n = size(M)
    print(io, "$m×$n IncidenceMatrix\n")
    for i in 1:min(20, size(M, 1))
        print(io, "($i) - ")
        join(io, [i for i in M[i,:].s][1:min(20,length(M[i,:].s))], ", ")
        if (length(M[i,:]) > 20)
            print(io, ", …")
        end
        print(io, "\n")
    end
    if (size(M, 1) > 20)
        print(io, "⁝")
    end
end
