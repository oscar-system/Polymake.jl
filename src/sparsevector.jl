import SparseArrays

# not overloading SparseArrays.spzero on purpose
function spzeros(::Type{T}, n::Base.Integer) where T <:VecOrMat_eltypes
    return SparseVector{to_cxx_type(T)}(n)
end

#functions for input of julia sparse vector type
function SparseVector{T}(vec::AbstractSparseVector) where T
    n = length(vec)
    (p,v) = SparseArrays.findnz(vec)
    sv = spzeros(T, n)
    for i = 1:length(p)
        sv[p[i]] = v[i]
    end
    return sv
end

#functions for input of dense vector type
@inline function SparseVector{T}(vec::AbstractVector) where T
    n = length(vec)
    sv = spzeros(T, n)
    temp = zero(T)
    for i = 1:n
        temp = vec[i]
        if !iszero(temp)
            sv[i] = temp
        end
    end
    return sv
end

SparseVector(vec::AbstractVector{T}) where T =
    SparseVector{promote_to_pm_type(SparseVector, T)}(vec)

Base.size(v::SparseVector) = (length(v),)

Base.eltype(m::SparseVector{T}) where T = to_jl_type(T)

Base.@propagate_inbounds function Base.getindex(V::SparseVector, n::Base.Integer)
    @boundscheck checkbounds(V, n)
    return _getindex(V, convert(Int64, n))
end

Base.@propagate_inbounds function Base.setindex!(V::SparseVector{T}, val, n::Base.Integer) where T
    @boundscheck checkbounds(V, n)
    _setindex!(V, convert(T, val), convert(Int64, n))
    return val
end

function SparseArrays.findnz(vec::SparseVector{T}) where T
    nzi = nzindices(vec)
    len = length(nzi)
    ei = Base.Vector{Int64}(undef, len)
    v = Base.Vector{to_jl_type(T)}(undef, len)
    k = 1
    for e in nzi
        ei[k] = e + 1
        v[k] = vec[e + 1]
        k += 1
    end
    return (ei,v)
end
