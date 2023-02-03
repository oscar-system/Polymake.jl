export visual

function Base.show(io::IO,::MIME"text/plain", obj::BigObject)
    strs = strip.(split(String(properties(obj)), "\n\n"))
    summary = strs[1]
    props = filter!(!isempty, strs[2:end])
    println(io, summary)

    upperbound = 10
    for p in props
        if occursin('\n', p)
            (key, val) = split(p, '\n'; limit=2)
        else
            key, val = p, ""
        end

        if key in ("POINTS", "INEQUALITIES", "FACETS", "VERTICES")
            println(io, '\n', key)
            try
                Base.print_matrix(io, getproperty(obj, Symbol(key)), "  ")
                println(io, "")
            catch
                println(io, "\t", val)
            end
        else
            if count(r"\n", val) > upperbound
                val = join(
                        split(val, "\n"; limit=upperbound+1)[1:upperbound],
                    "\n") * "\n…"
            end
            println(io, '\n', key)
            println(io, "\t", replace(val, "\n"=>"\n\t"))
        end
    end
end

function Base.show(io::IO, ::MIME"text/html", obj::BigObject)

    strs = strip.(split(String(properties(obj)), "\n\n"))
    summary = split(strs[1], "\n")
    attributes = filter!(!isempty, strs[2:end])

    props = Base.Vector{String}(undef, length(attributes))

    for (i, a) in enumerate(attributes)
        if occursin('\n', a)
            (key, val) = split(a, '\n'; limit=2)
        else
            key, val = a, ""
        end

        props[i] = """
            <details>
                <summary style='display:list-item;'>$key</summary>
                <pre>$val</pre>
            </details>
         """
    end

    preamble = ("<dt>$t</dt><dd>$d</dd>" for (t,d) in split.(summary, ":"; limit=2))

    print(io, "<dl> $(join(preamble, "\n")) </dl>", join(props, "\n"))
end

function Base.show(io::IO, ::MIME"text/plain", obj::SmallObject)
    print(io, show_small_obj(obj))
end
function Base.show(io::IOContext, ::MIME"text/plain", obj::SmallObject)
    print(io, show_small_obj(obj))
end
# fallback for non-wrapped types
function Base.show(io::IO, ::MIME"text/plain", pv::PropertyValue)
    type_info = typeinfo_string(pv, true)
    println(io, "PropertyValue wrapping $type_info")
    if  type_info != "undefined" && !startswith(type_info,"Visual::")
        print(io, call_function(:common, :safe_to_string, pv))
    end
end

function Base.show(io::IO, ::MIME"text/plain", a::Array{BigObject})
    print(io, "Array{BigObject} of size ",length(a))
end
Base.show(io::IO, obj::SmallObject) = show(io, MIME("text/plain"), obj)
Base.show(io::IOContext, obj::SmallObject) = show(io, MIME("text/plain"), obj)

struct Visual
    obj::Polymake.PropertyValue
end

function Base.show(io::IO, v::Visual)
    # IJulia renders all possible mimes, so frontend can decide on
    # the way to display the output.
    # This `if` keeps the browser from opening a new tab
    if !(isdefined(Main, :IJulia) && Main.IJulia.inited)
        show(io,MIME("text/plain"),v.obj)
    end
end

function _get_visual_string(x::Visual,function_symbol::Symbol)
    html_string=call_function(:common, function_symbol, x.obj)
    # we guess that the julia kernel is named this way...
    kernel = "julia-$(VERSION.major).$(VERSION.minor)"
    html_string = replace(html_string,"kernelspecs/polymake/"=>"kernelspecs/$(kernel)/polymake/")
    return html_string
end

_get_visual_string_threejs(x::Visual) = _get_visual_string(x,:jupyter_visual_threejs)
_get_visual_string_svg(x::Visual) = _get_visual_string(x,:jupyter_visual_svg)

function Base.show(io::IO,::MIME"text/html",v::Visual)
    print(io,_get_visual_string_threejs(v))
end

function Base.show(io::IO,::MIME"image/svg+xml",v::Visual)
    print(io,_get_visual_string_svg(v))
end

display_svg(obj::BigObject) = display_svg(visual(Visual, obj))
display_svg(v::Visual) = display(MIME"image/svg+xml"(), v)

"""
    visual(obj::BigObject; options...)

Visualize the given big object.

## Example

```
c = polytope.cube(3)
visual(c)
```
"""
function visual(obj::BigObject; kwargs...)
   # TODO change to call_method(Nothing,...)
   # once the void-call exceptions are fixed in polymake_jll
   vis = call_method(obj, :VISUAL; kwargs...)
   call_function(:common, :safe_to_string, vis.obj)
   return nothing
end

visual(::Type{Visual}, obj::BigObject; kwargs...) = call_method(obj, :VISUAL; kwargs...)


function configure_wslview(; force=true)
   (out, err) = shell_execute("script(\"$(joinpath(@__DIR__, "polymake", "wslviewer.pl"))\", $force);")
   if force
      isempty(err) || error(err)
      isempty(out) || @info out
   else
      isempty(err) || @warn err
      isempty(out) || @debug out
   end
   nothing
end
