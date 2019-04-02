export incl, swap

import Base: Set

### convert TO polymake object

pm_Set(v::Vector{T}) where T<:Integer = _new_set(v)

pm_Set{T}(v::Vector) where T = pm_Set(Vector{T}(v))
pm_Set{T}(s::Set) where T = pm_Set{T}(collect(s))

pm_Set{S}(n::T) where {S,T <: Integer} = scalar2set(S(n))

pm_Set{T}(itr) where T = union!(pm_Set{T}(), itr)

function pm_Set(itr)
    T = Base.@default_eltype(itr)
    (isconcretetype(T) || T === Union{}) || return pm_Set(collect(itr))
    return union!(pm_Set{T}(), itr)
end

pm_SetAllocated{T}(v::Vector{T}) where T<:Integer = pm_Set{T}(v)

### convert FROM polymake object

function Vector{I}(s::pm_Set{J}) where {I,J<:Integer}
    return convert(Vector{I}, collect(s))
end

Vector(s::pm_Set) = collect(s)

Set(s::pm_Set{T}) where T = Set{T}(Vector(s))
Set{T}(s::pm_Set{S}) where {T, S} = Set{T}(Vector{S}(s))

Set{T}(s::pm_Set{S}) where {T, S<:Integer} = Set{T}(collect(s))

pm_Set{T}(s::pm_Set{T}) where T = s

### Promotion rules

Base.promote_rule(::Type{Set{S}}, ::Type{pm_Set{T}}) where {S,T} = Set{promote_type(S,T)}

### julia functions for sets

# comparison between not-equally typed sets is not defined in Polymake
==(S::pm_Set, T::pm_Set) = incl(S,T) == 0

function ==(S::pm_Set, jlS::Set)
    length(S) == length(jlS) || return false
    for s in jlS
        s in S || return false
    end
    return true
end

==(T::AbstractSet, S::pm_Set) = S == T

Base.allunique(::pm_Set) = true

Base.copy(S::pm_Set) = deepcopy(S)

# delete! : Defined on the C++ side
Base.delete!(s::pm_Set{T}, x) where T = delete!(s, T(x))
# empty!  : Defined on the C++ side
#
function Base.filter!(pred, s::pm_Set{T}) where T
    to_delete = Set{T}()
    for x in s
        !pred(x) && push!(to_delete, x)
    end
    for x in to_delete
        delete!(s, x)
    end
    return s
end

# in      : Defined on the C++ side
function Base.in(x::Integer, s::pm_Set{T}) where T<:Integer
    in(T(x), s)
end
#
# # isempty : Defined on the C++

function Base.iterate(S::pm_Set)
    isempty(S) &&  return nothing
    state = beginiterator(S)
    elt = get_element(state)
    increment(state)
    return elt, state
end


function Base.iterate(S::pm_Set, state)
    if isdone(S, state)
        return nothing
    else
        elt = get_element(state)
        increment(state)
        return elt, state
    end
end

# length : Defined on the C++

function Base.pop!(s::pm_Set{T}, x) where T
    if x in s
        delete!(s, x)
        return x
    else
        throw(KeyError(x))
    end
end

function Base.pop!(s::pm_Set{T}, x, default) where T
    if x in s
        return pop!(s, x)
    else
        return default
    end
end

function Base.pop!(s::pm_Set{T}) where T
    isempty(s) && throw(ArgumentError("set must be non-empty"))
    return pop!(s, first(s))
end

# push! : Defined on the C++ side
Base.push!(s::pm_Set{T}, x::Integer) where T<:Integer = push!(s, T(x))
# show! : Defined on the C++ side

Base.sizehint!(s::pm_Set, newsz) = s


# Auxillary functions:

<(S::pm_Set, T::pm_Set) = incl(S,T) == -1
<=(S::pm_Set, T::pm_Set) = incl(S,T) <= 0
