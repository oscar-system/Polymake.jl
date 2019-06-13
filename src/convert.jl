####################  Converting to polymake types  ####################

convert(::Type{pm_Vector}, vec::AbstractVector) = pm_Vector(vec)
convert(::Type{pm_Vector{T}}, vec::AbstractVector) where T = pm_Vector{T}(vec)
convert(::Type{pm_Vector{T}}, vec::pm_Vector) where T = vec

convert(::Type{pm_Matrix}, mat::AbstractMatrix) = pm_Matrix(mat)
convert(::Type{pm_Matrix{T}}, mat::AbstractMatrix) where T = pm_Matrix{T}(mat)
convert(::Type{pm_Matrix{T}}, mat::pm_Matrix) where T = mat

convert(::Type{pm_Array}, vec::AbstractVector) = pm_Array(vec)
convert(::Type{pm_Array{T}}, vec::AbstractVector) where T = pm_Array{T}(vec)

convert(::Type{pm_Set}, as::AbstractSet) = pm_Set(as)
convert(::Type{pm_Set{T}}, as::AbstractSet) where T = pm_Set{T}(as)

# disambiguations:
convert(::Type{pm_Set}, itr) = pm_Set(itr)
convert(::Type{pm_Set{T}}, itr) where T = pm_Set{T}(itr)

convert(::Type{pm_perl_OptionSet}, dict) = pm_perl_OptionSet(dict)

###########  Converting to objects polymake understands  ###############

convert_to_pm(x::T) where T = convert(convert_to_pm_type(T), x)
convert_to_pm(v::Visual) = v.obj

# disambiguations:
convert(::Type{pm_Set}, as::AbstractSet) = pm_Set(as)
convert(::Type{pm_Set{T}}, s::pm_Set{T}) where T = s

################  Guessing the wrapped polymake type  ##################

# By default we throw an error:
convert_to_pm_type(T::Type) = throw(ArgumentError("Unrecognized argument type: $T.\nYou need to convert to polymake compatible type first."))

convert_to_pm_type(::Type{T}) where T <: Union{Int32, Int64, Float64} = T
convert_to_pm_type(::Type{T}) where T <: Union{pm_perl_Object, pm_perl_PropertyValue, pm_perl_OptionSet} = T

convert_to_pm_type(::Type{<:AbstractFloat}) = Float64
convert_to_pm_type(::Type{<:Union{Integer, pm_Integer}}) = pm_Integer
convert_to_pm_type(::Type{<:Union{Rational, pm_Rational}}) = pm_Rational
convert_to_pm_type(::Type{<:Union{AbstractVector, pm_Vector}}) = pm_Vector
convert_to_pm_type(::Type{<:Union{AbstractMatrix, pm_Matrix}}) = pm_Matrix
convert_to_pm_type(::Type{<:pm_Array}) = pm_Array
convert_to_pm_type(::Type{<:Union{AbstractSet, pm_Set}}) = pm_Set

convert_to_pm_type(::Type{AbstractVector{T}}) where T<:Union{Int32, Int64, String, AbstractSet{Int32}} = pm_Array{T}
convert_to_pm_type(::Type{AbstractVector{T}}) where T = pm_Vector{convert_to_pm_type(T)}
convert_to_pm_type(::Type{AbstractMatrix{T}}) where T = pm_Matrix{convert_to_pm_type(T)}

# this catches all pm_Arrays of pm_Arrays we have right now:
convert_to_pm_type(::Type{AbstractVector{<:AbstractArray{T}}}) where T<:Union{Int32, Int64, pm_Integer} = pm_Array{pm_Array{T}}
