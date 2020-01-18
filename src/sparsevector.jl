import SparseArrays

#functions for input of julia sparse vector type
@inline function pm_SparseVector{T}(vec::AbstractSparseVector) where T <: pm_VecOrMat_eltypes
    n = length(vec)
    (p,v) = SparseArrays.findnz(vec)
    sv = pm_SparseVector{T}(n)
    for i = 1:length(p)
        sv[p[i]] = v[i]
    end
    return sv
end

#functions for input of dense vector type
@inline function pm_SparseVector{T}(vec::AbstractVector) where T <: pm_VecOrMat_eltypes
    n = length(vec)
    sv = pm_SparseVector{T}(n)
    temp = T(0)
    for i = 1:n
        temp = vec[i]
        if !iszero(temp)
            sv[i] = temp
        end
    end
    return sv
end

pm_SparseVector(vec::AbstractVector{Int32}) = pm_SparseVector{Int32}(vec)
pm_SparseVector(vec::AbstractVector{T}) where T <: Integer = pm_SparseVector{pm_Integer}(vec)
pm_SparseVector(vec::AbstractVector{T}) where T <: Union{Rational, pm_Rational} = pm_SparseVector{pm_Rational}(vec)
pm_SparseVector(vec::AbstractVector{T}) where T <: AbstractFloat = pm_SparseVector{Float64}(vec)

Base.size(v::pm_SparseVector) = (Int(length(v)),)

Base.@propagate_inbounds function Base.getindex(V::pm_SparseVector, n::Integer)
    @boundscheck 1 <= n <= length(V) || throw(BoundsError(V, n))
    return _getindex(V, convert(Int64, n))
end

Base.@propagate_inbounds function Base.setindex!(V::pm_SparseVector{T}, val, n::Integer) where T
    @boundscheck 1 <= n <= length(V) || throw(BoundsError(V, n))
    _setindex!(V, convert(T, val), convert(Int64, n))
    return val
end
