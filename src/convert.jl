## BigInt

function convert(::Type{BigInt},int::CxxPM.pm_Integer)
    return deepcopy(unsafe_load(reinterpret(Ptr{BigInt},int.cpp_object)))
end

function convert(::Type{BigInt},int::CxxPM.pm_perl_PropertyValue)
    return to_pm_Integer(int)
end

function convert(::Type{CxxPM.pm_Integer},int::BigInt)
    return CxxPM.new_pm_Integer(int)
end

function convert(::Type{CxxPM.pm_Integer},int::T) where T <: Union{Int128,Int64,Int32}
    return CxxPM.pm_Integer(int)
end

function convert(::Type{CxxPM.pm_Set}, A::Vector{T}) where T<:Signed
    return CxxPM.new_set_int64(A)
end

function convert(::Type{Rational{BigInt}},rat::CxxPM.pm_Rational)
    num = CxxPM.numerator(rat)
    denom = CxxPM.denominator(rat)
    num = convert(BigInt,num)
    denom = convert(BigInt,denom)
    return Rational{BigInt}(num,denom)
end

function convert(::Type{CxxPM.pm_Rational},rat::Rational{BigInt})
    num = convert(pm_Integer,numerator(rat))
    denom = convert(pm_Integer,denominator(rat))
    return CxxPM.pm_Rational(num,denom)
end

function convert(::Type{CxxPM.pm_Rational},rat::Rational{T}) where T <: Union{Int128,Int64,Int32}
    num = convert(pm_Integer,numerator(rat))
    denom = convert(pm_Integer,denominator(rat))
    return CxxPM.pm_Rational(num,denom)
end

function convert(::Type{CxxPM.pm_Matrix{CxxPM.pm_Integer}}, matrix::Array{S,2}) where S <:Integer
    rows,cols = size(matrix)
    pm_matrix = CxxPM.pm_Matrix{CxxPM.pm_Integer}(rows,cols)
    for i in 1:rows
        for j in 1:cols
            converted = convert(CxxPM.pm_Integer,matrix[i,j])
            CxxPM.set_entry(pm_matrix, i-1, j-1, converted )
        end
    end
    return pm_matrix
end

function convert(::Type{CxxPM.pm_Matrix{CxxPM.pm_Rational}}, matrix::Array{Rational{S},2}) where S <:Integer
    rows,cols = size(matrix)
    pm_matrix = CxxPM.pm_Matrix{CxxPM.pm_Rational}(rows,cols)
    for i in 1:rows
        for j in 1:cols
            converted = convert(CxxPM.pm_Rational,matrix[i,j])
            CxxPM.set_entry(pm_matrix, i-1, j-1, converted )
        end
    end
    return pm_matrix
end

function convert(::Type{CxxPM.pm_Vector{CxxPM.pm_Integer}}, matrix::Array{S,1}) where S <:Integer
    (dim,) = size(matrix)
    pm_matrix = CxxPM.pm_Vector{CxxPM.pm_Integer}(dim)
    for i in 1:dim
        converted = convert(CxxPM.pm_Integer,matrix[i])
        CxxPM.set_entry(pm_matrix, i-1, converted )
    end
    return pm_matrix
end

function convert(::Type{CxxPM.pm_Vector{CxxPM.pm_Rational}}, matrix::Array{Rational{S},1}) where S <:Integer
    (dim,) = size(matrix)
    pm_matrix = CxxPM.pm_Vector{CxxPM.pm_Rational}(dim)
    for i in 1:dim
        converted = convert(CxxPM.pm_Rational,matrix[i])
        CxxPM.set_entry(pm_matrix, i-1, converted )
    end
    return pm_matrix
end

convert_to_pm(x::T) where T <:Integer = Base.convert(CxxPM.pm_Integer,x)

convert_to_pm(x::Rational{T}) where T <:Integer = Base.convert(CxxPM.pm_Rational,x)

convert_to_pm(x::Array{T,1}) where T <:Integer = Base.convert(CxxPM.pm_Vector{CxxPM.pm_Integer},x)

