# specialized Int32, Int64 constructors handled by Cxx side
Rational(a::BigInt, b::BigInt) = Rational(Integer(a), Integer(b))
# for the rest we have a blanket
@inline Rational(a::Base.Integer, b::Base.Integer) = Rational(Integer(a), Integer(b))
Rational(x::Base.Rational{<:Base.Integer}) = Rational(numerator(x), denominator(x))

Rational(int::Base.Integer) = Rational(int, one(int))
Rational(x::Number) = Rational(Base.Rational(x))

Base.one(i::Type{<:Rational}) = Rational(1)
Base.one(i::Rational) = Rational(1)
Base.zero(i::Rational) = Rational(0)
Base.zero(i::Type{<:Rational}) = Rational(0)

import Base: ==, <, <=
# These are operations we delegate to gmp
for op in (:(==), :(<), :(<=))
    @eval begin
        # These are all necessary to avoid ambiguities
        $op(lhs::BigInt, rhs::Rational) = $op(Integer(lhs),rhs)
        $op(lhs::Rational, rhs::BigInt) = $op(lhs, Integer(rhs))
    end
end

function Base.promote_rule(::Type{<:Rational},
    ::Type{<:Union{Base.Integer, Base.Rational{<:Base.Integer}}})
    return Rational
end

Base.promote_rule(::Type{<:Rational}, ::Type{<:AbstractFloat}) = Float64
Base.promote_rule(::Type{<:Integer}, ::Type{<:Base.Rational}) = Rational

# Base.Rational{<:Base.Integer} constructors from Rational (provides converts as well)
@inline function Base.Rational{T}(rat::Rational) where T<:Base.Integer
    return Base.Rational(convert(T, numerator(rat)),convert(T, denominator(rat)))
end

Base.Rational(rat::Rational) = Base.Rational{BigInt}(rat)
Base.big(rat::Rational) = Base.Rational{BigInt}(rat)

convert(::Type{T}, rat::Rational) where T<:Number = convert(T, big(rat))
convert(::Type{T}, rat::Rational) where T<:AbstractFloat = convert(T, Float64(rat))
Base.float(rat::Rational) = Float64(rat)

# no-copy convert
convert(::Type{<:Rational}, rat::T) where T <: Rational = rat

# Rational division:

Base.://(x::Integer, y::Integer) = Rational(x, y)
# ala promotion rules
Base.://(x::Integer, y::Base.Integer) = Rational(x, Integer(y))
Base.://(x::Base.Integer, y::Integer) = Rational(Integer(x), y)

Base.://(x::Base.Rational, y::Integer) = Rational(numerator(x), denominator(x)*y)
Base.://(x::Integer, y::Base.Rational) = Rational(x*numerator(y), denominator(y))

# division by Int64, Integer defined on the Cxx side
Base.://(x::Rational, y::Union{Int8, Int16, Int32, BigInt, Unsigned}) = x//Integer(y)
Base.://(x::Union{Int8, Int16, Int32, BigInt, Unsigned}, y::Rational) = Integer(x)//y
Base.://(x::Rational, y::Base.Rational{<:Base.Integer}) = x//Rational(y)
Base.://(x::Base.Rational{<:Base.Integer}, y::Rational) = Rational(x)//y
