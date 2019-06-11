#################### Unwrapping PropertyValues  ####################

convert(::Type{BigInt}, pv::pm_perl_PropertyValue) = convert(BigInt, to_pm_Integer(pv))

convert(::Type{<:Rational}, pv::pm_perl_PropertyValue) = convert(Rational{BigInt}, to_pm_Rational(pv))

convert(::Type{Matrix{Rational{BigInt}}}, pv::pm_perl_PropertyValue) =
    convert(Matrix{Rational{BigInt}}, to_matrix_rational(pv))

convert(::Type{Matrix{BigInt}}, matrix::pm_perl_PropertyValue) =
    convert(Matrix{BigInt}, to_matrix_int(pv))

convert(::Type{Vector{Rational{BigInt}}}, pv::pm_perl_PropertyValue) =
    convert(Matrix{Rational{BigInt}}, to_vector_rational(pv))

convert(::Type{Vector{BigInt}}, pv::pm_perl_PropertyValue) =
    convert(Matrix{BigInt}, to_vector_int(pv))

####################  Converting to polymake types  ####################

convert(::Type{pm_Vector}, vec::AbstractVector) = pm_Vector(vec)
convert(::Type{pm_Vector{T}}, vec::AbstractVector) where T = pm_Vector{T}(vec)

convert(::Type{pm_Matrix}, mat::AbstractMatrix) = pm_Matrix(mat)
convert(::Type{pm_Matrix{T}}, mat::AbstractMatrix) where T = pm_Matrix{T}(mat)

convert(::Type{pm_Array}, vec::AbstractVector) = pm_Array(vec)
convert(::Type{pm_Array{T}}, vec::AbstractVector) where T = pm_Array{T}(vec)

convert(::Type{pm_Set}, itr) = pm_Set(itr)
convert(::Type{pm_Set{T}}, itr) where T = pm_Set{T}(itr)
convert(::Type{pm_Set{T}}, as::AbstractSet) where T = pm_Set{T}(as)

# disambiguations:
convert(::Type{pm_Set}, as::AbstractSet) = pm_Set(as)
convert(::Type{pm_Set{T}}, s::pm_Set{T}) where T = s

################  Guessing the wrapped polymake type  ##################

convert_to_pm_type(T::Type{<:AbstractFloat}) = Float64
convert_to_pm_type(::Type{<:Union{Integer, pm_Integer}}) = pm_Integer
convert_to_pm_type(::Type{<:Union{Rational, pm_Rational}}) = pm_Rational
convert_to_pm_type(::Type{<:Union{AbstractVector, pm_Vector}}) = pm_Vector
convert_to_pm_type(::Type{<:Union{AbstractMatrix, pm_Matrix}}) = pm_Matrix
convert_to_pm_type(::Type{<:pm_Array}) = pm_Array
convert_to_pm_type(::Type{<:Union{AbstractSet, pm_Set}}) = pm_Set

convert_to_pm_type(::Type{AbstractVector{T}}) where T<:Union{Int32, Int64, String, AbstractSet{Int32}} = pm_Array{T}
# this catches all pm_Arrays of pm_Arrays we have right now:
convert_to_pm_type(::Type{AbstractVector{<:AbstractArray{T}}}) where T<:Union{Int32, Int64, pm_Integer} = pm_Array{pm_Array{T}}

###########  Converting to objects polymake understands  ##############

# By default we throw an error:
convert_to_pm(x) = throw(ArgumentError("Unrecognized argument type $(typeof(x)).\nYou need to convert to polymake compatible type first."))

# no convert for C++ compatible or wrapped polymake types:
convert_to_pm(x::Union{Int32, Int64, Float64}) = x
convert_to_pm(x::Union{pm_Vector, pm_Matrix, pm_Array, pm_Set}) = x
convert_to_pm(x::Union{pm_perl_Object, pm_perl_PropertyValue, pm_perl_OptionSet}) = x

convert_to_pm(x::T) where T <:Integer = convert(pm_Integer, x)
convert_to_pm(x::Rational{T}) where T <: Integer = convert(pm_Rational, x)

convert_to_pm(x::AbstractSet) = convert(pm_Set, x)

convert_to_pm(x::AbstractVector{<:Integer}) = convert(pm_Vector{pm_Integer},x)
convert_to_pm(x::AbstractVector{<:Rational}) = convert(pm_Vector{pm_Rational},x)
convert_to_pm(x::AbstractVector{<:pm_Rational}) = convert(pm_Vector{pm_Rational},x)

convert_to_pm(x::AbstractMatrix{<:AbstractFloat}) = convert(pm_Matrix{Float64},x)
convert_to_pm(x::AbstractMatrix{<:Integer}) = convert(pm_Matrix{pm_Integer},x)
convert_to_pm(x::AbstractMatrix{<:Rational}) = convert(pm_Matrix{pm_Rational},x)
convert_to_pm(x::AbstractMatrix{<:pm_Rational}) = convert(pm_Matrix{pm_Rational},x)

convert_to_pm(x::AbstractVector{<:AbstractVector{T}}) where T<:Union{Int32, Int64} = convert(pm_Array{pm_Array{T}},x)
convert_to_pm(x::AbstractVector{<:AbstractVector{<:Integer}}) = convert(pm_Array{pm_Array{pm_Integer}},x)

convert_to_pm(v::Visual) = v.obj

convert(::Type{pm_perl_OptionSet}, dict) = pm_perl_OptionSet(dict)
