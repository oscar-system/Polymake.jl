const pm_Matrix_suppT = Union{Int32, pm_Integer, pm_Rational, Float64}

@inline function pm_Matrix{T}(mat::AbstractMatrix) where T <: pm_Matrix_suppT
    res = pm_Matrix{T}(size(mat)...)
    @inbounds res .= mat
    return res
end

# needed for broadcast
@inline function pm_Matrix{T}(rows::UR, cols::UR) where {T <: pm_Matrix_suppT, UR<:Base.AbstractUnitRange}
    return pm_Matrix{T}(length(rows), length(cols))
end

# we can't use convert_to_pm_type(T) below:
# only types in pm_Matrix_suppT are available
pm_Matrix(mat::AbstractMatrix{Int32}) = pm_Matrix{Int32}(mat)
pm_Matrix(mat::AbstractMatrix{T}) where T <: Integer = pm_Matrix{pm_Integer}(mat)
pm_Matrix(mat::AbstractMatrix{T}) where T <: Union{Rational, pm_Rational} = pm_Matrix{pm_Rational}(mat)
pm_Matrix(mat::AbstractMatrix{T}) where T <: AbstractFloat = pm_Matrix{Float64}(mat)

# no-copy constructor for pm_Matrix{Float64} (it's stored as a continuous block)
pm_Matrix(mat::M) where M <: pm_Matrix{Float64} = mat

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

function Base.similar(mat::pm_Matrix, ::Type{S}, dims::Dims{2}) where S
    return Matrix{S}(undef, dims...)
end

function Base.similar(mat::pm_Matrix, ::Type{S}, dims::Dims{1}) where S<:Union{pm_Integer, pm_Rational}
    return pm_Vector{convert_to_pm_type(S)}(dims...)
end

function Base.similar(mat::pm_Matrix, ::Type{S}, dims::Dims{1}) where S
    return Vector{S}(undef, dims...)
end

Base.BroadcastStyle(::Type{<:pm_Matrix}) = Broadcast.ArrayStyle{pm_Matrix}()

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{pm_Matrix}},
    ::Type{ElType}) where ElType
    return pm_Matrix{convert_to_pm_type(ElType)}(axes(bc)...)
end
