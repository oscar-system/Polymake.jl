@inline function pm_Matrix{T}(rows::UR, cols::UR) where {T <: pm_VecOrMat_eltypes, UR<:Base.AbstractUnitRange}
    return pm_Matrix{T}(length(rows), length(cols))
end

@inline function pm_SparseVector{T}(len::UR) where {T <: pm_VecOrMat_eltypes, UR<:Base.AbstractUnitRange}
    return pm_SparseVector{T}(length(len))
end

Base.similar(X::Union{pm_Vector, pm_Matrix}, ::Type{S}, dims::Dims{1}) where
    {S <: pm_VecOrMat_eltypes} = pm_Vector{convert_to_pm_type(S)}(dims...)

Base.similar(X::Union{pm_Vector, pm_Matrix}, ::Type{S}, dims::Dims{1}) where {S} = Vector{S}(dims...)

Base.similar(X::Union{pm_Vector, pm_Matrix}, ::Type{S}, dims::Dims{2}) where
    {S <: pm_VecOrMat_eltypes} = pm_Matrix{convert_to_pm_type(S)}(dims...)

Base.similar(X::Union{pm_Vector, pm_Matrix}, ::Type{S}, dims::Dims{2}) where {S} = Matrix{S}(dims...)

Base.similar(X::pm_SparseVector, ::Type{S}, dims::Dims{1}) where
    {S <: pm_VecOrMat_eltypes} = pm_SparseMatrix{convert_to_pm_type(S)}(dims...)

Base.similar(X::pm_SparseVector, ::Type{S}, dims::Dims{1}) where {S} = SparseVector{S}(dims...)

Base.BroadcastStyle(::Type{<:pm_Vector}) = Broadcast.ArrayStyle{pm_Vector}()
Base.BroadcastStyle(::Type{<:pm_Matrix}) = Broadcast.ArrayStyle{pm_Matrix}()
Base.BroadcastStyle(::Type{<:pm_SparseVector}) = Broadcast.ArrayStyle{pm_SparseVector}()

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{pm_Vector}},
    ::Type{ElType}) where ElType
    return pm_Vector{promote_to_pm_type(pm_Vector, ElType)}(axes(bc)...)
end

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{pm_Matrix}},
    ::Type{ElType}) where ElType
    return pm_Matrix{promote_to_pm_type(pm_Matrix, ElType)}(axes(bc)...)
end

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{pm_SparseVector}},
    ::Type{ElType}) where ElType
    return pm_SparseVector{promote_to_pm_type(pm_SparseVector, ElType)}(axes(bc)...)
end

SparseVecOrMat{T} =
Union{SparseVector{T},SparseArrays.AbstractSparseMatrix{T}}

function Base.Broadcast.combine_eltypes(f::Tf,
args::Tuple{SparseVecOrMat{ElType},N}) where {N, Tf, ElType<:Union{pm_Integer,
pm_Rational}}
    any(isempty, args) && return Any
    x = first.(args)
    return typeof(f(x...))
end

function Base.Broadcast.combine_eltypes(f::Tf,
args::Tuple{SparseVecOrMat{ElType}}) where {Tf, ElType<:Union{pm_Integer,
pm_Rational}}
    any(isempty, args) && return Any
    x = first.(args)
    return typeof(f(x...))
end

function Base.Broadcast.combine_eltypes(f::Tf,
args::Tuple{SparseVecOrMat{ElType}}) where {Tf<:Union{Type{<:pm_Integer},
Type{<:pm_Rational}}, ElType}
    any(isempty, args) && return Any
    x = first.(args)
    return typeof(f(x...))
end
