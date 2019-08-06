####################  Converting to polymake types  ####################

for (pm_T, jl_T) in [
        (pm_Vector, AbstractVector),
        (pm_Matrix, AbstractMatrix),
        (pm_Array, AbstractVector),
        (pm_Set, AbstractSet)
        ]
    @eval begin
        convert(::Type{$pm_T}, itr::$jl_T) = $pm_T(itr)
        convert(::Type{$pm_T{T}}, itr::$jl_T) where T = $pm_T{T}(itr)
        convert(::Type{$pm_T}, itr::$pm_T) where T = itr
        convert(::Type{$pm_T{T}}, itr::$pm_T) where T = itr
    end
end

convert(::Type{pm_Set{T}}, itr::AbstractArray) where T = pm_Set{T}(itr)

###########  Converting to objects polymake understands  ###############

struct PolymakeType end

convert(::Type{PolymakeType}, x::T) where T = convert(convert_to_pm_type(T), x)
convert(::Type{PolymakeType}, v::Visual) = v.obj
convert(::Type{pm_perl_OptionSet}, dict) = pm_perl_OptionSet(dict)

####################  Guessing the polymake type  ######################

# By default we throw an error:
convert_to_pm_type(T::Type) = throw(ArgumentError("Unrecognized argument type: $T.\nYou need to convert to polymake compatible type first."))

convert_to_pm_type(::Type{T}) where T <: Union{Int32, Int64, Float64} = T
convert_to_pm_type(::Type{T}) where T <: Union{pm_perl_Object, pm_perl_PropertyValue, pm_perl_OptionSet} = T

convert_to_pm_type(::Type{<:AbstractFloat}) = Float64
convert_to_pm_type(::Type{<:AbstractString}) = String
convert_to_pm_type(::Type{<:Union{Integer, pm_Integer}}) = pm_Integer
convert_to_pm_type(::Type{<:Union{Rational, pm_Rational}}) = pm_Rational
convert_to_pm_type(::Type{<:Union{AbstractVector, pm_Vector}}) = pm_Vector
convert_to_pm_type(::Type{<:Union{AbstractMatrix, pm_Matrix}}) = pm_Matrix
convert_to_pm_type(::Type{<:pm_Array}) = pm_Array
convert_to_pm_type(::Type{<:Union{AbstractSet, pm_Set}}) = pm_Set

# specific converts for container types we wrap:
# pm_Set{Int32} is the natural type for polymake
convert_to_pm_type(::Type{<:Union{AbstractSet{T}, pm_Set{T}}}) where T<:Integer = pm_Set{Int32}
# convert_to_pm_type(::Type{<:Union{AbstractSet{Int64}, pm_Set{Int64}}}) = pm_Set{Int64}

for (pmT, jlT) in [(pm_Integer, Integer),
                   (pm_Rational, Union{Rational, pm_Rational})]
    @eval begin
        convert_to_pm_type(::Type{<:AbstractMatrix{T}}) where T<:$jlT = pm_Matrix{$pmT}
        convert_to_pm_type(::Type{<:AbstractVector{T}}) where T<:$jlT = pm_Vector{$pmT}
    end
end

convert_to_pm_type(::Type{<:AbstractMatrix{T}}) where T<:AbstractFloat = pm_Matrix{convert_to_pm_type(T)}

convert_to_pm_type(::Type{<:AbstractVector{T}}) where T<:Union{String, AbstractSet} = pm_Array{convert_to_pm_type(T)}

# this catches all pm_Arrays of pm_Arrays we have right now:
convert_to_pm_type(::Type{<:AbstractVector{<:AbstractArray{T}}}) where T = pm_Array{pm_Array{convert_to_pm_type(T)}}
