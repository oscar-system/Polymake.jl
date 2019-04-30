@inline function pm_Matrix{T}(mat::AbstractMatrix) where T
    res = pm_Matrix{T}(size(mat)...)
    @inbounds res .= mat
    return res
end

# needed for broadcast
@inline function pm_Matrix{T}(rows::UR, cols::UR) where {T, UR<:Base.AbstractUnitRange}
    return pm_Matrix{T}(length(rows), length(cols))
end

pm_Matrix(mat::AbstractMatrix) = pm_Matrix{convert_to_pm_type(eltype(mat))}(mat)

Base.size(m::pm_Matrix) = (rows(m), cols(m))

Base.@propagate_inbounds function Base.getindex(M::pm_Matrix , i::Integer, j::Integer)
    @boundscheck 1 <= i <= rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= cols(M) || throw(BoundsError(M, [i,j]))
    return _getindex(M, convert(Int64, i), convert(Int64, j))
end

Base.@propagate_inbounds function Base.setindex!(M::pm_Matrix{T}, val, i::Integer, j::Integer) where T
    @boundscheck 1 <= i <= rows(M) || throw(BoundsError(M, [i,j]))
    @boundscheck 1 <= j <= cols(M) || throw(BoundsError(M, [i,j]))
    _setindex!(M, convert(T, val), convert(Int64, i), convert(Int64, j))
    return M
end

function Base.similar(mat::pm_Matrix, ::Type{S}, dims::Dims{2}) where S<:Union{pm_Integer, pm_Rational, Float64}
    return pm_Matrix{convert_to_pm_type(S)}(dims...)
end

function Base.similar(mat::pm_Matrix, ::Type{S}, dims::Dims{1}) where S<:Union{pm_Integer, pm_Rational, Float64}
    return pm_Vector{convert_to_pm_type(S)}(dims...)
end

Base.BroadcastStyle(::Type{<:pm_Matrix}) = Broadcast.ArrayStyle{pm_Matrix}()

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{pm_Matrix}},
    ::Type{ElType}) where ElType
    return pm_Matrix{convert_to_pm_type(ElType)}(axes(bc)...)
end
