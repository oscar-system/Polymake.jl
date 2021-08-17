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

function findnz(vec::SparseVector{T}) where T
    I = Int[to_one_based_indexing(i) for i in _nzindices(vec)]
    V = to_jl_type(T)[vec[idx] for idx in I]
    return (I, V)
end

# implementation of SparseVector{Bool} with Int64 length using a polymake Set
struct SparseVectorBool <: SparseVector{Bool}
    l::Int64
    s::Set{to_cxx_type(Int64)}
end

spzeros(::Type{Bool}, n::Base.Integer) = SparseVectorBool(n, Polymake.Set{to_cxx_type(Int64)}())

Base.size(v::SparseVector{Bool}) = (v.l,)
Base.eltype(::SparseVector{Bool}) = Bool

Base.show(io::IOContext, ::MIME{Symbol("text/plain")}, v::Polymake.SparseVectorBool) = print(io, length(v), "-element SparseVectorBool. `true` for indices:\n", v.s...)

Base.@propagate_inbounds function Base.getindex(V::SparseVector{Bool}, n::Base.Integer)
    (V.l >= n && n >= 1) || throw(BoundsError(V, n))
    return in(V, n)
end

Base.@propagate_inbounds function Base.setindex!(V::SparseVector{Bool}, val, n::Base.Integer)
    (V.l >= n && n >= 1) || throw(BoundsError(V, n))
    if val
        push!(V.s, n)
    else
        delete!(V.s, n)
    end
    return val
end

function Base.show(io::IO, ::MIME"text/plain", V::SparseVectorBool)
    l = V.l
    print(io, "$l-element SparseVectorBool\n")
    join(io, [i for i in V.s][1:min(20, length(V.s))], ", ")
    if (length(V.s) > 20)
        print(io, ", …")
    end
end
