@inline function pm_Vector{T}(vec::AbstractVector) where T <: pm_VecOrMat_eltypes
    res = pm_Vector{T}(size(vec)...)
    @inbounds res .= vec
    return res
end

# we can't use convert_to_pm_type(T) below:
# only types in pm_VecOrMat_eltypes are available
pm_Vector(vec::AbstractVector{Int32}) = pm_Vector{Int32}(vec)
pm_Vector(vec::AbstractVector{T}) where T <: Integer = pm_Vector{pm_Integer}(vec)
pm_Vector(vec::AbstractVector{T}) where T <: Union{Rational, pm_Rational} = pm_Vector{pm_Rational}(vec)
pm_Vector(vec::AbstractVector{T}) where T <: AbstractFloat = pm_Vector{Float64}(vec)

Base.size(v::pm_Vector) = (Int(length(v)),)

Base.@propagate_inbounds function Base.getindex(V::pm_Vector, n::Integer)
    @boundscheck 1 <= n <= length(V) || throw(BoundsError(V, n))
    return _getindex(V, convert(Int64, n))
end

Base.@propagate_inbounds function Base.setindex!(V::pm_Vector{T}, val, n::Integer) where T
    @boundscheck 1 <= n <= length(V) || throw(BoundsError(V, n))
    _setindex!(V, convert(T, val), convert(Int64, n))
    return V
end
