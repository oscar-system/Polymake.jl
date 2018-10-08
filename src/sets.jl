import Base: Set

import PolymakeWrap.Polymake.pm_Set

### convert TO polymake object

for (T, f) in [
    (Int32, :new_set_int32),
    (Int64, :new_set_int64),
    ]
    @eval begin
        Polymake.pm_Set(v::Vector{$T}) = Polymake.$f(v)
    end
end

pm_Set{T}(v::Vector) where T = pm_Set(Vector{T}(v))
pm_Set{T}(s::Set) where T = pm_Set{T}(collect(s))

pm_Set{S}(n::T) where {S,T <: Integer} = Polymake.scalar2set(S(n))

pm_Set{T}(itr) where T = union!(pm_Set{T}(), itr)

function pm_Set(itr)
    # use IteratorEltype(itr) trait?
    T = typeof(first(itr))
    return union!(pm_Set{T}(), itr)
end

### convert FROM polymake object

function Vector{I}(s::Polymake.pm_Set{J}) where {I,J<:Integer}
    return convert(Vector{I}, collect(s))
end

Vector(s::Polymake.pm_Set) = collect(s)

for (T, f) in [
    (Int32, :fill_jlarray_int32_from_set32),
    (Int64, :fill_jlarray_int64_from_set64)
    ]
    @eval begin
        function convert(::Type{Vector{$T}}, s::Polymake.pm_Set{$T})
            v = Vector{$T}(length(s))
            Polymake.$f(v, s)
            return v
        end
    end
end

Set(s::Polymake.pm_Set{T}) where T = Set{T}(Vector(s))
Set{T}(s::Polymake.pm_Set{S}) where {T, S} = Set{T}(Vector{S}(s))

Set{T}(s::Polymake.pm_Set{S}) where {T, S<:Integer} = Set{T}(collect(s))

Polymake.pm_Set{T}(s::Polymake.pm_Set{T}) where T = s

### Promotion rules

Base.promote_rule(::Type{Set{S}}, ::Type{Polymake.pm_Set{T}}) where {S,T} = Set{promote_type(S,T)}

### julia functions for sets

import Base: ==

# comparison between not-equally typed sets is not defined in Polymake
==(S::Polymake.pm_Set, T::Polymake.pm_Set) = incl(S,T) == 0

function ==(S::Polymake.pm_Set, jlS::Set)
    length(S) == length(jlS) || return false
    for s in jlS
        s in S || return false
    end
    return true
end

==(T::AbstractSet, S::Polymake.pm_Set) = S == T

Base.allunique(::Polymake.pm_Set) = true

Base.copy(S::Polymake.pm_Set) = deepcopy(S)

# delete! : Defined on the C++ side
Base.delete!(s::Polymake.pm_Set{T}, x) where T = delete!(s, T(x))
# empty!  : Defined on the C++ side

function Base.filter!(pred, s::Polymake.pm_Set{T}) where T
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
Base.in(x::Integer, s::Polymake.pm_Set{T}) where T<:Integer = T(x) in s

# isempty : Defined on the C++

function Base.iterate(S::pm_Set)
    isempty(S) && return nothing
    state = Polymake.begin(S)
    elt = Polymake.get_element(state)
    Polymake.increment(state)
    return elt, state
end

function Base.iterate(S::pm_Set, state)
    if Polymake.isdone(S, state)
        return nothing
    else
        elt = Polymake.get_element(state)
        Polymake.increment(state)
        return elt, state
    end
end

# length : Defined on the C++

function Base.pop!(s::Polymake.pm_Set{T}, x) where T
    if x in s
        delete!(s, x)
        return x
    else
        throw(KeyError(x))
    end
end

function Base.pop!(s::Polymake.pm_Set{T}, x, default) where T
    if x in s
        return pop!(s, x)
    else
        return default
    end
end

function Base.pop!(s::Polymake.pm_Set{T}) where T
    isempty(s) && throw(ArgumentError("set must be non-empty"))
    return pop!(s, first(s))
end

# push! : Defined on the C++ side
Base.push!(s::Polymake.pm_Set{T}, x::Integer) where T<:Integer = push!(s, T(x))
# show! : Defined on the C++ side

Base.sizehint!(s::Polymake.pm_Set, newsz) = s



# Auxillary functions:

import Base: <, <=

<(S::Polymake.pm_Set, T::Polymake.pm_Set) = incl(S,T) == -1
<=(S::Polymake.pm_Set, T::Polymake.pm_Set) = incl(S,T) <= 0
