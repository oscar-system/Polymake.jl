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


convert(::Type{Array{Rational{BigInt},2}},matrix::Polymake.pm_perl_PropertyValue) = convert_matrix_rational(matrix)
convert(::Type{Array{Rational{BigInt},2}},matrix::Polymake.pm_Matrix{Polymake.pm_Rational}) = convert_matrix_rational(matrix)