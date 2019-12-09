@inline function pm_Matrix{T}(rows::UR, cols::UR) where {T <: pm_VecOrMat_eltypes, UR<:Base.AbstractUnitRange}
    return pm_Matrix{T}(length(rows), length(cols))
end

Base.similar(X::Union{pm_Vector, pm_Matrix}, ::Type{S}, dims::Dims{1}) where
    {S <: pm_VecOrMat_eltypes} = pm_Vector{convert_to_pm_type(S)}(dims...)

Base.similar(X::Union{pm_Vector, pm_Matrix}, ::Type{S}, dims::Dims{1}) where {S} = Vector{S}(dims...)

Base.similar(X::Union{pm_Vector, pm_Matrix}, ::Type{S}, dims::Dims{2}) where
    {S <: pm_VecOrMat_eltypes} = pm_Matrix{convert_to_pm_type(S)}(dims...)

Base.similar(X::Union{pm_Vector, pm_Matrix}, ::Type{S}, dims::Dims{2}) where {S} = Matrix{S}(dims...)

Base.BroadcastStyle(::Type{<:pm_Vector}) = Broadcast.ArrayStyle{pm_Vector}()
Base.BroadcastStyle(::Type{<:pm_Matrix}) = Broadcast.ArrayStyle{pm_Matrix}()

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{pm_Vector}},
    ::Type{ElType}) where ElType
    return pm_Vector{promote_to_pm_type(pm_Vector, ElType)}(axes(bc)...)
end

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{pm_Matrix}},
    ::Type{ElType}) where ElType
    return pm_Matrix{promote_to_pm_type(pm_Vector, ElType)}(axes(bc)...)
end
