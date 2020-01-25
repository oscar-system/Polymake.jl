@inline function Vector{T}(vec::AbstractVector) where T <: VecOrMat_eltypes
    res = Vector{T}(size(vec)...)
    @inbounds res .= vec
    return res
end

# we can't use convert_to_pm_type(T) below:
# only types in VecOrMat_eltypes are available
Vector(vec::AbstractVector{T}) where T <: Base.Integer = Vector{promote_type(T,Int64) == Int64 ? Int64 : Integer}(vec)
Vector(vec::AbstractVector{T}) where T <: Union{Base.Rational, Rational} = Vector{Rational}(vec)
Vector(vec::AbstractVector{T}) where T <: AbstractFloat = Vector{Float64}(vec)

Base.size(v::Vector) = (Int(length(v)),)

Base.@propagate_inbounds function Base.getindex(V::Vector, n::Base.Integer)
    @boundscheck 1 <= n <= length(V) || throw(BoundsError(V, n))
    return _getindex(V, convert(Int64, n))
end

Base.@propagate_inbounds function Base.setindex!(V::Vector{T}, val, n::Base.Integer) where T
    @boundscheck 1 <= n <= length(V) || throw(BoundsError(V, n))
    _setindex!(V, convert(T, val), convert(Int64, n))
    return V
end
