const List_suppT = Union{Std.Pair{CxxWrap.CxxLong, CxxWrap.CxxLong}}

function Base.iterate(L::StdList)
    isempty(L) &&  return nothing
    state = beginiterator(L)
    elt = get_element(state)
    increment(state)
    return elt, state
end

function Base.iterate(L::StdList, state)
    if isdone(L, state)
        return nothing
    else
        elt = get_element(state)
        increment(state)
        return elt, state
    end
end

