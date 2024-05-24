function Vector{T}(::UndefInitializer, n::Base.Integer) where
    T <: VecOrMat_eltypes
    return Vector{to_cxx_type(T)}(convert(Int64, n))
end

function Vector{Polynomial{Rational, Int64}}(::UndefInitializer, n::Base.Integer)
    return Vector{Polynomial{Rational, CxxWrap.CxxLong}}(convert(Int64, n), Polynomial{Rational, CxxWrap.CxxLong}([0], permutedims([0])))
end

function Vector{T}(vec::AbstractVector) where T
    res = Vector{T}(undef, size(vec)...)
    @inbounds res .= vec
    return res
end

Vector(vec::AbstractVector{T}) where T = Vector{promote_to_pm_type(Vector, T)}(vec)

Base.size(v::Vector) = (length(v),)

Base.eltype(v::Vector{T}) where T = to_jl_type(T)

Base.@propagate_inbounds function Base.getindex(V::Vector, n::Base.Integer)
    @boundscheck checkbounds(V, n)
    return _getindex(V, convert(Int64, n))[]
end

Base.@propagate_inbounds function Base.setindex!(V::Vector{T}, val, n::Base.Integer) where T
    @boundscheck checkbounds(V, n)
    _setindex!(V, convert(T, val), convert(Int64, n))
    return V
end
