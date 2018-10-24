export cube, cross, perlobj

import Base: convert, show

function cube(dim)
    return call_func_1args("cube",dim)
end

function cross(dim)
    return call_func_1args("cross",dim)
end

function rand_sphere(n,d)
    return call_func_2args("rand_sphere",n,d)
end

function upper_bound_theorem(n,d)
    return call_func_2args("upper_bound_theorem",n,d)
end

function perlobj(name::String, input_data::Dict{<:Union{String, Symbol},T}) where T
    polytope = pm_perl_Object(name)
    for value in input_data
        key = string(value[1])
        val = convert_to_pm(value[2])
        take(polytope,key,val)
    end
    return polytope
end

function perlobj(name::String, input_data::Pair{Symbol}...; kwargsdata...)
    obj = pm_perl_Object(name)
    for (key, val) in input_data
        setproperty!(obj, key, val)
    end
    for (key, val) in kwargsdata
        setproperty!(obj, key, val)
    end
    return obj
end

function typename_func(typename::String)
    if typename == "int"
        return to_int
    elseif typename == "double"
        return to_double
    elseif typename == "perl::Object"
        return to_perl_object
    elseif typename == "pm::Rational"
        return to_pm_Rational
    elseif typename == "pm::Integer"
        return to_pm_Integer
    elseif typename == "pm::Vector<pm::Integer>"
        return to_vector_int
    elseif typename == "pm::Vector<pm::Rational>"
        return to_vector_rational
    elseif typename == "pm::Matrix<pm::Integer>"
        return to_matrix_int
    elseif typename == "pm::Matrix<pm::Rational>"
        return to_matrix_rational
    elseif typename == "undefined"
        return x -> nothing
    end
    return identity
end

function Base.setproperty!(obj::pm_perl_Object, prop::Symbol, val)
    take(obj, string(prop), convert_to_pm(val))
end

function Base.getproperty(obj::pm_perl_Object, prop::Symbol)
    return_obj = internal_give(obj, string(prop))
    type_name = typeinfo_string(return_obj)
    return typename_func(type_name)(return_obj)
end

function convert_from_property_value(obj::Polymake.pm_perl_PropertyValue)
    type_name = Polymake.typeinfo_string(obj)
    return typename_func(type_name)(obj)
end

function give(obj::Polymake.pm_perl_Object,prop::String)
    return_obj = internal_give(obj,prop)
    return convert_from_property_value(return_obj)
end

function Base.show(io::IO, obj::pm_perl_Object)
    print(io, properties(obj))
end

function Base.show(io::IO, ::MIME"text/plain", obj::SmallObject)
    print(io, show_small_obj(obj))
end
Base.show(io::IO, obj::SmallObject) = show(io, MIME("text/plain"), obj)
