using SparseArrays

@inline function pm_IncidenceMatrix{pm_NonSymmetric}(mat::AbstractMatrix)
    res = pm_IncidenceMatrix{pm_NonSymmetric}(size(mat)...)
    @inbounds res .= mat
    return res
end

@inline function pm_IncidenceMatrix{pm_Symmetric}(mat::AbstractMatrix)
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
    res = pm_IncidenceMatrix{pm_NonSymmetric}(m,n)
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

# set default parameter to pm_NonSymmetric
pm_IncidenceMatrix(x...) = pm_IncidenceMatrix{pm_NonSymmetric}(x...)

Base.size(m::pm_IncidenceMatrix) = (rows(m), cols(m))

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
