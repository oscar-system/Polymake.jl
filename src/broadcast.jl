function Vector{T}(len::UR) where {T, UR<:Base.AbstractUnitRange}
    return Vector{T}(undef, length(len))
end

function Matrix{T}(rows::UR, cols::UR) where {T , UR<:Base.AbstractUnitRange}
    return Matrix{T}(undef, length(rows), length(cols))
end

function IncidenceMatrix{NonSymmetric}(rows::UR, cols::UR) where
    UR<:Base.AbstractUnitRange
    return IncidenceMatrix{NonSymmetric}(undef, length(rows), length(cols))
end

function spzeros(::Type{T}, rows::UR, cols::UR) where {T , UR<:Base.AbstractUnitRange}
    return Polymake.spzeros(T, length(rows), length(cols))
end

function spzeros(::Type{T}, len::UR) where {T, UR<:Base.AbstractUnitRange}
    return Polymake.spzeros(T, length(len))
end

for (dim, T) in ((1, :Vector), (2, :Matrix))
    @eval begin
        function Base.similar(X::Union{Vector, Matrix, IncidenceMatrix},
            ::Type{S}, dims::Dims{$dim}) where S <: VecOrMat_eltypes
            return Polymake.$T{convert_to_pm_type(S)}(undef, dims...)
        end
        function Base.similar(X::Union{Vector, Matrix, IncidenceMatrix},
            ::Type{S}, dims::Dims{$dim}) where S
            return Base.$T{S}(undef, dims...)
        end
    end
end

for dim in (1, 2)
    @eval begin
        function Base.similar(X::Union{SparseVector, SparseMatrix},
            ::Type{S}, dims::Dims{$dim}) where S <: VecOrMat_eltypes
            return Polymake.spzeros(convert_to_pm_type(S), dims...)
        end
        function Base.similar(X::Union{SparseVector, SparseMatrix},
            ::Type{S}, dims::Dims{$dim}) where S
            return SparseArrays.spzeros(S, dims...)
        end
    end
end

function Base.similar(X::Union{IncidenceMatrix, SparseVector},
    ::Type{<:Union{Bool, CxxWrap.CxxBool}}, dims::Dims{1})
    return spzeros(Bool, dims...)
end

function Base.similar(X::Union{IncidenceMatrix, SparseVector},
    ::Type{<:Union{Bool, CxxWrap.CxxBool}}, dims::Dims{2})
    return IncidenceMatrix{NonSymmetric}(undef, dims...)
end

Base.BroadcastStyle(::Type{<:Vector}) = Broadcast.ArrayStyle{Vector}()
Base.BroadcastStyle(::Type{<:Matrix}) = Broadcast.ArrayStyle{Matrix}()
Base.BroadcastStyle(::Type{<:SparseVector}) = Broadcast.ArrayStyle{SparseVector}()
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
    return Polymake.spzeros(promote_to_pm_type(SparseMatrix, ElType), axes(bc)...)
end

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{SparseVector}},
    ::Type{ElType}) where ElType
    return Polymake.spzeros(promote_to_pm_type(SparseVector, ElType), axes(bc)...)
end

#Overloading some of julia's broadcast functions to allow correct typing when
#broadcasting julia sparse matrices with polymake element type output
SparseVecOrMat{T} =
Union{SparseArrays.SparseVector{T},SparseArrays.AbstractSparseMatrix{T}}

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
