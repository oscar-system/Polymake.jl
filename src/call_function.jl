function CxxWrap.StdVector{CxxWrap.StdString}(vec::AbstractVector{<:AbstractString})
    return CxxWrap.StdVector(convert.(CxxWrap.StdString, vec))
end

"""
    call_function([::Type{PropertyValue},] app::Symbol, func::Symbol, args...;
        template_parameters=String[], kwargs...)

Call a polymake function `func` from application `app` with given arguments `args`.
If `PropertyValue` is specified as the first argument no unwrapping is performed
and a raw `PropertyValue` is returned.
"""

function call_function(::Type{PropertyValue}, app::Symbol, func::Symbol, args...;
    template_parameters::Base.AbstractVector{<:AbstractString}=String[],
    calltype::Symbol=:scalar, kwargs...)
    fname = Meta.pm_name_qualified(app, func)
    cargs = Meta.polymake_arguments(args...; kwargs...)
    templ = CxxWrap.StdVector{CxxWrap.StdString}(template_parameters)
    return disable_sigint() do
        if calltype == :void
            internal_call_function_void(fname, templ, cargs)
            return nothing
        elseif calltype == :list
            return internal_call_function_list(fname, templ, cargs)
        else
            return internal_call_function(fname, templ, cargs)
        end
    end
end

function call_function(app::Symbol, func::Symbol, args...;
    template_parameters::Base.AbstractVector{<:AbstractString}=String[], kwargs...)
    return convert_from_property_value(
        call_function(PropertyValue, app, func, args...;
                      template_parameters=template_parameters, kwargs...)
        )
end

function call_function(::Type{Nothing}, app::Symbol, func::Symbol, args...;
    template_parameters::Base.AbstractVector{<:AbstractString}=String[], kwargs...)

    call_function(PropertyValue, app, func, args...;
                  template_parameters=template_parameters, calltype=:void, kwargs...)
    return nothing
end

"""
    call_method([::Type{PropertyValue},] obj::BigObject, func::Symbol, args...;
        kwargs...)

Call a polymake method `func` on the object `obj` with the given arguments `args`.
If `PropertyValue` is specified as the first argument no unwrapping is performed
and a raw `PropertyValue` is returned.
"""
function call_method(::Type{PropertyValue}, obj::BigObject, func::Symbol, args...;
    calltype::Symbol=:scalar, kwargs...)
    fname = string(func)
    cargs = Meta.polymake_arguments(args...; kwargs...)
    return disable_sigint() do
        if calltype == :void
            internal_call_method_void(fname, obj, cargs)
            return nothing
        elseif calltype == :list
            return internal_call_method_list(fname, obj, cargs)
        else
            return internal_call_method(fname, obj, cargs)
        end
    end
end

function call_method(obj::BigObject, func::Symbol, args...; kwargs...)
    return convert_from_property_value(
        call_method(PropertyValue, obj::BigObject, func::Symbol, args...;
                    kwargs...)
        )
end

function call_method(::Type{Nothing}, obj::BigObject, func::Symbol, args...; kwargs...)
    call_method(PropertyValue, obj::BigObject, func::Symbol, args...;
                calltype=:void, kwargs...)
    return nothing
end

"""
    @pm polymakeapp.function_name{Template, parameters}(args)

This macro can be used to
 * create `polymake` Big Objects (such as polytopes)
 * call `polymake` functions with specific template parameters.

The expression passed to the macro has to be:
 * a fully qualified name of a `polymake` object (i.e. starting with the
**lowercase** name of a polymake application), or
 * a function with template parameters enclosed in `{ ... }`.

# Examples
```jldoctest
julia> P = @pm polytope.Polytope{QuadraticExtension}(POINTS=[1 0 0; 0 1 0])
type: Polytope<QuadraticExtension<Rational>>

POINTS
1 0 0
0 1 0



julia> @pm common.convert_to{Float}(P)
type: Polytope<Float>

POINTS
1 0 0
0 1 0


CONE_AMBIENT_DIM
3



julia> @pm tropical.Polytope{Max}(POINTS=[1 0 0; 0 1 0])
type: Polytope<Max, Rational>

POINTS
0 -1 -1
0 1 0



```
!!! Note
    the expression in `@pm` macro is parsed syntactically, so it has to be a valid `julia` expression. However template parameters **need not** to be defined in `julia`, but must be valid names of `polymake` property types. Nested types (such as `{QuadraticExtension{Rational}}`) are allowed.
"""
macro pm(expr)
    module_name, polymake_func, templates, args, kwargs = try
        Meta.parse_function_call(expr)
    catch ex
        throw(ArgumentError("Can not parse the expression passed to @pm macro:\n$expr\n Only `@pm app.func{template, parameters}(KEY=val, ...)` syntax is recognized"))
        rethrow(ex)
    end
    polymake_app = Meta.get_polymake_app_name(module_name)

    # poor-mans Big Object constructor detection
    if isuppercase(string(polymake_func)[1])
        polymake_func_name =
            Meta.pm_name_qualified(polymake_app, polymake_func, templates)
        return :(
            bigobject($polymake_func_name, $(esc.(args)...); $(esc.(kwargs)...))
            )
    else # we presume it's a function
        app = "$polymake_app"
        func = "$polymake_func"
        return :(
            call_function(
                Symbol($app),
                Symbol($func),
                $(esc.(args)...);
                template_parameters=$templates,
                $(esc.(kwargs)...))
            )
    end
end
