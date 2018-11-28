export perlobj, call_function, call_method

import Base: convert, show

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
    Symbol("pm::Set<int,pm::operations::cmp>") => to_set_int32,
    Symbol("pm::Set<long,pm::operations::cmp>") => to_set_int64,
    Symbol("pm::Array<int>") => to_array_int32,
    Symbol("pm::Array<long>") => to_array_int64,
    Symbol("pm::Array<pm::Integer>") => to_array_Integer,
    Symbol("pm::Array<pm::Array<int>") => to_array_array_int32,
    Symbol("pm::Array<pm::Array<long>") => to_array_array_int64,
    Symbol("pm::Array<pm::Array<pm::Integer>") => to_array_array_Integer,
    Symbol("pm::Array<std::basic_string<char,std::char_traits<char>,std::allocator<char>>>") => to_array_string,
    Symbol("pm::Array<pm::Set<int,pm::operations::cmp>>") => to_array_set_int32,
    Symbol("pm::Array<pm::Matrix<pm::Integer>>") => to_array_matrix_Integer,
    Symbol("undefined") => x -> nothing,
)

Base.propertynames(p::Polymake.pm_perl_Object) = Symbol.(Polymake.complete_property(p, ""))

function Base.setproperty!(obj::pm_perl_Object, prop::Symbol, val)
    take(obj, string(prop), convert_to_pm(val))
end

function convert_from_property_value(obj::Polymake.pm_perl_PropertyValue)
    type_name = Polymake.typeinfo_string(obj)
    T = Symbol(replace(type_name," "=>""))
    if haskey(WrappedTypes, T)
        f = WrappedTypes[T]
        return f(obj)
    else
        @warn("The return value contains $(typeinfo_string(obj)) which has not been wrapped yet")
        return obj
    end
end

"""
    call_function(func::Symbol, args...; void=false, kwargs...)

Call a polymake function with the given `func` name and given arguments `args`.
If `void=true` the function is called in a void context. For example this is important for visualization.
"""
function call_function(func::Symbol, args...; void=false, kwargs...)
    fname = string(func)
    cargs = Any[args...]
    if isempty(kwargs)
        if void
            ret = internal_call_function_void(fname, cargs)
        else
            ret = internal_call_function(fname, cargs)
        end
    else
        if void
            ret = internal_call_function_void(fname, cargs, OptionSet(kwargs))
        else
            ret = internal_call_function(fname, cargs, OptionSet(kwargs))
        end
    end
    convert_from_property_value(ret)
end

"""
    call_method(obj::pm_perl_Object, func::Symbol, args...; kwargs...)

Call a polymake method on the object `obj` with the given `func` name and given arguments `args`.
If `void=true` the function is called in a void context. For example this is important for visualization.
"""
function call_method(obj, func::Symbol, args...; void=false, kwargs...)
    fname = string(func)
    cargs = Any[args...]
    if isempty(kwargs)
        if void
            ret = internal_call_method_void(fname, cargs)
        else
            ret = internal_call_method(fname, cargs)
        end
    else
        if void
            ret = internal_call_method_void(fname, obj, cargs, OptionSet(kwargs))
        else
            ret = internal_call_method(fname, obj, cargs, OptionSet(kwargs))
        end
    end
    convert_from_property_value(ret)
end

function give(obj::Polymake.pm_perl_Object, prop::String)
    return_obj = try
        internal_give(obj, prop)
    catch ex
        throw(PolymakeError(ex.msg))
    end
    return convert_from_property_value(return_obj)
end

Base.getproperty(obj::pm_perl_Object, prop::Symbol) = give(obj, string(prop))

Base.show(io::IO, obj::pm_perl_Object) = print(io, properties(obj))
function Base.show(io::IO, ::MIME"text/plain", obj::SmallObject)
    print(io, show_small_obj(obj))
end
# fallback for non-wrapped types
function Base.show(io::IO, ::MIME"text/plain", pv::pm_perl_PropertyValue)
    print(io, to_string(pv))
end
Base.show(io::IO, obj::SmallObject) = show(io, MIME("text/plain"), obj)
