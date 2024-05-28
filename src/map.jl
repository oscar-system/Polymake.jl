function Map{String,String}()
    return Map{to_cxx_type(String),to_cxx_type(String)}()
end

function Base.getindex(M::Map{TK, TV}, key) where {TK, TV}
    return convert(to_jl_type(TV), _getindex(M, convert(to_cxx_type(TK), key)))
end

function Base.setindex!(M::Map{TK, TV}, val, key) where {TK, TV}
   _setindex!(M, convert(to_cxx_type(TV), val), convert(to_cxx_type(TK), key))
    return val
end

function Base.haskey(M::Map{TK, TV}, key) where {TK, TV}
    return _haskey(M, convert(to_cxx_type(TK), key))
end

function Base.:(==)(M::Map{TK,TV}, N::Map{TK,TV}) where {TK, TV}
   return _isequal(M,N)
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
