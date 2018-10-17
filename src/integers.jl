function BigInt(int::Polymake.pm_IntegerAllocated)
    deepcopy(unsafe_load(reinterpret(Ptr{BigInt},int.cpp_object)))
end


# Int32, Int64 constructors handled by Cxx side
Polymake.pm_Integer(int::Int128) = Polymake.pm_Integer(big(int))
Polymake.pm_Integer(int::BigInt) = Polymake.new_pm_Integer_from_bigint(int)
Polymake.pm_Integer(int::Integer) = Polymake.pm_Integer(BigInt(int))

Base.one(i::Type{<:Polymake.pm_Integer}) = pm_Integer(1)
Base.one(i::Polymake.pm_Integer) = pm_Integer(1)
Base.zero(i::Polymake.pm_Integer) = pm_Integer(0)
Base.zero(i::Type{<:Polymake.pm_Integer}) = pm_Integer(0)

import Base: ==, <, <=
# These are operations we delegate to gmp
for op in (:(==), :(<), :(<=))
    @eval begin
        # These are all necessary to avoid ambiguities
        $op(lhs::BigInt, rhs::Polymake.pm_Integer) = $op(lhs,BigInt(rhs))
        $op(lhs::Polymake.pm_Integer, rhs::BigInt) = $op(BigInt(lhs), rhs)
    end
end

function Base.promote_rule(::Type{Polymake.pm_Integer}, ::Type{<:Union{Int128, Int64, Int32}})
    Polymake.pm_Integer
end

Base.promote_rule(::Type{<:Polymake.pm_Integer}, ::Type{BigInt}) = Polymake.pm_Integer
Base.promote_rule(::Type{BigInt}, ::Type{<:Polymake.pm_Integer}) = Polymake.pm_Integer

# Convert from Julia to PM
function Base.convert(::Type{<:Polymake.pm_Integer}, int::Integer)
    return Polymake.pm_Integer(int)
end
Base.convert(::Type{<:Polymake.pm_Integer}, int::Polymake.pm_IntegerAllocated) = int
# Convert from PM to Julia
function Base.convert(::Type{T}, int::Polymake.pm_Integer) where {T<:Integer}
    convert(T, BigInt(int))
end
