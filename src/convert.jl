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

#################### Converting to polymake types  ####################

convert(::Type{pm_Vector}, vec::AbstractVector) = pm_Vector(vec)
convert(::Type{pm_Vector{T}}, vec::AbstractVector) where T = pm_Vector{T}(vec)

convert(::Type{pm_Matrix}, mat::AbstractMatrix) = pm_Matrix(mat)
convert(::Type{pm_Matrix{T}}, mat::AbstractMatrix) where T = pm_Matrix{T}(mat)

convert(::Type{pm_Array}, vec::AbstractVector) = pm_Array(vec)
convert(::Type{pm_Array{T}}, vec::AbstractVector) where T = pm_Array{T}(vec)

#################### Guessing the polymake type  ####################

convert_to_pm_type(::Type{<:Union{Integer, pm_Integer}}) = pm_Integer
convert_to_pm_type(::Type{<:Union{Rational, pm_Rational}}) = pm_Rational
convert_to_pm_type(::Type{Vector{T}}) where T<:Union{Int32, Int64} = pm_Array{T}
convert_to_pm_type(::Type{<:Union{Set, pm_Set}}) = pm_Set
convert_to_pm_type(::Type{<:Union{Vector, pm_Vector}}) = pm_Matrix
convert_to_pm_type(::Type{<:Union{Matrix, pm_Matrix}}) = pm_Matrix
convert_to_pm_type(::Type{<:pm_Array}) = pm_Array

# By default convert_to_pm is a no op
convert_to_pm(x) = x
# no convert for Cxx compatible types
convert_to_pm(x::T) where T <:Union{Int32, Int64, Float64} = x

convert_to_pm(x::T) where T <:Integer = convert(pm_Integer, x)
convert_to_pm(x::Rational{T}) where T <:Integer = convert(pm_Rational, x)
# We realize AbstractVectors/Matrices if they are not already Vector/Matrix or pm_*
convert_to_pm(x::AbstractVector) = convert_to_pm(Vector(x))
convert_to_pm(x::AbstractMatrix) = convert_to_pm(Matrix(x))
convert_to_pm(x::pm_Vector) = x
convert_to_pm(x::pm_Matrix) = x

convert_to_pm(x::Vector{<:Integer}) = convert(pm_Vector{pm_Integer},x)
convert_to_pm(x::Vector{<:Rational}) = convert(pm_Vector{pm_Rational},x)
convert_to_pm(x::Matrix{<:Integer}) = convert(pm_Matrix{pm_Integer},x)
convert_to_pm(x::Matrix{<:Rational}) = convert(pm_Matrix{pm_Rational},x)
convert_to_pm(x::Matrix{Float64}) = convert(pm_Matrix{Float64},x)

convert_to_pm(x::Vector{<:pm_Rational}) = convert(pm_Vector{pm_Rational}, x)
convert_to_pm(x::Matrix{<:pm_Rational}) = convert(pm_Matrix{pm_Rational}, x)

convert_to_pm(x::Vector{<:Vector{T}}) where T<:Union{Int32, Int64} = convert(pm_Array{pm_Array{T}},x)
convert_to_pm(x::Vector{<:Vector{<:Integer}}) = convert(pm_Array{pm_Array{pm_Integer}},x)

convert_to_pm(v::Visual) = v.obj

convert(::Type{pm_perl_OptionSet}, dict) = pm_perl_OptionSet(dict)
