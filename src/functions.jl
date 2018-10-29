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
    perl_obj = pm_perl_Object(name)
    for value in input_data
        key = string(value[1])
        val = convert_to_pm(value[2])
        take(perl_obj,key,val)
    end
    return perl_obj
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

const WrappedTypes = Dict(
    Symbol("int") => to_int,
    Symbol("double") => to_double, 
    Symbol("perl::Object") => to_perl_object,
    Symbol("pm::Integer") => to_pm_Integer,
    Symbol("pm::Rational") => to_pm_Rational,
    Symbol("pm::Vector<pm::Integer>") => to_vector_Integer,
    Symbol("pm::Vector<pm::Rational>") => to_vector_Rational,
    Symbol("pm::Matrix<pm::Integer>") => to_matrix_Integer,
    Symbol("pm::Matrix<pm::Rational>") => to_matrix_Rational,
    Symbol("pm::Set<int, pm::operations::cmp>") => to_set_int32,
    Symbol("pm::Set<long, pm::operations::cmp>") => to_set_int64,
    Symbol("pm::Array<int>") => to_array_int32,
    Symbol("pm::Array<long>") => to_array_int64,
    Symbol("pm::Array<std::basic_string<char, std::char_traits<char>, std::allocator<char> >>") => to_array_string,
    Symbol("pm::Array<pm::Set<int, pm::operations::cmp>>") => to_array_set_int32,
    Symbol("pm::Array<pm::Matrix<pm::Integer>>") => to_array_matrix_Integer, 
    Symbol("undefined") => x -> nothing,
)

function Base.setproperty!(obj::pm_perl_Object, prop::Symbol, val)
    take(obj, string(prop), convert_to_pm(val))
end

function convert_from_property_value(obj::Polymake.pm_perl_PropertyValue)
    type_name = Polymake.typeinfo_string(obj)
    f = get(WrappedTypes, Symbol(type_name), identity)
    return f(obj)
end

function Base.getproperty(obj::pm_perl_Object, prop::Symbol)
    return_obj = internal_give(obj, string(prop))
    return convert_from_property_value(return_obj)
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
