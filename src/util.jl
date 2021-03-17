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

version() = VersionNumber(shell_execute("print \$Version;").stdout)
installTop() = shell_execute("print \$InstallTop;").stdout

function cite(;format=:bibtex)
    cite_str = match(r"(?<bibtex>@incollection.*\n (\s*\w*\s?= .*\n)+\s*\})", shell_execute("""help "core/citation";""").stdout)
    if format == :bibtex
        return print(cite_str[:bibtex])
    else
        throw("The only supported citation format is :bibtex")
    end
end

labeldict = Dict{String,Base.Array{String}}()

function lookup_label_app(label_expression::String)
   if isempty(labeldict)
      for app in list_applications()
         for label in list_labels(Symbol(app))
            if haskey(labeldict,label)
               push!(labeldict[label],app)
            else
               labeldict[label] = [app]
            end
         end
      end
   end
   label = split(label_expression,".",limit=2)[1]
   apps = get(labeldict,label,[])
   if length(apps) == 1
      return apps[1]
   elseif length(apps) == 0
      throw(PolymakeError("label '$label' not found"))
   else
      throw(PolymakeError("label '$label' ambiguous: applications $apps"))
   end
end

"""
    prefer(f::Function, label_expression::String; application::String="")

Make the production rules, user functions, or methods (further called items) matching the given `label_expression` be preferred over competing rules (functions, methods).

## Examples

If you prefer to use lrs as the default for the convex hull computation set
```
c = polytope.cube(3)
prefer("lrs.convex_hull") do
   c.VERTICES
end
```

Another example
```
m = matroid.fano_matroid()
prefer("_4ti2"; application="matroid") do
   m.CIRCUITS
end
```

FIXME: this is deprecated in favour of the do block syntax
       also it doesn't really work as the labels are not looked up
       in the correct application
"""
function prefer(label_expression::String)
    Base.depwarn("`prefer(label)` is deprecated, use `prefer(label) do ... end` instead.", :prefer, force=true)
   set_preference(label_expression)
end

function prefer(f::Function, label_expression::String; application::String="")
   old_app = get_current_app()
   scope = scope_begin()
   if application == ""
      application = lookup_label_app(label_expression)
   end
   # switching apps will just switch some references within polymake back and forth
   # we need to do this for the proper label lookup
   Polymake.application(application)
   internal_prefer_now(scope, label_expression)
   Polymake.application(old_app)

   res = f()

   scope_end(scope)
   return res
end
