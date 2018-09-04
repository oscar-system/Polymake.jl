## BigInt

function convert(::Type{BigInt},int::Polymake.pm_Integer)
    return deepcopy(unsafe_load(reinterpret(Ptr{BigInt},int.cpp_object)))
end

function convert(::Type{BigInt},int::Polymake.pm_perl_PropertyValue)
    return to_pm_Integer(int)
end

function convert(::Type{Polymake.pm_Integer},int::BigInt)
    return Polymake.new_pm_Integer(int)
end

function convert(::Type{Polymake.pm_Integer},int::T) where T <: Union{Int128,Int64,Int32}
    return Polymake.pm_Integer(int)
end

function convert(::Type{Polymake.pm_Set}, A::Vector{Int64})
    return Polymake.new_set_int64(A)
end

function convert(::Type{Polymake.pm_Set}, A::Vector{Int32})
    return Polymake.new_set_int32(A)
end

function convert(::Type{Vector}, set::Polymake.pm_Set{T}) where T<:Integer
    return convert(Vector{T}, set)
end

function convert(::Type{Vector{Int32}}, set::Polymake.pm_Set{Int32})
    A = Vector{Int32}(size(set))
    Polymake.fill_jlarray_int32_from_set32(A, set)
    return A
end

function convert(::Type{Vector{Int64}}, set::Polymake.pm_Set{Int64})
    A = Vector{Int64}(size(set))
    Polymake.fill_jlarray_int64_from_set64(A, set)
    return A
end

function convert(::Type{Vector{I}}, set::Polymake.pm_Set{J}) where {I,J<:Integer}
    return I.(convert(Vector{J}, set))
end

function convert(::Type{Rational{BigInt}},rat::Polymake.pm_Rational)
    num = Polymake.numerator(rat)
    denom = Polymake.denominator(rat)
    num = convert(BigInt,num)
    denom = convert(BigInt,denom)
    return Rational{BigInt}(num,denom)
end

function convert(::Type{Polymake.pm_Rational},rat::Rational{BigInt})
    num = convert(pm_Integer,numerator(rat))
    denom = convert(pm_Integer,denominator(rat))
    return Polymake.pm_Rational(num,denom)
end

function convert(::Type{Polymake.pm_Rational},rat::Rational{T}) where T <: Union{Int128,Int64,Int32}
    num = convert(pm_Integer,numerator(rat))
    denom = convert(pm_Integer,denominator(rat))
    return Polymake.pm_Rational(num,denom)
end

function convert(::Type{Polymake.pm_Matrix{Polymake.pm_Integer}}, matrix::Array{S,2}) where S <:Integer
    rows,cols = size(matrix)
    pm_matrix = Polymake.pm_Matrix{Polymake.pm_Integer}(rows,cols)
    for i in 1:rows
        for j in 1:cols
            converted = convert(Polymake.pm_Integer,matrix[i,j])
            Polymake.set_entry(pm_matrix, i-1, j-1, converted )
        end
    end
    return pm_matrix
end

function convert(::Type{Polymake.pm_Matrix{Polymake.pm_Rational}}, matrix::Array{Rational{S},2}) where S <:Integer
    rows,cols = size(matrix)
    pm_matrix = Polymake.pm_Matrix{Polymake.pm_Rational}(rows,cols)
    for i in 1:rows
        for j in 1:cols
            converted = convert(Polymake.pm_Rational,matrix[i,j])
            Polymake.set_entry(pm_matrix, i-1, j-1, converted )
        end
    end
    return pm_matrix
end

function convert(::Type{Polymake.pm_Vector{Polymake.pm_Integer}}, matrix::Array{S,1}) where S <:Integer
    (dim,) = size(matrix)
    pm_matrix = Polymake.pm_Vector{Polymake.pm_Integer}(dim)
    for i in 1:dim
        converted = convert(Polymake.pm_Integer,matrix[i])
        Polymake.set_entry(pm_matrix, i-1, converted )
    end
    return pm_matrix
end

function convert(::Type{Polymake.pm_Vector{Polymake.pm_Rational}}, matrix::Array{Rational{S},1}) where S <:Integer
    (dim,) = size(matrix)
    pm_matrix = Polymake.pm_Vector{Polymake.pm_Rational}(dim)
    for i in 1:dim
        converted = convert(Polymake.pm_Rational,matrix[i])
        Polymake.set_entry(pm_matrix, i-1, converted )
    end
    return pm_matrix
