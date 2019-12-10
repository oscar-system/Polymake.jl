to_one_based_indexing(n::Number) = n + one(n)
to_zero_based_indexing(n::Number) = (n > zero(n) ? n - one(n) : throw(ArgumentError("Can't use negative index")))

for f in [:to_one_based_indexing, :to_zero_based_indexing]
    @eval begin
        $f(itr) = $f.(itr)
        $f(s::S) where S<:AbstractSet = S($f.(s))
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
