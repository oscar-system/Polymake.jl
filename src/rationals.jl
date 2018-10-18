function Rational(frac::Polymake.pm_RationalAllocated)
    Rational(BigInt(numerator(frac)), BigInt(denominator(frac)))
end


# Int32, Int64 constructors handled by Cxx side
Polymake.pm_Rational(a::Int128, b::Int128) = Polymake.pm_Rational(big(a), big(b))
function Polymake.pm_Rational(a::BigInt, b::BigInt)
    Polymake.pm_Rational(pm_Integer(a), pm_Integer(b))
end
function Polymake.pm_Rational(x::Rational{<:Integer})
    Polymake.pm_Rational(numerator(x), denominator(x))
end
# Fallback for same integer types -> convert to BigInt first
function Polymake.pm_Rational(a::T, b::T) where {T<:Integer}
    Polymake.pm_Rational(BigInt(a), BigInt(b))
end
# If we have different integer types, promote to common type first
function Polymake.pm_Rational(a::Integer, b::Integer)
    Polymake.pm_Rational(promote(a, b)...)
end
Polymake.pm_Rational(int::Integer) = pm_Rational(int, one(int))

Base.one(i::Type{<:Polymake.pm_Rational}) = pm_Rational(1)
Base.one(i::Polymake.pm_Rational) = pm_Rational(1)
Base.zero(i::Polymake.pm_Rational) = pm_Rational(0)
Base.zero(i::Type{<:Polymake.pm_Rational}) = pm_Rational(0)

import Base: ==, <, <=
# These are operations we delegate to gmp
for op in (:(==), :(<), :(<=))
    @eval begin
        # These are all necessary to avoid ambiguities
        $op(lhs::BigInt, rhs::Polymake.pm_Rational) = $op(pm_Integer(lhs),rhs)
        $op(lhs::Polymake.pm_Rational, rhs::BigInt) = $op(lhs, pm_Integer(rhs))
    end
end

function Base.promote_rule(::Type{Polymake.pm_Rational}, ::Type{<:Union{Int128, Int64, Int32}})
    Polymake.pm_Rational
end
Base.promote_rule(::Type{<:Polymake.pm_Rational}, ::Type{BigInt}) = Polymake.pm_Rational
Base.promote_rule(::Type{BigInt}, ::Type{<:Polymake.pm_Rational}) = Polymake.pm_Rational
Base.promote_rule(::Type{<:Polymake.pm_Rational}, ::Type{<:Rational{<:Integer}}) = Polymake.pm_Rational
Base.promote_rule(::Type{<:Rational{<:Integer}}, ::Type{<:Polymake.pm_Rational}) = Polymake.pm_Rational

# Convert from Julia to PM
Base.convert(::Type{<:Polymake.pm_Rational}, x::Integer) = Polymake.pm_Rational(x, one(x))
Base.convert(::Type{<:Polymake.pm_Rational}, x::Rational) = Polymake.pm_Rational(x)
