using SparseArrays

function pm_IncidenceMatrix{pm_NonSymmetric}(mat::AbstractMatrix)
    res = pm_IncidenceMatrix{pm_NonSymmetric}(size(mat)...)
    @inbounds res .= mat
    return res
end

function pm_IncidenceMatrix{pm_Symmetric}(mat::AbstractMatrix)
    m,n = size(mat)
    m == n || throw(ArgumentError("a symmetric matrix needs to be quadratic"))
    res = pm_IncidenceMatrix{pm_Symmetric}(m,n)
    for i = 1:m
        for j = 1:i
            temp = mat[i,j]
            ((temp == mat[j,i] == 0) | ((temp != 0) & (mat[j,i] != 0))) || throw(ArgumentError("input matrix is not symmetric"))
            res[i,j] = res[j,i] = temp
        end
    end
    return res
end

function pm_IncidenceMatrix{pm_NonSymmetric}(mat::AbstractSparseMatrix)
    res = pm_IncidenceMatrix{pm_NonSymmetric}(size(mat)...)
    r,c,v = findnz(mat)
    for i = 1:length(r)
        res[r[i],c[i]] = v[i]
    end
    return res
end

function pm_IncidenceMatrix{pm_Symmetric}(mat::AbstractSparseMatrix)
    m,n = size(mat)
    m == n || throw(ArgumentError("a symmetric matrix needs to be quadratic"))
    res = pm_IncidenceMatrix{pm_Symmetric}(m,n)
    r,c,v = findnz(mat)
    for i = 1:length(r)
        ((v[i] == mat[c[i],r[i]] == 0) | ((v[i] != 0) & (mat[c[i],r[i]] != 0))) || throw(ArgumentError("input matrix is not symmetric"))
        res[r[i],c[i]] = v[i]
    end
    return res
end

# set default parameter to pm_NonSymmetric
pm_IncidenceMatrix(x...) = pm_IncidenceMatrix{pm_NonSymmetric}(x...)

Base.size(m::pm_IncidenceMatrix) = (rows(m), cols(m))

Base.@propagate_inbounds function Base.getindex(M::pm_IncidenceMatrix , i::Integer, j::Integer)
    @boundscheck checkbounds(M, i, j)
    return _getindex(M, convert(Int64, i), convert(Int64, j))
end

Base.@propagate_inbounds function Base.setindex!(M::pm_IncidenceMatrix, val, i::Integer, j::Integer)
    @boundscheck checkbounds(M, i, j)
    _setindex!(M, !iszero(val), convert(Int64, i), convert(Int64, j))
    return val
end

Base.@propagate_inbounds function row(M::pm_IncidenceMatrix, i::Integer)
    @boundscheck checkbounds(M, i, 1)
    return to_one_based_indexing(_row(M, convert(Int64, i)))
end

Base.@propagate_inbounds function col(M::pm_IncidenceMatrix, j::Integer)
    @boundscheck checkbounds(M, 1, j)
    return to_one_based_indexing(_col(M, convert(Int64, j)))
end

function Base.resize!(M::pm_IncidenceMatrix{pm_NonSymmetric}, m::Integer, n::Integer)
    m >= 0 || throw(DomainError(m, "can not resize to a negative length"))
    n >= 0 || throw(DomainError(n, "can not resize to a negative length"))
    _resize!(M,Int64(m),Int64(n))
end

function Base.resize!(M::pm_IncidenceMatrix{pm_Symmetric}, n::Integer)
    n >= 0 || throw(DomainError(n, "can not resize to a negative length"))
    _resize!(M,Int64(n),Int64(n))
end
