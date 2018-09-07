import Base: Set

import PolymakeWrap.Polymake.pm_Set
### convert TO polymake object

for (T, f) in [
    (Int32, :new_set_int32),
    (Int64, :new_set_int64),
    ]
    @eval begin
        function convert(::Type{Polymake.pm_Set}, v::Vector{$T})
            return Polymake.$f(v)
        end
    end
end

pm_Set{T}(v::Vector) where T <: Signed = pm_Set(Vector{T}(v))
pm_Set(::Type{T}) where T = pm_Set{T}()

convert(::Type{Polymake.pm_Set}, s::Set) = pm_Set(collect(s))

### convert FROM polymake object

function convert(::Type{Vector}, s::Polymake.pm_Set{T}) where T<:Integer
    return Vector{T}(s)
end

function convert(::Type{Vector{I}}, s::Polymake.pm_Set{J}) where {I,J<:Integer}
    return convert(Vector{I}, Vector(s))
end

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

function convert(::Type{Set{T}}, set::Polymake.pm_Set{S}) where {T, S<:Integer}
    return Set{T}(Vector(set))
end

convert(::Polymake.pm_Set{T}, s::Polymake.pm_Set{T}) where T = s
convert(::Polymake.pm_Set{T}, s::Polymake.pm_Set) where T = s

### julia functions for sets

import Base: <, <=, ==

<(S::Polymake.pm_Set, T::Polymake.pm_Set) = incl(S,T) == -1
<=(S::Polymake.pm_Set, T::Polymake.pm_Set) = incl(S,T) <= 0
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

