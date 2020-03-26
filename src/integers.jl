# One arguments constructors used by convert:
# specialized Int64 constructors handled by Cxx side
Integer(int::BigInt) = new_integer_from_bigint(int)
Integer(int::Number) = Integer(BigInt(int))
# to avoid ambiguities:
Integer(rat::Base.Rational) = Integer(BigInt(rat))
Integer(flt::BigFloat) = Integer(BigInt(flt))

Base.one(::Type{<:Integer}) = Integer(1)
Base.one(::Integer) = Integer(1)
Base.zero(::Integer) = Integer(0)
Base.zero(::Type{<:Integer}) = Integer(0)

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
@inline function Base.BigInt(int::pmI) where pmI<:Integer
    return deepcopy(unsafe_load(reinterpret(Ptr{BigInt},int.cpp_object)))
end
# all convert(T, x) fallbacks to T(x)
# big(::Integer) goes through convert(BigInt, x)
for T in [:Int8,  :Int16,  :Int32,  :Int64,  :Int128,
          :UInt8, :UInt16, :UInt32, :UInt64, :UInt128]
    @eval Base.$T(int::Integer) = $T(BigInt(int))
end

convert(::Type{T}, int::Integer) where {T<:Number} = convert(T, BigInt(int))
convert(::Type{T}, int::Integer) where {T<:AbstractFloat} = convert(T, Float64(int))
Base.float(int::Integer) = Float64(int)

# no-copy converts
convert(::Type{<:Integer}, int::T) where T <: Integer = int
convert(::Type{Base.Integer}, int::Integer) = int

Base.trailing_zeros(int::Integer) = trailing_zeros(BigInt(int))
Base.trailing_ones(int::Integer) = trailing_ones(BigInt(int))
Base.:(>>)(int::Polymake.Integer, n::UInt64) = >>(BigInt(int), n)
Base.:(<<)(int::Polymake.Integer, n::UInt64) = <<(BigInt(int), n)
