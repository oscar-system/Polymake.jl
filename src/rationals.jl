# specialized Int32, Int64 constructors handled by Cxx side
pm_Rational(a::BigInt, b::BigInt) = pm_Rational(pm_Integer(a), pm_Integer(b))
# for the rest we have a blanket
@inline pm_Rational(a::Integer, b::Integer) = pm_Rational(pm_Integer(a), pm_Integer(b))
pm_Rational(x::Rational{<:Integer}) = pm_Rational(numerator(x), denominator(x))

pm_Rational(int::Integer) = pm_Rational(int, one(int))
pm_Rational(x::Number) = pm_Rational(Rational(x))

Base.one(i::Type{<:pm_Rational}) = pm_Rational(1)
Base.one(i::pm_Rational) = pm_Rational(1)
Base.zero(i::pm_Rational) = pm_Rational(0)
Base.zero(i::Type{<:pm_Rational}) = pm_Rational(0)

import Base: ==, <, <=
# These are operations we delegate to gmp
for op in (:(==), :(<), :(<=))
    @eval begin
        # These are all necessary to avoid ambiguities
        $op(lhs::BigInt, rhs::pm_Rational) = $op(pm_Integer(lhs),rhs)
        $op(lhs::pm_Rational, rhs::BigInt) = $op(lhs, pm_Integer(rhs))
    end
end

function Base.promote_rule(::Type{<:pm_Rational},
    ::Type{<:Union{Integer, Rational{<:Integer}}})
    return pm_Rational
end

Base.promote_rule(::Type{<:pm_Rational}, ::Type{<:AbstractFloat}) = Float64
Base.promote_rule(::Type{<:pm_Integer}, ::Type{<:Rational}) = pm_Rational

# Rational{<:Integer} constructors from pm_Rational (provides converts as well)
@inline function Base.Rational{T}(rat::pm_Rational) where T<:Integer
    return Rational(convert(T, numerator(rat)),convert(T, denominator(rat)))
end

Base.Rational(rat::pm_Rational) = Rational{BigInt}(rat)
Base.big(rat::pm_Rational) = Rational{BigInt}(rat)

convert(::Type{T}, rat::pm_Rational) where T<:Number = convert(T, big(rat))
convert(::Type{T}, rat::pm_Rational) where T<:AbstractFloat = convert(T, Float64(rat))
Base.float(rat::pm_Rational) = Float64(rat)

# no-copy convert
convert(::Type{<:pm_Rational}, rat::T) where T <: pm_Rational = rat

# Rational division:

Base.://(x::pm_Integer, y::pm_Integer) = pm_Rational(x, y)
# ala promotion rules
Base.://(x::pm_Integer, y::Integer) = pm_Rational(x, pm_Integer(y))
Base.://(x::Integer, y::pm_Integer) = pm_Rational(pm_Integer(x), y)

Base.://(x::Rational, y::pm_Integer) = pm_Rational(numerator(x), denominator(x)*y)
Base.://(x::pm_Integer, y::Rational) = pm_Rational(x*numerator(y), denominator(y))

# division by Int32, Int64, pm_Integer defined on the Cxx side
Base.://(x::pm_Rational, y::Union{Int8, Int16, BigInt, Unsigned}) = x//pm_Integer(y)
Base.://(x::Union{Int8, Int16, BigInt, Unsigned}, y::pm_Rational) = pm_Integer(x)//y
Base.://(x::pm_Rational, y::Rational{<:Integer}) = x//pm_Rational(y)
Base.://(x::Rational{<:Integer}, y::pm_Rational) = pm_Rational(x)//y
