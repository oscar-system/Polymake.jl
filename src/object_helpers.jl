function complete_property(obj::pm_perl_Object, prefix::String)
   call_function(:complete_property, obj, prefix)
end

list_applications() = call_function(:list_applications)

list_big_objects(app::String) = call_function(:list_big_objects, app)

function pm_perl_OptionSet(iter)
    opt_set = pm_perl_OptionSet()
    for (key, value) in iter
        option_set_take(opt_set, string(key), value)
    end
    return opt_set
end

function _get_visual_string(x::Visual,function_symbol::Symbol)
    html_string=call_function(function_symbol,x.obj)
    # we guess that the julia kernel is named this way...
    kernel = "julia-$(VERSION.major).$(VERSION.minor)"
    html_string = replace(html_string,"kernelspecs/polymake/"=>"kernelspecs/$(kernel)/")
    return html_string
end

_get_visual_string_threejs(x::Visual) = _get_visual_string(x,:jupyter_visual_threejs)
_get_visual_string_svg(x::Visual) = _get_visual_string(x,:jupyter_visual_svg)

function c_arguments(args...; kwargs...)
    if isempty(kwargs)
        return Any[ args... ]
    else
        Any[ args..., pm_perl_OptionSet(kwargs) ]
    end
end
