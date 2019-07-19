function complete_property(obj::pm_perl_Object, prefix::String)
   call_function(:common, :complete_property, obj, prefix)
end

list_applications() = call_function(:common, :list_applications)

list_big_objects(app::Symbol) = call_function(:common, :list_big_objects, string(app))

function pm_perl_OptionSet(iter)
    opt_set = pm_perl_OptionSet()
    for (key, value) in iter
        option_set_take(opt_set, string(key), value)
    end
    return opt_set
end

function _get_visual_string(x::Visual,function_symbol::Symbol)
    html_string=call_function(:common, function_symbol, x.obj)
    # we guess that the julia kernel is named this way...
    kernel = "julia-$(VERSION.major).$(VERSION.minor)"
    html_string = replace(html_string,"kernelspecs/polymake/"=>"kernelspecs/$(kernel)/")
    return html_string
end

_get_visual_string_threejs(x::Visual) = _get_visual_string(x,:jupyter_visual_threejs)
_get_visual_string_svg(x::Visual) = _get_visual_string(x,:jupyter_visual_svg)

function polymake_arguments(args...; kwargs...)
    if isempty(kwargs)
        return Any[ convert.(PolymakeType, args)... ]
    else
        Any[ convert.(PolymakeType, args)..., pm_perl_OptionSet(kwargs) ]
    end
end

function get_docs(input::String; full::Bool=true, html::Bool=false)
    pos = UInt(max(length(input)-1, 0))
    return Polymake.shell_context_help(input, pos, full, html)
end

function cite(;format=:bibtex)
    cite_str = split(shell_execute("""help "core/citation";""")[2], "\n\n")[2]
    if format == :bibtex
        return cite_str
    else
        throw("The only supported citation format is :bibtex")
    end
end
