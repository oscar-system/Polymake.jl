import Base: convert, show

function cube(dim)
    return CxxPM.call_func_1args("cube",dim)
end

function cross(dim)
    return CxxPM.call_func_1args("cross",dim)
end

function rand_sphere(n,d)
    return CxxPM.call_func_2args("rand_sphere",n,d)
end

function upper_bound_theorem(n,d)
    return CxxPM.call_func_2args("upper_bound_theorem",n,d)
end

function perlobj(name::String,input_data::Dict{String,T}) where T
    polytope = CxxPM.pm_perl_Object(name)
    for value in input_data
        key = value[1]
        val = convert_to_pm(value[2])
        CxxPM.take(polytope,key,val)
    end
    return polytope
end

function typename_func(typename::String)
    if typename == "int"
        return CxxPM.to_int
    elseif typename == "double"
        return CxxPM.to_double
    elseif typename == "perl::Object"
        return CxxPM.to_perl_object
    elseif typename == "pm::Rational"
        return CxxPM.to_pm_Rational
    elseif typename == "pm::Integer"
        return CxxPM.to_pm_Integer
    elseif typename == "pm::Vector<pm::Integer>"
        return CxxPM.to_vector_int
    elseif typename == "pm::Vector<pm::Rational>"
        return CxxPM.to_vector_rational
    elseif typename == "pm::Matrix<pm::Integer>"
        return CxxPM.to_matrix_int
    elseif typename == "pm::Matrix<pm::Rational>"
        return CxxPM.to_matrix_rational
    elseif typename == "undefined"
        return x -> nothing
    end
    return identity
end

function give(obj::CxxPM.pm_perl_Object,prop::String)
    return_obj = CxxPM.give(obj,prop)
    type_name = CxxPM.typeinfo_string(return_obj)
    return typename_func(type_name)(return_obj)
end

function Base.show(io::IO,obj::CxxPM.pm_perl_Object)
    print(io, CxxPM.properties(obj))
end

function Base.show(io::IO,obj::SmallObject)
    print(io, CxxPM.show_small_obj(obj))
end
