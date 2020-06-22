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

# workaround for https://github.com/JuliaInterop/CxxWrap.jl/issues/199
for (jlF, pmF) in (
    (:(==), :_isequal),
    (:getindex, :_getindex),
    )
    @eval begin
        Base.$jlF(s::S, t::S) where S<:Set = $pmF(s,t)
    end
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

Base.Set(s::Set{T}) where T = Base.Set{to_jl_type(T)}(Base.Vector(s))

function Base.Set{T}(s::Set{S}) where {T, S}
    jls = Base.Set{T}()
    sizehint!(jls, length(s))
    for x in s
        push!(jls, x)
    end
    return jls
end

### Promotion rules

Base.promote_rule(::Type{<:Set{S}}, ::Type{Base.Set{T}}) where {S,T} =
    Base.Set{promote_type(to_jl_type(S),T)}
Base.emptymutable(s::Set{T}, ::Type{U}=to_jl_type(T)) where {T,U} =
    Base.emptymutable(Base.Set{to_jl_type(T)}(), U)
Base.copymutable(s::Set{T}) where T = Base.Set{to_jl_type(T)}(s)

### julia functions for sets

# comparison between not-equally typed sets is not defined in Polymake
==(S::Set, T::Set) = incl(S,T) == 0

function ==(S::Set, jlS::AbstractSet)
    length(S) == length(jlS) || return false
    return all(s in S for s in jlS)
end

==(T::AbstractSet, S::Set) = S == T

Base.allunique(::Set) = true

# delete! : Defined on the C++ side
Base.delete!(s::Set{T}, x) where T = delete!(s, T(x))
# empty!  : Defined on the C++ side
Base.empty(s::Set{T}, ::Type{U}=T) where {T, U} = Set{to_cxx_type(U)}()
#
function Base.filter!(pred, s::Set{T}) where T
    to_delete = Base.Set{to_jl_type(T)}()
    for x in s
        !pred(x) && push!(to_delete, x)
    end
    for x in to_delete
        delete!(s, x)
    end
    return s
end

# in      : Defined on the C++ side
Base.in(x::Base.Integer, s::Set{T}) where T = in(T(x), s)

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

Base.pop!(s::Set{T}, x) where T = (x in s ? (delete!(s,x); x) : throw(KeyError(x)))
Base.pop!(s::Set{T}, x, default) where T = (x in s ? pop!(s,x) : default)

function Base.pop!(s::Set{T}) where T
    isempty(s) && throw(ArgumentError("set must be non-empty"))
    return pop!(s, first(s))
end

# push! : Defined on the C++ side
Base.push!(s::Set{T}, x::Base.Integer) where T = push!(s, T(x))
# show : Defined on the C++ side

Base.sizehint!(s::Set, newsz) = s


# Auxillary functions:

<(S::Set, T::Set) = incl(S,T) == -1
<=(S::Set, T::Set) = incl(S,T) <= 0
