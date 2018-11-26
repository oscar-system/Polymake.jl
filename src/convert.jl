## BigInt

function convert(::Type{BigInt},int::pm_Integer)
    return deepcopy(unsafe_load(reinterpret(Ptr{BigInt},int.cpp_object)))
end

function convert(::Type{BigInt},int::pm_perl_PropertyValue)
    return to_pm_Integer(int)
end

function convert(::Type{Rational{BigInt}},rat::pm_Rational)
    num = numerator(rat)
    denom = denominator(rat)
    num = convert(BigInt,num)
    denom = convert(BigInt,denom)
    return Rational{BigInt}(num,denom)
end

function convert(::Type{pm_Rational},rat::Rational{BigInt})
    num = convert(pm_Integer,numerator(rat))
    denom = convert(pm_Integer,denominator(rat))
    return pm_Rational(num,denom)
end

function convert(::Type{pm_Rational},rat::Rational{T}) where T <: Union{Int128,Int64,Int32}
    num = convert(pm_Integer,numerator(rat))
    denom = convert(pm_Integer,denominator(rat))
    return pm_Rational(num,denom)
end

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

function convert(::Type{pm_Matrix{pm_Rational}}, matrix::Array{Rational{S},2}) where S <:Integer
    rows,cols = size(matrix)
    pm_matrix = pm_Matrix{pm_Rational}(rows,cols)
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

convert_to_pm(x::String) = x
convert_to_pm(x::T) where T <:Integer = Base.convert(pm_Integer,x)
convert_to_pm(x::Rational{T}) where T <:Integer = Base.convert(pm_Rational,x)
convert_to_pm(x::Array{T,1}) where T <:Integer = Base.convert(pm_Vector{pm_Integer},x)
convert_to_pm(x::Array{Rational{T},1}) where T <:Integer = Base.convert(pm_Vector{pm_Rational},x)
convert_to_pm(x::Array{T,2}) where T <:Integer = Base.convert(pm_Matrix{pm_Integer},x)
convert_to_pm(x::Array{Rational{T},2}) where T <:Integer = Base.convert(pm_Matrix{pm_Rational},x)
convert_to_pm(x::Vector{<:Vector{T}}) where T<:Union{Int32, Int64} =  Base.convert(pm_Array{pm_Array{T}},x)
convert_to_pm(x::Vector{<:Vector{<:Integer}}) =  Base.convert(pm_Array{pm_Array{pm_Integer}},x)
for (_, T) in C_TYPES
    @eval convert_to_pm(x::$T) = x
end


function convert_matrix_rational(pmmatrix::pm_perl_PropertyValue)
    return convert_matrix_rational(to_matrix_rational(pmmatrix))
end

function convert_matrix_rational(matrix::pm_Matrix{pm_Rational})
    rows = rows(matrix)
    columns = cols(matrix)
    result = Array{Rational{BigInt},2}(rows,columns)
    for i = 1:rows
        for j = 1:columns
            current_entry = matrix(i-1,j-1)
            result[i,j] = convert(Rational{BigInt},current_entry)
        end
    end
    return result
end

convert(::Type{Array{Rational{BigInt},2}},matrix::pm_perl_PropertyValue) = convert_matrix_rational(matrix)
convert(::Type{Array{Rational{BigInt},2}},matrix::pm_Matrix{pm_Rational}) = convert_matrix_rational(matrix)

function convert_matrix_integer(pmmatrix::pm_perl_PropertyValue)
    return convert_matrix_integer(to_matrix_int(pmmatrix))
end

function convert_matrix_integer(matrix::pm_Matrix{pm_Integer})
    rows = rows(matrix)
    columns = cols(matrix)
    result = Array{BigInt,2}(rows,columns)
    for i = 1:rows
        for j = 1:columns
            current_entry = matrix(i-1,j-1)
            result[i,j] = convert(BigInt,current_entry)
        end
    end
    return result
end

convert(::Type{Array{BigInt,2}},matrix::pm_perl_PropertyValue) = convert_matrix_integer(matrix)
convert(::Type{Array{BigInt,2}},matrix::pm_Matrix{pm_Rational}) = convert_matrix_integer(matrix)

function convert_vector_rational(pmvector::pm_perl_PropertyValue)
    return convert_vector_rational(to_vector_rational(pmvector))
end

function convert_vector_rational(vector::pm_Vector{pm_Rational})
    dim = dim(vector)
    result = Array{Rational{BigInt},1}(dim)
    for i = 1:dim
        current_entry = vector(i-1)
        result[i] = convert(Rational{BigInt},current_entry)
    end
    return result
end

convert(::Type{Array{Rational{BigInt},1}},vector::pm_perl_PropertyValue) = convert_vector_rational(vector)
convert(::Type{Array{Rational{BigInt},1}},vector::pm_Vector{pm_Rational}) = convert_vector_rational(vector)

function convert_vector_integer(pmvector::pm_perl_PropertyValue)
    return convert_vector_integer(to_vector_int(pmvector))
end

function convert_vector_integer(vector::pm_Vector{pm_Integer})
    dim = dim(vector)
    result = Array{BigInt,1}(dim)
    for i = 1:dim
        current_entry = vector(i-1)
        result[i] = convert(BigInt,current_entry)
    end
    return result
end

convert(::Type{Array{BigInt,1}},vector::pm_perl_PropertyValue) = convert_vector_integer(vector)
convert(::Type{Array{BigInt,1}},vector::pm_Vector{pm_Integer}) = convert_vector_integer(vector)
