to_one_based_indexing(n::Number) = n + one(n)
to_zero_based_indexing(n::Number) = (n > zero(n) ? n - one(n) : throw(ArgumentError("Can't use negative index")))

for f in [:to_one_based_indexing, :to_zero_based_indexing]
    @eval begin
        $f(itr) = $f.(itr)
        $f(s::S) where S<:Set = Set($f.(s))
    end
end

get_current_app() = shell_execute("print \$User::application->name;").stdout

function get_docs(input::String; full::Bool=true, html::Bool=false)
    pos = UInt(max(length(input)-1, 0))
    return shell_context_help(input, pos, full, html)
end

function shell_execute(str::AbstractString)
    correct_input, out, err, msg = convert(Tuple{Bool, String, String, String}, _shell_execute(str))
    if correct_input
        isempty(msg) && return (stdout=out, stderr=err)
        @error "Polymake returned:" out err
        throw(PolymakeError(msg))
    elseif isempty(out) && isempty(err) && isempty(msg) # correct_input == false
        throw(PolymakeError("incomplete input in polymake shell: \"$str\""))
    else
        @error "Polymake returned:" out err
        throw(PolymakeError(msg))
    end
end

function cite(;format=:bibtex)
    cite_str = match(r"(?<bibtex>@incollection.*\n (\s*\w*\s?= .*\n)+\s*\})", shell_execute("""help "core/citation";""").stdout)
    if format == :bibtex
        return print(cite_str[:bibtex])
    else
        throw("The only supported citation format is :bibtex")
    end
end

"""
    prefer(label_expression::String)

Make the production rules, user functions, or methods (further called items) matching the given `label_expression` be preferred over competing rules (functions, methods).

## Examples

If you prefer to use lrs as the default for the convex hull computation set
```
prefer("lrs.convex_hull")
```

Another example
```
prefer("cdd.simplex")
```
"""
prefer(label_expression::String) = set_preference(label_expression)
