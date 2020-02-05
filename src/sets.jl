export incl, swap

const Set_suppT = Union{Int64, CxxWrap.CxxLong}

### convert TO polymake object
Set{T}() where T<:Set_suppT = Set{to_cxx_type(T)}()
Set{T}(v::Base.Vector{S}) where {S<:Set_suppT, T<:Set_suppT} = _new_set(v)
Set{T}(n::Base.Integer) where T<:Set_suppT = scalar2set(T(n))
Set{T}(s::Set{T}) where T<:Set_suppT = s

Set{T}(v::S) where {T, S <: Union{AbstractVector, AbstractSet}} = Set(collect(T, v))
Set{T}(itr) where T = union!(Set{to_cxx_type(T)}(), itr)

function Set(itr)
    T = Base.@default_eltype(itr)
    (isconcretetype(T) || T === Union{}) || return Set(collect(itr))
    return union!(Set{T}(), itr)
end

Base.eltype(::Set{T}) where T = to_jl_type(T)

### convert FROM polymake object

function Base.Vector{I}(s::Set{J}) where {I, J}
    jlv = Base.Vector{I}(undef, length(s))
    for (i,x) in enumerate(s)
        jlv[i] = x
    end
    return jlv
end

Base.Vector(s::Set) = collect(s)

Base.Set(s::Set{T}) where T = Base.Set{T}(Base.Vector(s))

function Base.Set{T}(s::Set{S}) where {T, S}
    jls = Base.Set{T}()
    sizehint!(jls, length(s))
    for x in s
        push!(jls, x)
    end
    return jls
end

### Promotion rules

Base.promote_rule(::Type{Base.Set{S}}, ::Type{Base.Set{T}}) where {S,T} = Base.Set{promote_type(S,T)}

### julia functions for sets

# comparison between not-equally typed sets is not defined in Polymake
==(S::Set, T::Set) = incl(S,T) == 0

function ==(S::Set, jlS::AbstractSet)
    length(S) == length(jlS) || return false
    for s in jlS
        s in S || return false
    end
    return true
end

==(T::AbstractSet, S::Set) = S == T

Base.allunique(::Set) = true

Base.copy(S::Set) = deepcopy(S)

# delete! : Defined on the C++ side
Base.delete!(s::Set{T}, x) where T = delete!(s, T(x))
# empty!  : Defined on the C++ side
#
function Base.filter!(pred, s::Set{T}) where T
    to_delete = Base.Set{T}()
    for x in s
        !pred(x) && push!(to_delete, x)
    end
    for x in to_delete
        delete!(s, x)
    end
    return s
end

# in      : Defined on the C++ side
function Base.in(x::Base.Integer, s::Set{T}) where T
    in(T(x), s)
end
#
# # isempty : Defined on the C++

function Base.iterate(S::Set)
    isempty(S) &&  return nothing
    state = beginiterator(S)
    elt = get_element(state)
    increment(state)
    return elt, state
end


function Base.iterate(S::Set, state)
    if isdone(S, state)
        return nothing
    else
        elt = get_element(state)
        increment(state)
        return elt, state
    end
end

# length : Defined on the C++

function Base.pop!(s::Set{T}, x) where T
    if x in s
        delete!(s, x)
        return x
    else
        throw(KeyError(x))
    end
end

function Base.pop!(s::Set{T}, x, default) where T
    if x in s
        return pop!(s, x)
    else
        return default
    end
end

function Base.pop!(s::Set{T}) where T
    isempty(s) && throw(ArgumentError("set must be non-empty"))
    return pop!(s, first(s))
end

# push! : Defined on the C++ side
Base.push!(s::Set{T}, x::Base.Integer) where T = push!(s, T(x))
# show! : Defined on the C++ side

Base.sizehint!(s::Set, newsz) = s


# Auxillary functions:

<(S::Set, T::Set) = incl(S,T) == -1
<=(S::Set, T::Set) = incl(S,T) <= 0
