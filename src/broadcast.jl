function Matrix{T}(rows::UR, cols::UR) where {T <: VecOrMat_eltypes, UR<:Base.AbstractUnitRange}
    return Matrix{T}(length(rows), length(cols))
end

function IncidenceMatrix{NonSymmetric}(rows::UR, cols::UR) where {UR<:Base.AbstractUnitRange}
    return IncidenceMatrix{NonSymmetric}(length(rows), length(cols))
end

function Vector{T}(len::UR) where {T <: VecOrMat_eltypes, UR<:Base.AbstractUnitRange}
    return Vector{T}(length(len))
end

function SparseMatrix{T}(rows::UR, cols::UR) where {T <: VecOrMat_eltypes, UR<:Base.AbstractUnitRange}
    return SparseMatrix{T}(length(rows), length(cols))
end

function SparseVector{T}(len::UR) where {T <: VecOrMat_eltypes, UR<:Base.AbstractUnitRange}
    return SparseVector{T}(length(len))
end

Base.similar(X::Union{Vector, Matrix, IncidenceMatrix}, ::Type{S}, dims::Dims{1}) where
    {S <: VecOrMat_eltypes} = Vector{convert_to_pm_type(S)}(dims...)

Base.similar(X::Union{Vector, Matrix, IncidenceMatrix}, ::Type{S}, dims::Dims{1}) where {S} = Base.Vector{S}(dims...)

Base.similar(X::Union{Vector, Matrix, IncidenceMatrix}, ::Type{S}, dims::Dims{2}) where
    {S <: VecOrMat_eltypes} = Matrix{convert_to_pm_type(S)}(dims...)

Base.similar(X::Union{Vector, Matrix, IncidenceMatrix}, ::Type{S}, dims::Dims{2}) where {S} = Base.Matrix{S}(dims...)

Base.similar(X::IncidenceMatrix, ::Type{Bool}, dims::Dims{1}) = BitArray{1}(undef, dims...)

Base.similar(X::IncidenceMatrix, ::Type{Bool}, dims::Dims{2}) = IncidenceMatrix{NonSymmetric}(dims...)

Base.similar(X::Union{SparseVector, SparseMatrix}, ::Type{S}, dims::Dims{1}) where
    {S <: VecOrMat_eltypes} = SparseVector{convert_to_pm_type(S)}(dims...)

Base.similar(X::Union{SparseVector, SparseMatrix}, ::Type{S}, dims::Dims{1}) where {S} = SparseArrays.SparseVector{S}(dims...)

Base.similar(X::Union{SparseVector, SparseMatrix}, ::Type{S}, dims::Dims{2}) where
    {S <: VecOrMat_eltypes} = SparseMatrix{convert_to_pm_type(S)}(dims...)

Base.similar(X::Union{SparseVector, SparseMatrix}, ::Type{S}, dims::Dims{2}) where {S} = SparseArrays.SparseMatrixCSC{S}(dims...)

Base.BroadcastStyle(::Type{<:Vector}) = Broadcast.ArrayStyle{Vector}()
Base.BroadcastStyle(::Type{<:Matrix}) = Broadcast.ArrayStyle{Matrix}()
Base.BroadcastStyle(::Type{<:SparseVector}) = Broadcast.ArrayStyle{SparseMatrix}()
Base.BroadcastStyle(::Type{<:SparseMatrix}) = Broadcast.ArrayStyle{SparseMatrix}()
Base.BroadcastStyle(::Type{<:IncidenceMatrix}) = Broadcast.ArrayStyle{IncidenceMatrix{NonSymmetric}}()

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{Vector}},
    ::Type{ElType}) where ElType
    return Vector{promote_to_pm_type(Vector, ElType)}(axes(bc)...)
end

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{Matrix}},
    ::Type{ElType}) where ElType
    return Matrix{promote_to_pm_type(Matrix, ElType)}(axes(bc)...)
end

#SparseArrays.HigherOrderFns.SparseMatStyle{SparseMatrix}
function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{SparseMatrix}},
    ::Type{ElType}) where ElType
    return SparseMatrix{promote_to_pm_type(SparseMatrix, ElType)}(axes(bc)...)
end

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{SparseVector}},
    ::Type{ElType}) where ElType
    return SparseVector{promote_to_pm_type(SparseVector, ElType)}(axes(bc)...)
end

#Overloading some of julia's broadcast functions to allow correct typing when
#broadcasting julia sparse matrices with polymake element type output
SparseVecOrMat{T} =
Union{SparseVector{T},SparseArrays.AbstractSparseMatrix{T}}

function Base.Broadcast.combine_eltypes(f::Tf,
args::Tuple{SparseVecOrMat{ElType},N}) where {N, Tf, ElType<:Union{Integer,
Rational}}
    any(isempty, args) && return Any
    x = first.(args)
    return typeof(f(x...))
end

function Base.Broadcast.combine_eltypes(f::Tf,
args::Tuple{SparseVecOrMat{ElType}}) where {Tf, ElType<:Union{Integer,
Rational}}
    any(isempty, args) && return Any
    x = first.(args)
    return typeof(f(x...))
end

function Base.Broadcast.combine_eltypes(f::Tf,
args::Tuple{SparseVecOrMat{ElType}}) where {Tf<:Union{Type{<:Integer},
Type{<:Rational}}, ElType}
    any(isempty, args) && return Any
    x = first.(args)
    return typeof(f(x...))
end

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{T}},
    ::Type{Bool}) where {T<:IncidenceMatrix}
    return IncidenceMatrix{NonSymmetric}(axes(bc)...)
end

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{T}},
    ::Type{ElType}) where {T<:IncidenceMatrix, ElType}
    return Matrix{promote_to_pm_type(Matrix, ElType)}(axes(bc)...)
end
