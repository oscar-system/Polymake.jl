Base.eltype(::StdList{StdPair{S, T}}) where {S, T} = Pair{T,T}

Base.push!(L::StdList{<:StdPair}, a::Pair) = push!(L, StdPair(a))

Base.eltype(::StdList{T}) where T = T

function Base.iterate(L::StdList{T}) where T
    isempty(L) &&  return nothing
    state = beginiterator(L)
    elt = get_element(state)
    increment(state)
    return elt, state
end

function Base.iterate(L::StdList{T}, state) where T
    if isdone(L, state)
        return nothing
    else
        elt = get_element(state)
        increment(state)
        return elt, state
    end
end
