# One arguments constructors used by convert:
# specialized Int32, Int64 constructors handled by Cxx side
pm_Integer(int::BigInt) = new_pm_Integer_from_bigint(int)
pm_Integer(int::Number) = pm_Integer(BigInt(int))
# to avoid ambiguities:
pm_Integer(rat::Rational) = pm_Integer(BigInt(rat))
pm_Integer(flt::BigFloat) = pm_Integer(BigInt(flt))

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

function Base.promote_rule(::Type{<:pm_Integer}, ::Type{<:Union{Signed, Unsigned}})
    return pm_Integer
end
# symmetric promote_rule is needed since BigInts define those for Integer:
Base.promote_rule(::Type{BigInt}, ::Type{<:pm_Integer}) = pm_Integer
Base.promote_rule(::Type{<:pm_Integer}, ::Type{<:AbstractFloat}) = Float64

# BigInt constructor from pm_Integer
@inline function Base.BigInt(int::pmI) where pmI<:pm_Integer
    return deepcopy(unsafe_load(reinterpret(Ptr{BigInt},int.cpp_object)))
end
# all convert(T, x) fallbacks to T(x)
# big(::Integer) goes through convert(BigInt, x)
for T in [:Int8,  :Int16,  :Int32,  :Int64,  :Int128,
          :UInt8, :UInt16, :UInt32, :UInt64, :UInt128]
    @eval Base.$T(int::pm_Integer) = $T(BigInt(int))
end

convert(::Type{T}, int::pm_Integer) where {T<:Number} = convert(T, BigInt(int))
convert(::Type{T}, int::pm_Integer) where {T<:AbstractFloat} = convert(T, Float64(int))
Base.float(int::pm_Integer) = Float64(int)

# no-copy converts
convert(::Type{<:pm_Integer}, int::T) where T <: pm_Integer = int
convert(::Type{Integer}, int::pm_Integer) = int
