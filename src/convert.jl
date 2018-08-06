## BigInt

function convert(::Type{BigInt},int::Polymake.pm_Integer)
    return deepcopy(unsafe_load(reinterpret(Ptr{BigInt},int.cpp_object)))
end

function convert(::Type{BigInt},int::Polymake.pm_perl_PropertyValue)
    return get_pm_integer(int)
end

function convert(::Type{Polymake.pm_Integer},int::BigInt)
    return Polymake.new_pm_Integer(int)
end

function convert(::Type{Polymake.pm_Integer},int::T) where T <: Union{Int128,Int64,Int32}
    return Polymake.pm_Integer(int)
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

function convert_matrix_rational(pmmatrix::Polymake.pm_perl_PropertyValue)
    return convert_matrix_rational(Polymake.to_matrix_rational(pmmatrix))
end

function convert_matrix_rational(matrix::Polymake.pm_Matrix{Polymake.pm_Rational})
    rows = Polymake.get_matrix_rows(matrix)
    columns = Polymake.get_matrix_columns(matrix)
    result = Array{Rational{BigInt},2}(rows,columns)
    for i = 1:rows
        for j = 1:columns
            current_entry = Polymake.get_matrix_entry_rational(matrix,i-1,j-1)
            result[i,j] = convert(Rational{BigInt},current_entry)
        end
    end
    return result
end

convert(::Type{Array{Rational{BigInt},2}},matrix::Polymake.pm_perl_PropertyValue) = convert_matrix_rational(matrix)
convert(::Type{Array{Rational{BigInt},2}},matrix::Polymake.pm_Matrix{Polymake.pm_Rational}) = convert_matrix_rational(matrix)