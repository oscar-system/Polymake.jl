import Base: convert, show

const give = Polymake.give

function cube(dim)
    return Polymake.call_func_1args("cube",dim)
end

function cross(dim)
    return Polymake.call_func_1args("cross",dim)
end

function rand_sphere(n,d)
    return Polymake.call_func_2args("rand_sphere",n,d)
end

function upper_bound_theorem(n,d)
    return Polymake.call_func_2args("upper_bound_theorem",n,d)
end

function get_pm_integer(int)
    return deepcopy(unsafe_load(reinterpret(Ptr{BigInt},Polymake.to_bigint(int).cpp_object)))
end

function convert(::Type{BigInt},int::Polymake.pm_Integer)
    return deepcopy(unsafe_load(reinterpret(Ptr{BigInt},int.cpp_object)))
end

function convert(::Type{BigInt},int::Polymake.pm_perl_PropertyValue)
    return get_pm_integer(int)
end

function convert(::Type{Rational{BigInt}},rat::Polymake.pm_Rational)
    num = Polymake.numerator(rat)
    denom = Polymake.denominator(rat)
    num = convert(BigInt,num)
    denom = convert(BigInt,denom)
    return Rational{BigInt}(num,denom)
end

function convert_matrix_rational(pmmatrix::Polymake.pm_perl_PropertyValue)
    return convert_matrix_rational(Polymake.to_matrix_rational(pmmatrix))
end

function convert_matrix_rational(matrix::Polymake.pm_Matrix_pm_Rational)
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
convert(::Type{Array{Rational{BigInt},2}},matrix::Polymake.pm_Matrix_pm_Rational) = convert_matrix_rational(matrix)