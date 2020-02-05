import SparseArrays

#functions for input of julia sparse vector type
@inline function SparseVector{T}(vec::AbstractSparseVector) where T <: VecOrMat_eltypes
    n = length(vec)
    (p,v) = SparseArrays.findnz(vec)
    sv = SparseVector{T}(n)
    for i = 1:length(p)
        sv[p[i]] = v[i]
    end
    return sv
end

#functions for input of dense vector type
@inline function SparseVector{T}(vec::AbstractVector) where T <: VecOrMat_eltypes
    n = length(vec)
    sv = SparseVector{T}(n)
    temp = T(0)
    for i = 1:n
        temp = vec[i]
        if !iszero(temp)
            sv[i] = temp
        end
    end
    return sv
end

SparseVector(vec::AbstractVector{Int64}) = SparseVector{Int64}(vec)
SparseVector(vec::AbstractVector{T}) where T <: Base.Integer = SparseVector{Integer}(vec)
SparseVector(vec::AbstractVector{T}) where T <: Union{Base.Rational, Rational} = SparseVector{Rational}(vec)
SparseVector(vec::AbstractVector{T}) where T <: AbstractFloat = SparseVector{Float64}(vec)

Base.size(v::SparseVector) = (Int(length(v)),)

Base.@propagate_inbounds function Base.getindex(V::SparseVector, n::Base.Integer)
    @boundscheck 1 <= n <= length(V) || throw(BoundsError(V, n))
    return _getindex(V, convert(Int64, n))
end

Base.@propagate_inbounds function Base.setindex!(V::SparseVector{T}, val, n::Base.Integer) where T
    @boundscheck 1 <= n <= length(V) || throw(BoundsError(V, n))
    _setindex!(V, convert(T, val), convert(Int64, n))
    return val
end

function SparseArrays.findnz(vec::SparseVector{T}) where T <: VecOrMat_eltypes
    nzi = nzindices(vec)
    len = length(nzi)
    ei = Base.Vector{Int64}(undef, len)
    v = Base.Vector{T}(undef, len)
    k = 1
    for e in nzi
        ei[k] = e + 1
        v[k] = vec[e + 1]
        k += 1
    end
    return (ei,v)
end
