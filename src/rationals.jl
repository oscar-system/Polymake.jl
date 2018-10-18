function Rational(frac::pm_RationalAllocated)
    Rational(BigInt(numerator(frac)), BigInt(denominator(frac)))
end


# Int32, Int64 constructors handled by Cxx side
pm_Rational(a::Int128, b::Int128) = pm_Rational(big(a), big(b))
function pm_Rational(a::BigInt, b::BigInt)
    pm_Rational(pm_Integer(a), pm_Integer(b))
end
function pm_Rational(x::Rational{<:Integer})
    pm_Rational(numerator(x), denominator(x))
end
# Fallback for same integer types -> convert to BigInt first
function pm_Rational(a::T, b::T) where {T<:Integer}
    pm_Rational(BigInt(a), BigInt(b))
end
# If we have different integer types, promote to common type first
function pm_Rational(a::Integer, b::Integer)
    pm_Rational(promote(a, b)...)
end
pm_Rational(int::Integer) = pm_Rational(int, one(int))

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

function Base.promote_rule(::Type{pm_Rational}, ::Type{<:Union{Int128, Int64, Int32}})
    pm_Rational
end
Base.promote_rule(::Type{<:pm_Rational}, ::Type{BigInt}) = pm_Rational
Base.promote_rule(::Type{BigInt}, ::Type{<:pm_Rational}) = pm_Rational
Base.promote_rule(::Type{<:pm_Rational}, ::Type{<:Rational{<:Integer}}) = pm_Rational
Base.promote_rule(::Type{<:Rational{<:Integer}}, ::Type{<:pm_Rational}) = pm_Rational

# Convert from Julia to PM
Base.convert(::Type{<:pm_Rational}, x::Integer) = pm_Rational(x, one(x))
Base.convert(::Type{<:pm_Rational}, x::Rational) = pm_Rational(x)
