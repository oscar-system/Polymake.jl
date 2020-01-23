function pm_Matrix{T}(rows::UR, cols::UR) where {T <: pm_VecOrMat_eltypes, UR<:Base.AbstractUnitRange}
    return pm_Matrix{T}(length(rows), length(cols))
end

function pm_IncidenceMatrix{pm_NonSymmetric}(rows::UR, cols::UR) where {UR<:Base.AbstractUnitRange}
    return pm_IncidenceMatrix{pm_NonSymmetric}(length(rows), length(cols))
end

Base.similar(X::Union{pm_Vector, pm_Matrix, pm_IncidenceMatrix}, ::Type{S}, dims::Dims{1}) where
    {S <: pm_VecOrMat_eltypes} = pm_Vector{convert_to_pm_type(S)}(dims...)

Base.similar(X::Union{pm_Vector, pm_Matrix, pm_IncidenceMatrix}, ::Type{S}, dims::Dims{1}) where {S} = Vector{S}(dims...)

Base.similar(X::Union{pm_Vector, pm_Matrix, pm_IncidenceMatrix}, ::Type{S}, dims::Dims{2}) where
    {S <: pm_VecOrMat_eltypes} = pm_Matrix{convert_to_pm_type(S)}(dims...)

Base.similar(X::Union{pm_Vector, pm_Matrix, pm_IncidenceMatrix}, ::Type{S}, dims::Dims{2}) where {S} = Matrix{S}(dims...)

Base.similar(X::pm_IncidenceMatrix, ::Type{Bool}, dims::Dims{1}) = BitArray{1}(undef, dims...)

Base.similar(X::pm_IncidenceMatrix, ::Type{Bool}, dims::Dims{2}) = pm_IncidenceMatrix{pm_NonSymmetric}(dims...)

Base.BroadcastStyle(::Type{<:pm_Vector}) = Broadcast.ArrayStyle{pm_Vector}()
Base.BroadcastStyle(::Type{<:pm_Matrix}) = Broadcast.ArrayStyle{pm_Matrix}()
Base.BroadcastStyle(::Type{<:pm_IncidenceMatrix}) = Broadcast.ArrayStyle{pm_IncidenceMatrix{pm_NonSymmetric}}()

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{pm_Vector}},
    ::Type{ElType}) where ElType
    return pm_Vector{promote_to_pm_type(pm_Vector, ElType)}(axes(bc)...)
end

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{pm_Matrix}},
    ::Type{ElType}) where ElType
    return pm_Matrix{promote_to_pm_type(pm_Vector, ElType)}(axes(bc)...)
end

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{T}},
    ::Type{Bool}) where {T<:pm_IncidenceMatrix}
    return pm_IncidenceMatrix{pm_NonSymmetric}(axes(bc)...)
end

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{T}},
    ::Type{ElType}) where {T<:pm_IncidenceMatrix, ElType}
    return pm_Matrix{promote_to_pm_type(pm_Matrix, ElType)}(axes(bc)...)
end
