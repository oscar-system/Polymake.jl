@inline function pm_Vector{T}(vec::AbstractVector) where T
    res = pm_Vector{T}(size(vec)...)
    @inbounds res .= vec
    return res
end

pm_Vector(vec::AbstractVector) = pm_Vector{convert_to_pm_type(eltype(vec))}(vec)

Base.size(v::pm_Vector) = (length(v),)

Base.@propagate_inbounds function Base.getindex(V::pm_Vector, n::Integer)
    @boundscheck 1 <= n <= length(V) || throw(BoundsError(V, n))
    return _getindex(V, Int(n))
end

Base.@propagate_inbounds function Base.setindex!(V::pm_Vector{T}, val, n::Integer) where T
    @boundscheck 1 <= n <= length(V) || throw(BoundsError(V, n))
    _setindex!(V, T(val), Int(n))
    return V
end
