const List_suppT = Union{StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}}

Base.eltype(::StdList{StdPair{T, T}}) where T = Pair{T,T}

function Base.iterate(L::StdList)
    isempty(L) &&  return nothing
    state = beginiterator(L)
    elt = get_element(state)
    increment(state)
    return Pair(elt), state
end

function Base.iterate(L::StdList, state)
    if isdone(L, state)
        return nothing
    else
        elt = get_element(state)
        increment(state)
        return Pair(elt), state
    end
end

Base.push!(L::StdList{<:StdPair}, a::Pair) = push!(L, StdPair(a))
