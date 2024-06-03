import SparseArrays

# not overloading SparseArrays.spzero on purpose
function spzeros(::Type{T}, n::Base.Integer) where T <:VecOrMat_eltypes
    return SparseVector{to_cxx_type(T)}(n)
end

#functions for input of abstract sparse vector type
function SparseVector{T}(vec::AbstractSparseVector) where T
    sv = spzeros(T, length(vec))
    for (idx, val) in zip(SparseArrays.findnz(vec)...)
        sv[idx] = val
    end
    return sv
end

#functions for input of dense vector type
function SparseVector{T}(vec::AbstractVector) where T
    sv = spzeros(T, length(vec))
    for (idx, val) in enumerate(vec)
        iszero(val) && continue
        sv[idx] = val
    end
    return sv
end

SparseVector(vec::AbstractVector{T}) where T =
    SparseVector{promote_to_pm_type(SparseVector, T)}(vec)

Base.size(v::SparseVector) = (length(v),)

Base.eltype(::Type{<:SparseVector{T}}) where T = to_jl_type(T)

Base.@propagate_inbounds function Base.getindex(V::SparseVector, n::Base.Integer)
    @boundscheck checkbounds(V, n)
    return _getindex(V, convert(Int64, n))
end

Base.@propagate_inbounds function Base.setindex!(V::SparseVector{T}, val, n::Base.Integer) where T
    @boundscheck checkbounds(V, n)
    _setindex!(V, convert(T, val), convert(Int64, n))
    return val
end

function findnz(vec::SparseVector{T}) where T
    I = SparseArrays.nonzeroinds(vec)
    V = to_jl_type(T)[vec[idx] for idx in I]
    return (I, V)
end

SparseArrays.nonzeroinds(vec::SparseVector) = Int[to_one_based_indexing(i) for i in _nzindices(vec)]

SparseArrays.nonzeros(vec::SparseVector{T}) where T = findnz(vec)[2]

function Base.:*(s::Number, vec::SparseVector{T}) where T
    JT = to_jl_type(T)
    P = promote_to_pm_type(SparseVector, promote_type(JT, typeof(s)))
    if P == JT
        return convert(JT, s) * vec
    else
        return convert(P, s) * SparseVector{P}(vec)
    end
end

Base.:*(vec::SparseVector, s::Number) = s * vec

function Base.:/(vec::SparseVector{T}, s::Number) where T
    JT = to_jl_type(T)
    P = promote_to_pm_type(SparseVector, promote_type(JT, typeof(s)))
    if P == JT
        return vec / convert(JT, s)
    else
        return SparseVector{P}(vec) / convert(P, s)
    end
end

# implementation of SparseVector{Bool} with Int64 length using a polymake Set
struct SparseVectorBool <: SparseVector{Bool}
    l::Int64
    s::Set{to_cxx_type(Int64)}
end

spzeros(::Type{Bool}, n::Base.Integer) = SparseVectorBool(n, Polymake.Set{to_cxx_type(Int64)}())

Base.size(v::SparseVector{Bool}) = (v.l,)
Base.eltype(::Type{<:SparseVector{Bool}}) = Bool

Base.@propagate_inbounds function Base.getindex(V::SparseVector{Bool}, n::Base.Integer)
    @boundscheck checkbounds(V, n)
    return in(n, V.s)
end

Base.@propagate_inbounds function Base.setindex!(V::SparseVector{Bool}, val::Bool, n::Base.Integer)
    @boundscheck checkbounds(V, n)
    if val
        push!(V.s, n)
    else
        delete!(V.s, n)
    end
    return val
end

function SparseArrays.nonzeroinds(V::SparseVectorBool)
    return [i for i in V.s]
end

function SparseArrays.nonzeros(V::SparseVectorBool)
    return trues(length(V.s))
end

function _findnz(V::SparseVectorBool)
    len = nnz(V)
    i = Base.Vector{Int64}(undef, len)
    k = 1
    for e in V.s
        i[k] = e
        k += 1
    end
    return i
end

function SparseArrays.findnz(V::SparseVectorBool)
    i = _findnz(V)
    len = nnz(V)
    return (i, trues(len))
end

SparseArrays.nnz(V::SparseVectorBool) = length(V.s)

Base.show(io::IO, tp::MIME"text/plain", V::SparseVectorBool) =
    Base.show(IOContext(io), tp, V)

function Base.show(io::IOContext, ::MIME"text/plain", V::SparseVectorBool)
    t = min(div(displaysize(io)[2], 2 + ndigits(V.l)) - 1, length(V.s))
    l = V.l
    print(io, "$l-element SparseVectorBool\n[")
    join(io, [i for i in V.s][1:t], ", ")
    if (length(V.s) > t)
        print(io, ", …")
    end
    print(io, "]")
end
