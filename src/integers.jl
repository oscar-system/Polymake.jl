function BigInt(int::pm_IntegerAllocated)
    deepcopy(unsafe_load(reinterpret(Ptr{BigInt},int.cpp_object)))
end


# Int32, Int64 constructors handled by Cxx side
pm_Integer(int::Int128) = pm_Integer(big(int))
pm_Integer(int::BigInt) = new_pm_Integer_from_bigint(int)
pm_Integer(int::Integer) = pm_Integer(BigInt(int))

Base.one(i::Type{<:pm_Integer}) = pm_Integer(1)
Base.one(i::pm_Integer) = pm_Integer(1)
Base.zero(i::pm_Integer) = pm_Integer(0)
Base.zero(i::Type{<:pm_Integer}) = pm_Integer(0)

import Base: ==, <, <=
# These are operations we delegate to gmp
for op in (:(==), :(<), :(<=))
    @eval begin
        # These are all necessary to avoid ambiguities
        $op(lhs::BigInt, rhs::pm_Integer) = $op(lhs,BigInt(rhs))
        $op(lhs::pm_Integer, rhs::BigInt) = $op(BigInt(lhs), rhs)
    end
end

function Base.promote_rule(::Type{pm_Integer}, ::Type{<:Union{Int128, Int64, Int32}})
    pm_Integer
end

Base.promote_rule(::Type{<:pm_Integer}, ::Type{BigInt}) = pm_Integer
Base.promote_rule(::Type{BigInt}, ::Type{<:pm_Integer}) = pm_Integer

# Convert from Julia to PM
function Base.convert(::Type{<:pm_Integer}, int::Integer)
    return pm_Integer(int)
end
Base.convert(::Type{<:pm_Integer}, int::T) where T <: pm_Integer = int
# Convert from PM to Julia
function Base.convert(::Type{T}, int::pm_Integer) where {T<:Integer}
    convert(T, BigInt(int))
end

Base.convert(::Type{Integer},int::pm_Integer) = int
