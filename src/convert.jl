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

function convert(::Type{pm_Matrix{pm_Integer}}, matrix::Array{S,2}) where S <:Integer
    rows,cols = size(matrix)
    pm_matrix = pm_Matrix{pm_Integer}(rows,cols)
    for i in 1:rows
        for j in 1:cols
            pm_matrix[i,j] = matrix[i,j]
        end
    end
    return pm_matrix
end


function convert(::Type{pm_Vector{pm_Integer}}, matrix::Array{S,1}) where S <:Integer
    (dim,) = size(matrix)
    pm_matrix = pm_Vector{pm_Integer}(dim)
    for i in 1:dim
        pm_matrix[i] = matrix[i]
    end
    return pm_matrix
end

function convert(::Type{pm_Vector{pm_Rational}}, matrix::Array{Rational{S},1}) where S <:Integer
    (dim,) = size(matrix)
    pm_matrix = pm_Vector{pm_Rational}(dim)
    for i in 1:dim
        pm_matrix[i] = matrix[i]
    end
    return pm_matrix
end

function convert(::Type{pm_Array{pm_Array{T}}}, vectors::Vector{<:Vector{<:Integer}}) where T
    n = length(vectors)
    pm_array = pm_Array{pm_Array{T}}(n)
    for (i, v_i) in enumerate(vectors)
        pm_array_i = pm_Array{T}(length(v_i))
        for j=1:length(v_i)
            pm_array_i[j] = T(v_i[j])
        end
        pm_array[i] = pm_array_i
    end
    return pm_array
end

# By default convert_to_pm is a no op
convert_to_pm(x) = x
convert_to_pm(x::T) where T <:Integer = convert(pm_Integer, x)
convert_to_pm(x::Rational{T}) where T <:Integer = convert(pm_Rational, x)
# We realize AbstractVectors/Matrices if they are not already Vector/Matrix or pm_*
convert_to_pm(x::AbstractVector) = convert_to_pm(Vector(x))
convert_to_pm(x::AbstractMatrix) = convert_to_pm(Matrix(x))
convert_to_pm(x::pm_Vector) = x
convert_to_pm(x::pm_Matrix) = x

convert_to_pm(x::Vector{<:Vector{T}}) where T<:Union{Int32, Int64} =  Base.convert(pm_Array{pm_Array{T}},x)
convert_to_pm(x::Vector{<:Vector{<:Integer}}) =  Base.convert(pm_Array{pm_Array{pm_Integer}},x)


function convert_matrix_rational(matrix::pm_Matrix{pm_Rational})
    nr_rows = rows(matrix)
    columns = cols(matrix)
    result = Array{Rational{BigInt},2}(undef,nr_rows,columns)
    for i = 1:nr_rows
        for j = 1:columns
            current_entry = matrix[i,j]
            result[i,j] = convert(Rational{BigInt},current_entry)
        end
    end
    return result
end

convert(::Type{Array{Rational{BigInt},2}},matrix::pm_Matrix{pm_Rational}) = convert_matrix_rational(matrix)

function convert_matrix_integer(matrix::pm_Matrix{pm_Integer})
    nr_rows = rows(matrix)
    columns = cols(matrix)
    result = Array{BigInt,2}(undef,nr_rows,columns)
    for i = 1:nr_rows
        for j = 1:columns
            current_entry = matrix[i,j]
            result[i,j] = convert(BigInt,current_entry)
        end
    end
    return result
end

convert(::Type{Array{BigInt,2}},matrix::pm_Matrix{pm_Rational}) = convert_matrix_integer(matrix)

function convert_vector_rational(vector::pm_Vector{pm_Rational})
    dim = length(vector)
    result = Array{Rational{BigInt},1}(undef,dim)
    for i = 1:dim
        current_entry = vector[i]
        result[i] = convert(Rational{BigInt},current_entry)
    end
    return result
end

convert(::Type{Array{Rational{BigInt},1}},vector::pm_Vector{pm_Rational}) = convert_vector_rational(vector)

function convert_vector_integer(vector::pm_Vector{pm_Integer})
    dim = length(vector)
    result = Array{BigInt,1}(undef,dim)
    for i = 1:dim
        current_entry = vector[i]
        result[i] = convert(BigInt,current_entry)
    end
    return result
end

convert(::Type{Array{BigInt,1}},vector::pm_Vector{pm_Integer}) = convert_vector_integer(vector)
convert_to_pm(x::Vector{<:Integer}) = convert(pm_Vector{pm_Integer},x)
convert_to_pm(x::Vector{<:Rational}) = convert(pm_Vector{pm_Rational},x)
convert_to_pm(x::Matrix{<:Integer}) = convert(pm_Matrix{pm_Integer},x)
convert_to_pm(x::Matrix{<:Rational}) = convert(pm_Matrix{pm_Rational},x)
convert_to_pm(x::Matrix{Float64}) = convert(pm_Matrix{Float64},x)

convert_to_pm(x::Vector{<:pm_Rational}) = convert(pm_Vector{pm_Rational}, x)
convert_to_pm(x::Matrix{<:pm_Rational}) = convert(pm_Matrix{pm_Rational}, x)

convert_to_pm(x::Vector{<:Vector{T}}) where T<:Union{Int32, Int64} = convert(pm_Array{pm_Array{T}},x)
convert_to_pm(x::Vector{<:Vector{<:Integer}}) = convert(pm_Array{pm_Array{pm_Integer}},x)


convert(::Type{pm_perl_OptionSet}, dict) = pm_perl_OptionSet(dict)
