Base.show(io::IO,::MIME"text/plain", obj::pm_perl_Object) = print(io, properties(obj))

function Base.show(io::IO,::MIME"text/html",obj::pm_perl_Object)
    return_string = properties(obj)
    summary, description = split(return_string,"\n";limit=2)
    if startswith(summary, "type: ")
        summary = summary[7:end]
    end
    if startswith(description, "description: ")
        description = description[14:end]
    end
    print(io,"""
<details>
<summary>$summary</summary>
    <pre>
$description
    </pre>
</details>
""")
end

function Base.show(io::IO, ::MIME"text/plain", obj::SmallObject)
    print(io, show_small_obj(obj))
end
# fallback for non-wrapped types
function Base.show(io::IO, ::MIME"text/plain", pv::pm_perl_PropertyValue)
    print(io, to_string(pv))
end
function Base.show(io::IO, ::MIME"text/plain", a::pm_Array{pm_perl_Object})
    print(io, "pm_Array{pm_perl_Object} of size ",length(a))
end
Base.show(io::IO, obj::SmallObject) = show(io, MIME("text/plain"), obj)

struct Visual
    obj::Polymake.pm_perl_PropertyValue
end

function Base.show(io::IO, v::Visual)
    # IJulia renders all possible mimes, so frontend can decide on
    # the way to display the output.
    # This `if` keeps the browser from opening a new tab
    if !(isdefined(Main, :IJulia) && Main.IJulia.inited)
        show(io,MIME("text/plain"),v.obj)
    end
end

function Base.show(io::IO,::MIME"text/html",v::Visual)
     print(io,_get_visual_string_threejs(v))
end

function Base.show(io::IO,::MIME"text/svg+xml",v::Visual)
    print(io,_get_visual_string_svg(v))
end
