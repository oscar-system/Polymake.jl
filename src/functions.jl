import Base: convert, show

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

function convert(::Type{BigInt},xx::Polymake.pm_perl_PropertyValue)
    return get_pm_integer(xx)
end

function convert(::Type{Rational{BigInt}},xx::Polymake.pm_perl_PropertyValue)
    num = Polymake.get_numerator(xx)
    denom = Polymake.get_denominator(xx)
    num = convert(BigInt,num)
    denom = convert(BigInt,denom)
    return Rational{BigInt}(num,denom)
end

function convert_matrix(matrix)
    matrix = Polymake.to_matrix(matrix)
    rows = Polymake.get_matrix_rows(matrix)
    columns = Polymake.get_matrix_columns(matrix)
    result = Array{Rational{BigInt},2}
end
