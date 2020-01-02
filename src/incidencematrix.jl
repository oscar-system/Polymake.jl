using SparseArrays

@inline function pm_IncidenceMatrix{pm_NonSymmetric}(mat::AbstractMatrix)
    res = pm_IncidenceMatrix{pm_NonSymmetric}(size(mat)...)
    @inbounds res .= mat
    return res
end

@inline function pm_IncidenceMatrix{pm_Symmetric}(mat::AbstractMatrix)
    m,n = size(mat)
    res = pm_IncidenceMatrix{pm_Symmetric}(m,n)
    if (m <= n)
        for j = 1:n
            for i = 1:min(j,m)
                res[i,j] = mat[i,j]
            end
        end
    else
        for i = 1:m
            for j = 1:min(i,n)
                res[i,j] = mat[i,j]
            end
        end
    end
    return res
end

@inline function pm_IncidenceMatrix{pm_NonSymmetric}(mat::AbstractSparseMatrix)
    res = pm_IncidenceMatrix{pm_NonSymmetric}(size(mat)...)
    r,c,v = findnz(mat)
    for i = 1:length(r)
        res[r[i],c[i]] = v[i]
    end
    return res
end

@inline function pm_IncidenceMatrix{pm_NonSymmetric}(mat::AbstractSparseMatrix)
    m,n = size(mat)
    res = pm_IncidenceMatrix{pm_NonSymmetric}(
    r,c,v = findnz(mat)
    if (m <= n)
        for i = 1:length(r)
            if (r[i] <= c[i])
                res[r[i],c[i]] = v[i]
            end
        end
    else
        for i = 1:length(r)
            if (r[i] >= c[i])
                res[r[i],c[i]] = v[i]
            end
        end
    end
    return res
end

Base.@propagate_inbounds function Base.getindex(M::pm_IncidenceMatrix , i::Integer, j::Integer)
    @boundscheck 1 <= i <= rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= cols(M) || throw(BoundsError(M, [i,j]))
    return _getindex(M, convert(Int64, i), convert(Int64, j))
end

Base.@propagate_inbounds function Base.setindex!(M::pm_IncidenceMatrix, val, i::Integer, j::Integer)
    @boundscheck 1 <= i <= rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= cols(M) || throw(BoundsError(M, [i,j]))
    _setindex!(M, convert(Int64, val), convert(Int64, i), convert(Int64, j))
    return val
end
