import Base: convert
####################  Converting to polymake types  ####################

for (pm_T, jl_T) in [
        (Vector, AbstractVector),
        (Matrix, AbstractMatrix),
        (Array, AbstractVector),
        (Set, AbstractSet),
        (SparseMatrix, AbstractMatrix)
        ]
    @eval begin
        convert(::Type{$pm_T}, itr::$jl_T) = $pm_T(itr)
        convert(::Type{$pm_T{T}}, itr::$jl_T) where T = $pm_T{T}(itr)
        convert(::Type{$pm_T}, itr::$pm_T) = itr
        convert(::Type{$pm_T{T}}, itr::$pm_T) where T = itr
    end
end

convert(::Type{Set{T}}, itr::AbstractArray) where T = Set{T}(itr)

###########  Converting to objects polymake understands  ###############

struct PolymakeType end

convert(::Type{PolymakeType}, x::T) where T = convert(convert_to_pm_type(T), x)
convert(::Type{PolymakeType}, v::Visual) = v.obj
convert(::Type{OptionSet}, dict) = OptionSet(dict)

####################  Guessing the polymake type  ######################

# By default we throw an error:
convert_to_pm_type(T::Type) = throw(ArgumentError("Unrecognized argument type: $T.\nYou need to convert to polymake compatible type first."))

convert_to_pm_type(::Type{T}) where T <: Union{Int64, Float64} = T
convert_to_pm_type(::Type{T}) where T <: Union{BigObject, PropertyValue, OptionSet} = T

convert_to_pm_type(::Type{Int32}) = Int64
convert_to_pm_type(::Type{<:AbstractFloat}) = Float64
convert_to_pm_type(::Type{<:AbstractString}) = String
convert_to_pm_type(::Type{<:Union{Base.Integer, Integer}}) = Integer
convert_to_pm_type(::Type{<:Union{Base.Rational, Rational}}) = Rational
convert_to_pm_type(::Type{<:Union{AbstractVector, Vector}}) = Vector
convert_to_pm_type(::Type{<:Union{AbstractMatrix, Matrix}}) = Matrix
convert_to_pm_type(::Type{<:Union{AbstractSparseMatrix, SparseMatrix}}) = SparseMatrix
convert_to_pm_type(::Type{<:Array}) = Array
# convert_to_pm_type(::Type{<:Union{AbstractSet, Set}}) = Set

# specific converts for container types we wrap:
convert_to_pm_type(::Type{<:Set{<:Base.Integer}}) = Set{Int64}
convert_to_pm_type(::Type{<:Base.AbstractSet{<:Base.Integer}}) = Set{Int64}

for (pmT, jlT) in [(Integer, Base.Integer),
                   (Rational, Union{Base.Rational, Rational})]
    @eval begin
        convert_to_pm_type(::Type{<:AbstractMatrix{T}}) where T<:$jlT = Matrix{$pmT}
        convert_to_pm_type(::Type{<:AbstractVector{T}}) where T<:$jlT = Vector{$pmT}
    end
end

convert_to_pm_type(::Type{<:AbstractMatrix{T}}) where T<:AbstractFloat = Matrix{convert_to_pm_type(T)}

convert_to_pm_type(::Type{<:AbstractVector{T}}) where T<:Union{String, AbstractSet} = Array{convert_to_pm_type(T)}

# this catches all Arrays of Arrays we have right now:
convert_to_pm_type(::Type{<:AbstractVector{<:AbstractArray{T}}}) where T = Array{Array{convert_to_pm_type(T)}}

# 2-argument version: the first is the container type
promote_to_pm_type(::Type, S::Type) = convert_to_pm_type(S) #catch all
function promote_to_pm_type(::Type{<:Union{Vector, Matrix, SparseMatrix}}, S::Type{<:Base.Integer})
    promote_type(S, Int64) == Int64 && return Int64
    return Integer
end
