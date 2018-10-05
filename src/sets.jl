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

Polymake.pm_Set(s::AbstractSet{S}) where S = pm_Set(collect(s))

pm_Set{T}(v::Vector) where T = pm_Set(Vector{T}(v))
pm_Set{T}(s::Set) where T = pm_Set{T}(collect(s))

pm_Set(::Type{T}) where T = pm_Set{T}()

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

==(T, S::Polymake.pm_Set) = S == T

Base.hash(S::Polymake.pm_Set, h::UInt) = hash(Vector(S), h)

Base.copy(S::Polymake.pm_Set) = deepcopy(S)

Base.similar(S::Polymake.pm_Set{T}) where T = pm_Set(Vector{T}(length(S)))

# Iteration protocol

function Base.iterate(S::pm_Set)
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

Base.eltype(::Type{Polymake.pm_SetAllocated{T}}) where T = T

# length : Defined on the C++ side

Base.size(S::Polymake.pm_Set) = (length(S),)

# Utility functions:
# isempty : Defined on the C++ side
# in : Defined on the C++ side


# Set operations:

import Base: pop!, union, intersect, unique, allunique

# push! : Defined on the C++ side
# delete! : Defined on the C++ side
# empty! : Defined on the C++ side

#in doubt: sizehint!, rehash!

function pop!(s::Polymake.pm_Set{T}, x) where T
    if x in s
        delete!(s, x)
        return x
    else
        throw(KeyError(x))
    end
end

pop!(s::Polymake.pm_Set{T}, x, default) where T = (x in s ? pop!(s, x) : default)
pop!(s::Polymake.pm_Set{T}) where T = (x = first(s); delete!(x, s); x)

union(s::Polymake.pm_Set) = copy(s)
intersect(s::Polymake.pm_Set) = copy(s)

unique(s::Polymake.pm_Set) = copy(s)
allunique(s::Polymake.pm_Set) = true

# Ordering:

import Base: <, <=

<(S::Polymake.pm_Set, T::Polymake.pm_Set) = incl(S,T) == -1
<=(S::Polymake.pm_Set, T::Polymake.pm_Set) = incl(S,T) <= 0
