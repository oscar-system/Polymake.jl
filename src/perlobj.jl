function bigobject(fname::String; kwargsdata...)
    obj = BigObject(BigObjectType(fname))
    setproperties!(obj; kwargsdata...)
    return obj
end

function bigobject(fname::String, other::BigObject; kwargsdata...)
    obj = BigObject(BigObjectType(fname), other; kwargsdata...)
    return obj
end

function bigobject(fname::String, name::String; kwargsdata...)
    obj = bigobject(fname; kwargsdata...)
    setname!(obj, name)
    return obj
end

# polymake can either just give a reference or do a full copy.
# but even that full copy will contain references to the same data
# objects in memory, but this is fine since most of them are immutable anyway.
# those that can be modified will use a CoW approach, i.e. they will be copied
# when they are modified.
Base.deepcopy_internal(o::BigObject, dict::IdDict) = internal_copy(o)
Base.copy(o::BigObject) = internal_copy(o)

function setproperties!(obj::BigObject; kwargsdata...)
    for (key, val) in kwargsdata
        setproperty!(obj, string(key), val)
    end
    return obj
end

Base.propertynames(p::BigObject) = Symbol.(Polymake.complete_property(p, ""))

function Base.setproperty!(obj::BigObject, prop::Symbol, val)
    @assert prop != :cpp_object
    return take(obj, string(prop), convert(PolymakeType, val))
end

function Base.setproperty!(obj::BigObject, prop::Symbol, val::Ptr{Cvoid})
    @assert prop == :cpp_object
    return setfield!(obj, prop, val)
end

Base.setproperty!(obj::BigObject, prop::String, val) = setproperty!(obj, Symbol(prop), val)

function give(obj::BigObject, prop::String)
    return_obj = try
        disable_sigint() do
            internal_give(obj, prop)
        end
    catch ex
        ex isa ErrorException && throw(PolymakeError(ex.msg))
        if (ex isa InterruptException)
            @warn """Interrupting polymake is not safe.
            SIGINT is disabled while waiting for polymake to finish its computations."""
        end
        rethrow(ex)
    end
    return convert_from_property_value(return_obj)
end

function Base.getproperty(obj::BigObject, prop::Symbol)
    if prop == :cpp_object
        return getfield(obj, :cpp_object)
    else
        return give(obj, string(prop))
    end
end

function complete_property(obj::BigObject, prefix::String)
   call_function(:common, :complete_property, obj, prefix)
end

function convert_from_property_value(obj::PropertyValue)
    type_name = typeinfo_string(obj,true)
    T = Symbol(replace(type_name," "=>""))
    if haskey(TypeConversionFunctions, T)
        f = TypeConversionFunctions[T]
        return f(obj)
    elseif startswith(type_name,"Visual::")
        return Visual(obj)
    else
        return obj
    end
end

function get_attachment(obj::BigObject, name::String)
   return convert_from_property_value(_get_attachment(obj,name))
end

function get_attachment(::Type{PropertyValue}, obj::BigObject, name::String)
   return _get_attachment(obj,name)
end

function OptionSet(iter)
    opt_set = OptionSet()
    for (key, value) in iter
        option_set_take(opt_set, string(key), value)
    end
    return opt_set
end
