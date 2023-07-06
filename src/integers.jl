# One arguments constructors used by convert:
# specialized Int64 constructors handled by Cxx side
Integer(int::BigInt) = new_integer_from_bigint(int)
Integer(int::Number) = Integer(BigInt(int))
# to avoid ambiguities:
Integer(rat::Base.Rational) = Integer(BigInt(rat))
Integer(flt::BigFloat) = Integer(BigInt(flt))

# we need thie to make the fallbacks like Base.one work
IntegerAllocated(int::Union{BigInt,Base.Rational,BigFloat,<:Number}) = Integer(int)

import Base: ==, <, <=
# These are operations we delegate to gmp
for op in (:(==), :(<), :(<=))
    @eval begin
        # These are all necessary to avoid ambiguities
        $op(lhs::BigInt, rhs::Integer) = $op(lhs,BigInt(rhs))
        $op(lhs::Integer, rhs::BigInt) = $op(BigInt(lhs), rhs)
    end
end

function Base.promote_rule(::Type{<:Integer}, ::Type{<:Union{Bool, Signed, Unsigned}})
    return Integer
end
# symmetric promote_rule is needed since BigInts define those for Integer:
Base.promote_rule(::Type{BigInt}, ::Type{<:Integer}) = Integer
Base.promote_rule(::Type{<:Integer}, ::Type{<:AbstractFloat}) = Float64

# BigInt constructor from Integer
@inline function Base.BigInt(int::Integer)
    isfinite(int) || throw(DomainError(int))
    GC.@preserve int deepcopy(unsafe_load(Ptr{BigInt}(int.cpp_object)))
end
# all convert(T, x) fallbacks to T(x)
# big(::Integer) goes through convert(BigInt, x)
for T in [:Int128, :UInt64, :UInt128]
    @eval Base.$T(int::Integer) = $T(BigInt(int))
end

Base.Int64(int::Integer) = Int64(new_int_from_integer(int))

for T in [:Int8,  :Int16,  :Int32, :UInt8, :UInt16, :UInt32]
    @eval Base.$T(int::Integer) = $T(Int64(int))
end

Rational(int::Integer) = new_rational_from_integer(int)
(::Type{T})(int::Integer) where {T<:Number} = convert(T, BigInt(int))
(::Type{T})(int::Integer) where {T<:AbstractFloat} = convert(T, Float64(int))
# to avoid ambiguity
Float64(int::Integer) = Float64(CxxWrap.CxxRef(int))
BigFloat(int::Integer) = BigFloat(BigInt(int))
Base.float(int::Integer) = Float64(int)

# no-copy converts
Integer(int::Integer) = int
Base.Integer(int::Integer) = int

Base.trailing_zeros(int::Integer) = trailing_zeros(BigInt(int))
Base.trailing_ones(int::Integer) = trailing_ones(BigInt(int))
Base.:(>>)(int::Polymake.Integer, n::UInt64) = >>(BigInt(int), n)
Base.:(<<)(int::Polymake.Integer, n::UInt64) = <<(BigInt(int), n)

Base.checked_abs(x::Integer) = abs(x)
Base.checked_neg(x::Integer) = -x
Base.checked_add(a::Integer, b::Integer) = a + b
Base.checked_sub(a::Integer, b::Integer) = a - b
Base.checked_mul(a::Integer, b::Integer) = a * b
Base.checked_div(a::Integer, b::Integer) = div(a, b)
Base.checked_rem(a::Integer, b::Integer) = rem(a, b)
Base.add_with_overflow(a::Integer, b::Integer) = a + b, false
Base.sub_with_overflow(a::Integer, b::Integer) = a - b, false
Base.mul_with_overflow(a::Integer, b::Integer) = a * b, false
