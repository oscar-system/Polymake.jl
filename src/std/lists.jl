Base.eltype(::Type{<:StdList{<:StdPair{S, T}}}) where {S, T} = Pair{S,T}

Base.push!(L::StdList{<:StdPair}, a::Pair) = push!(L, StdPair(a))

Base.eltype(::Type{<:StdList{T}}) where T = T

function Base.iterate(L::StdList)
    isempty(L) &&  return nothing
    state = beginiterator(L)
    elt = get_element(state)
    increment(state)
    return eltype(L)(elt), state
end

function Base.iterate(L::StdList, state)
    if isdone(L, state)
        return nothing
    else
        elt = get_element(state)
        increment(state)
        return eltype(L)(elt), state
    end
end
