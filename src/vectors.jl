pm_Vector{T}(v::AbstractVector) where T = pm_Vector(convert(AbstractVector{T}, v))
function pm_Vector(v::AbstractVector{T}) where T<:Integer
    res = pm_Vector{pm_Integer}(size(v)...)
    res .= v
    return res
end
function pm_Vector(v::AbstractVector{T}) where T<:Rational
    res = pm_Vector{pm_Rational}(size(v)...)
    res .= v
    return res
end

Base.size(v::pm_Vector) = (length(v),)
Base.@propagate_inbounds function Base.getindex(V::pm_Vector, n::Integer)
    @boundscheck 1 <= n <= length(V) || throw(BoundsError(V, n))
    return Polymake._getindex(V, Int(n))
end

Base.@propagate_inbounds function Base.setindex!(V::pm_Vector{T}, val, n::Integer) where T
    @boundscheck 1 <= n <= length(V) || throw(BoundsError(V, n))
    Polymake._setindex!(V, T(val), Int(n))
    return V
end
