function Map{String,String}()
    return Map{to_cxx_type(String),to_cxx_type(String)}()
end

function Base.getindex(M::Map{TV, TK}, key) where {TV, TK}
    return convert(to_jl_type(TV), _getindex(M, convert(to_cxx_type(String), key)))
end

function Base.setindex!(M::Map{TV, TK}, val, key::AbstractString) where {TV, TK}
    _setindex!(M, convert(TV, val), convert(TK, key))
    return val
end

# show method
function Base.show(io::IO, M::Map)
    print(io, join(collect(M), "\n"))
end

# Iterator

Base.eltype(M::Map{S,T}) where {S,T} = Pair{to_jl_type(S), to_jl_type(T)}

function Base.iterate(M::Map{S,T}) where {S,T}
    isempty(M) &&  return nothing
    state = beginiterator(M)
    elt = get_element(state)
    increment(state)
    return Pair{to_jl_type(S), to_jl_type(T)}(elt[1], elt[2]), state
end


function Base.iterate(M::Map{S,T}, state) where {S,T}
    if isdone(M, state)
        return nothing
    else
        elt = get_element(state)
        increment(state)
        return Pair{to_jl_type(S), to_jl_type(T)}(elt[1], elt[2]), state
    end
end
