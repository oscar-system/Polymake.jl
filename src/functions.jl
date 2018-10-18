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

function perlobj(name::String,input_data::Dict{String,T}) where T
    polytope = Polymake.pm_perl_Object(name)
    for value in input_data
        key = value[1]
        val = convert_to_pm(value[2])
        Polymake.take(polytope,key,val)
    end
    return polytope
end

function typename_func(typename::String)
    if typename == "int"
        return Polymake.to_int
    elseif typename == "double"
        return Polymake.to_double
    elseif typename == "perl::Object"
        return Polymake.to_perl_object
    elseif typename == "pm::Rational"
        return Polymake.to_pm_Rational
    elseif typename == "pm::Integer"
        return Polymake.to_pm_Integer
    elseif typename == "pm::Vector<pm::Integer>"
        return Polymake.to_vector_int
    elseif typename == "pm::Vector<pm::Rational>"
        return Polymake.to_vector_rational
    elseif typename == "pm::Matrix<pm::Integer>"
        return Polymake.to_matrix_int
    elseif typename == "pm::Matrix<pm::Rational>"
        return Polymake.to_matrix_rational
    elseif typename == "undefined"
        return x -> nothing
    end
    return identity
end

Base.getproperty(obj::Polymake.pm_perl_Object, prop::Symbol) = give(obj, string(prop))

function give(obj::Polymake.pm_perl_Object,prop::String)
    return_obj = Polymake.give(obj,prop)
    type_name = Polymake.typeinfo_string(return_obj)
    return typename_func(type_name)(return_obj)
end

function Base.show(io::IO, obj::Polymake.pm_perl_Object)
    print(io, Polymake.properties(obj))
end

function Base.show(io::IO, ::MIME"text/plain", obj::SmallObject)
    print(io, Polymake.show_small_obj(obj))
end
Base.show(io::IO, obj::SmallObject) = show(io, MIME("text/plain"), obj)
