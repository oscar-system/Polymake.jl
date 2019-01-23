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

function _get_visual_string(x::pm_perl_Object)
    mktempdir() do path
        complete_path = joinpath(path,"test.poly")
        save_perl_object(x,complete_path)
        shell_execute("\$visual_temp = load(\"$complete_path\");")
    end
    string_tuple = shell_execute("\$visual_temp->VISUAL;")
    html_string = string_tuple[2]
    html_string = replace(html_string,".@@HTML@@"=>"")
    html_string = replace(html_string,".@@ENDHTML@@"=>"")
    # we guess that the julia kernel is named this way...
    kernel = "julia-$(VERSION.major).$(VERSION.minor)"
    html_string = replace(html_string,"kernelspecs/polymake/"=>"kernelspecs/$(kernel)/")
    return html_string
end

function visual(x::pm_perl_Object)
    if isdefined(Main, :IJulia) && Main.IJulia.inited
        return HTML(_get_visual_string(x))
    else
        call_method(x,:VISUAL;void=true)
    end
end