end

convert_to_pm(x::T) where T <:Integer = Base.convert(Polymake.pm_Integer,x)

convert_to_pm(x::Rational{T}) where T <:Integer = Base.convert(Polymake.pm_Rational,x)

convert_to_pm(x::Array{T,1}) where T <:Integer = Base.convert(Polymake.pm_Vector{Polymake.pm_Integer},x)

convert_to_pm(x::Array{Rational{T},1}) where T <:Integer = Base.convert(Polymake.pm_Vector{Polymake.pm_Rational},x)

convert_to_pm(x::Array{T,2}) where T <:Integer = Base.convert(Polymake.pm_Matrix{Polymake.pm_Integer},x)

convert_to_pm(x::Array{Rational{T},2}) where T <:Integer = Base.convert(Polymake.pm_Matrix{Polymake.pm_Rational},x)

function convert_matrix_rational(pmmatrix::Polymake.pm_perl_PropertyValue)
    return convert_matrix_rational(Polymake.to_matrix_rational(pmmatrix))
end

function convert_matrix_rational(matrix::Polymake.pm_Matrix{Polymake.pm_Rational})
    rows = Polymake.rows(matrix)
    columns = Polymake.cols(matrix)
    result = Array{Rational{BigInt},2}(rows,columns)
    for i = 1:rows
        for j = 1:columns
            current_entry = matrix(i-1,j-1)
            result[i,j] = convert(Rational{BigInt},current_entry)
        end
    end
    return result
end

convert(::Type{Array{Rational{BigInt},2}},matrix::Polymake.pm_perl_PropertyValue) = convert_matrix_rational(matrix)
convert(::Type{Array{Rational{BigInt},2}},matrix::Polymake.pm_Matrix{Polymake.pm_Rational}) = convert_matrix_rational(matrix)

function convert_matrix_integer(pmmatrix::Polymake.pm_perl_PropertyValue)
    return convert_matrix_integer(Polymake.to_matrix_int(pmmatrix))
end

function convert_matrix_integer(matrix::Polymake.pm_Matrix{Polymake.pm_Integer})
    rows = Polymake.rows(matrix)
    columns = Polymake.cols(matrix)
    result = Array{BigInt,2}(rows,columns)
    for i = 1:rows
        for j = 1:columns
            current_entry = matrix(i-1,j-1)
            result[i,j] = convert(BigInt,current_entry)
        end
    end
    return result
end

convert(::Type{Array{BigInt,2}},matrix::Polymake.pm_perl_PropertyValue) = convert_matrix_integer(matrix)
convert(::Type{Array{BigInt,2}},matrix::Polymake.pm_Matrix{Polymake.pm_Rational}) = convert_matrix_integer(matrix)

function convert_vector_rational(pmvector::Polymake.pm_perl_PropertyValue)
    return convert_vector_rational(Polymake.to_vector_rational(pmvector))
end

function convert_vector_rational(vector::Polymake.pm_Vector{Polymake.pm_Rational})
    dim = Polymake.dim(vector)
    result = Array{Rational{BigInt},1}(dim)
    for i = 1:dim
        current_entry = vector(i-1)
        result[i] = convert(Rational{BigInt},current_entry)
    end
    return result
end

convert(::Type{Array{Rational{BigInt},1}},vector::Polymake.pm_perl_PropertyValue) = convert_vector_rational(vector)
convert(::Type{Array{Rational{BigInt},1}},vector::Polymake.pm_Vector{Polymake.pm_Rational}) = convert_vector_rational(vector)

function convert_vector_integer(pmvector::Polymake.pm_perl_PropertyValue)
    return convert_vector_integer(Polymake.to_vector_int(pmvector))
end

function convert_vector_integer(vector::Polymake.pm_Vector{Polymake.pm_Integer})
    dim = Polymake.dim(vector)
    result = Array{BigInt,1}(dim)
    for i = 1:dim
        current_entry = vector(i-1)
        result[i] = convert(BigInt,current_entry)
    end
    return result
end

convert(::Type{Array{BigInt,1}},vector::Polymake.pm_perl_PropertyValue) = convert_vector_integer(vector)
convert(::Type{Array{BigInt,1}},vector::Polymake.pm_Vector{Polymake.pm_Integer}) = convert_vector_integer(vector)