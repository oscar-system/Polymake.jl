function pm_Matrix{T}(rows::UR, cols::UR) where {T <: pm_VecOrMat_eltypes, UR<:Base.AbstractUnitRange}
    return pm_Matrix{T}(length(rows), length(cols))
end

function pm_IncidenceMatrix{pm_NonSymmetric}(rows::UR, cols::UR) where {UR<:Base.AbstractUnitRange}
    return pm_IncidenceMatrix{pm_NonSymmetric}(length(rows), length(cols))
end

function pm_Vector{T}(len::UR) where {T <: pm_VecOrMat_eltypes, UR<:Base.AbstractUnitRange}
    return pm_Vector{T}(length(len))
end

function pm_SparseMatrix{T}(rows::UR, cols::UR) where {T <: pm_VecOrMat_eltypes, UR<:Base.AbstractUnitRange}
    return pm_SparseMatrix{T}(length(rows), length(cols))
end

Base.similar(X::Union{pm_Vector, pm_Matrix, pm_IncidenceMatrix}, ::Type{S}, dims::Dims{1}) where
    {S <: pm_VecOrMat_eltypes} = pm_Vector{convert_to_pm_type(S)}(dims...)

Base.similar(X::Union{pm_Vector, pm_Matrix, pm_IncidenceMatrix}, ::Type{S}, dims::Dims{1}) where {S} = Vector{S}(dims...)

Base.similar(X::Union{pm_Vector, pm_Matrix, pm_IncidenceMatrix}, ::Type{S}, dims::Dims{2}) where
    {S <: pm_VecOrMat_eltypes} = pm_Matrix{convert_to_pm_type(S)}(dims...)

Base.similar(X::Union{pm_Vector, pm_Matrix, pm_IncidenceMatrix}, ::Type{S}, dims::Dims{2}) where {S} = Matrix{S}(dims...)

Base.similar(X::pm_IncidenceMatrix, ::Type{Bool}, dims::Dims{1}) = BitArray{1}(undef, dims...)

Base.similar(X::pm_IncidenceMatrix, ::Type{Bool}, dims::Dims{2}) = pm_IncidenceMatrix{pm_NonSymmetric}(dims...)

Base.similar(X::pm_SparseMatrix, ::Type{S}, dims::Dims{2}) where
    {S <: pm_VecOrMat_eltypes} = pm_SparseMatrix{convert_to_pm_type(S)}(dims...)

Base.similar(X::pm_SparseMatrix, ::Type{S}, dims::Dims{2}) where {S} = SparseMatrixCSC{S}(dims...)

Base.BroadcastStyle(::Type{<:pm_Vector}) = Broadcast.ArrayStyle{pm_Vector}()
Base.BroadcastStyle(::Type{<:pm_Matrix}) = Broadcast.ArrayStyle{pm_Matrix}()
Base.BroadcastStyle(::Type{<:pm_IncidenceMatrix}) = Broadcast.ArrayStyle{pm_IncidenceMatrix{pm_NonSymmetric}}()
Base.BroadcastStyle(::Type{<:pm_SparseMatrix}) = Broadcast.ArrayStyle{pm_SparseMatrix}()

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{pm_Vector}},
    ::Type{ElType}) where ElType
    return pm_Vector{promote_to_pm_type(pm_Vector, ElType)}(axes(bc)...)
end

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{pm_Matrix}},
    ::Type{ElType}) where ElType
    return pm_Matrix{promote_to_pm_type(pm_Matrix, ElType)}(axes(bc)...)
end

#SparseArrays.HigherOrderFns.SparseMatStyle{pm_SparseMatrix}
function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{pm_SparseMatrix}},
    ::Type{ElType}) where ElType
    return pm_SparseMatrix{promote_to_pm_type(pm_SparseMatrix, ElType)}(axes(bc)...)
end

#Overloading some of julia's broadcast functions to allow correct typing when
#broadcasting julia sparse matrices with polymake element type output
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

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{T}},
    ::Type{Bool}) where {T<:pm_IncidenceMatrix}
    return pm_IncidenceMatrix{pm_NonSymmetric}(axes(bc)...)
end

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{T}},
    ::Type{ElType}) where {T<:pm_IncidenceMatrix, ElType}
    return pm_Matrix{promote_to_pm_type(pm_Matrix, ElType)}(axes(bc)...)
end