convert_to_pm(x::Array{Rational{T},1}) where T <:Integer = Base.convert(CxxPM.pm_Vector{CxxPM.pm_Rational},x)

convert_to_pm(x::Array{T,2}) where T <:Integer = Base.convert(CxxPM.pm_Matrix{CxxPM.pm_Integer},x)

convert_to_pm(x::Array{Rational{T},2}) where T <:Integer = Base.convert(CxxPM.pm_Matrix{CxxPM.pm_Rational},x)

function convert_matrix_rational(pmmatrix::CxxPM.pm_perl_PropertyValue)
    return convert_matrix_rational(CxxPM.to_matrix_rational(pmmatrix))
end

function convert_matrix_rational(matrix::CxxPM.pm_Matrix{CxxPM.pm_Rational})
    rows = CxxPM.rows(matrix)
    columns = CxxPM.cols(matrix)
    result = Array{Rational{BigInt},2}(rows,columns)
    for i = 1:rows
        for j = 1:columns
            current_entry = matrix(i-1,j-1)
            result[i,j] = convert(Rational{BigInt},current_entry)
        end
    end
    return result
end

convert(::Type{Array{Rational{BigInt},2}},matrix::CxxPM.pm_perl_PropertyValue) = convert_matrix_rational(matrix)
convert(::Type{Array{Rational{BigInt},2}},matrix::CxxPM.pm_Matrix{CxxPM.pm_Rational}) = convert_matrix_rational(matrix)

function convert_matrix_integer(pmmatrix::CxxPM.pm_perl_PropertyValue)
    return convert_matrix_integer(CxxPM.to_matrix_int(pmmatrix))
end

function convert_matrix_integer(matrix::CxxPM.pm_Matrix{CxxPM.pm_Integer})
    rows = CxxPM.rows(matrix)
    columns = CxxPM.cols(matrix)
    result = Array{BigInt,2}(rows,columns)
    for i = 1:rows
        for j = 1:columns
            current_entry = matrix(i-1,j-1)
            result[i,j] = convert(BigInt,current_entry)
        end
    end
    return result
end

convert(::Type{Array{BigInt,2}},matrix::CxxPM.pm_perl_PropertyValue) = convert_matrix_integer(matrix)
convert(::Type{Array{BigInt,2}},matrix::CxxPM.pm_Matrix{CxxPM.pm_Rational}) = convert_matrix_integer(matrix)

function convert_vector_rational(pmvector::CxxPM.pm_perl_PropertyValue)
    return convert_vector_rational(CxxPM.to_vector_rational(pmvector))
end

function convert_vector_rational(vector::CxxPM.pm_Vector{CxxPM.pm_Rational})
    dim = CxxPM.dim(vector)
    result = Array{Rational{BigInt},1}(dim)
    for i = 1:dim
        current_entry = vector(i-1)
        result[i] = convert(Rational{BigInt},current_entry)
    end
    return result
end

convert(::Type{Array{Rational{BigInt},1}},vector::CxxPM.pm_perl_PropertyValue) = convert_vector_rational(vector)
convert(::Type{Array{Rational{BigInt},1}},vector::CxxPM.pm_Vector{CxxPM.pm_Rational}) = convert_vector_rational(vector)

function convert_vector_integer(pmvector::CxxPM.pm_perl_PropertyValue)
    return convert_vector_integer(CxxPM.to_vector_int(pmvector))
end

function convert_vector_integer(vector::CxxPM.pm_Vector{CxxPM.pm_Integer})
    dim = CxxPM.dim(vector)
    result = Array{BigInt,1}(dim)
    for i = 1:dim
        current_entry = vector(i-1)
        result[i] = convert(BigInt,current_entry)
    end
    return result
end

convert(::Type{Array{BigInt,1}},vector::CxxPM.pm_perl_PropertyValue) = convert_vector_integer(vector)
convert(::Type{Array{BigInt,1}},vector::CxxPM.pm_Vector{CxxPM.pm_Integer}) = convert_vector_integer(vector)
