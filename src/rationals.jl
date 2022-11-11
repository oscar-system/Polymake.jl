Rational(num::Int64, den::Int64) =
    rational_si_si(convert(CxxLong, num), convert(CxxLong, den))

function Rational(num::T, den::S) where {T<:Base.Integer, S<:Base.Integer}
    R = promote_type(promote_type(T, Int64), promote_type(S, Int64))
    R == Int64 && return Rational(convert(Int64, num), convert(Int64, den))
    return Rational(Integer(convert(BigInt, num)), Integer(convert(BigInt, den)))
end

Rational(x::Base.Rational) = Rational(numerator(x), denominator(x))
@inline function Rational(x::Base.Rational{BigInt})
    GC.@preserve x new_rational_from_baserational(pointer_from_objref(numerator(x)), pointer_from_objref(denominator(x)))
end
Rational(int::Base.Integer) = Rational(int, one(int))
Rational(x::Number) = Rational(Base.Rational(x))

Base.one(::Type{<:Rational}) = Rational(1)
Base.one(::Rational) = Rational(1)
Base.zero(::Rational) = Rational(0)
Base.zero(::Type{<:Rational}) = Rational(0)

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

@inline function Base.Rational{BigInt}(rat::Rational)
    res = Base.Rational{BigInt}(0)
    new_baserational_from_rational(rat, pointer_from_objref(res.num), pointer_from_objref(res.den))
    return res
end

Base.Rational(rat::Rational) = Base.Rational{BigInt}(rat)
Base.big(rat::Rational) = Base.Rational{BigInt}(rat)

convert(::Type{Integer}, rat::Rational) = new_integer_from_rational(rat)
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
Base.://(x::Rational, y::Base.Rational) = x//Rational(y)
Base.://(x::Base.Rational, y::Rational) = Rational(x)//y
Base.://(x::Bool, y::Rational) = Rational(x)//y

for op in (:*, :+, :-)
    @eval begin
        Base.$op(x::Integer, y::Base.Rational) = $op(x, Rational(y))
        Base.$op(y::Base.Rational, x::Integer) = $op(Rational(y), x)
    end
end
