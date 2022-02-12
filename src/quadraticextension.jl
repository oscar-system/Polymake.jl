const qe_suppT = Union{Polymake.Rational}

QuadraticExtension{T}(a::Number, b::Number, r::Number) where T<:qe_suppT =
    QuadraticExtension{T}(convert(T, a), convert(T, b), convert(T, r))
    
QuadraticExtension{T}(a::Number) where T<:qe_suppT = QuadraticExtension{T}(a, 0, 0)

QuadraticExtension(x...) = QuadraticExtension{Rational}(x...)

Base.zero(::Type{<:QuadraticExtension{T}}) where T<:qe_suppT = QuadraticExtension{T}(0)
Base.zero(::QuadraticExtension{T}) where T<:qe_suppT = QuadraticExtension{T}(0)
Base.one(::Type{<:QuadraticExtension{T}}) where T<:qe_suppT = QuadraticExtension{T}(1)
Base.one(::QuadraticExtension{T}) where T<:qe_suppT = QuadraticExtension{T}(1)

generating_field_elements(qe::QuadraticExtension{T}) where T<:qe_suppT = (a = _a(qe), b = _b(qe),  r =_r(qe))

# we might need to split this up
# if we should wrap `QuadraticExtension` with another scalar than `Rational`
function Base.promote_rule(::Type{<:QuadraticExtension{T}},
    ::Type{<:Union{T, Base.Integer, Base.Rational{<:Base.Integer}}}) where T<:qe_suppT
    return QuadraticExtension{T}
end

import Base: <, //, <=
# defining for `Real` to avoid disambiguities
Base.:<(x::Real, y::QuadraticExtension{T}) where T<:qe_suppT = convert(QuadraticExtension{T}, x) < y
Base.:<(x::QuadraticExtension{T}, y::Real) where T<:qe_suppT = x < convert(QuadraticExtension{T}, y)
Base.://(x::Real, y::QuadraticExtension{T}) where T<:qe_suppT = convert(QuadraticExtension{T}, x) // y
Base.://(x::QuadraticExtension{T}, y::Real) where T<:qe_suppT = x // convert(QuadraticExtension{T}, y)

Base.:<=(x::QuadraticExtension{T}, y::QuadraticExtension{T}) where T<:qe_suppT = x < y || x == y
Base.:/(x::QuadraticExtension{T}, y::QuadraticExtension{T}) where T<:qe_suppT = x // y

# no-copy convert
convert(::Type{<:QuadraticExtension{T}}, qe::QuadraticExtension{T}) where T<:qe_suppT = qe

function convert(to::Type{<:Number}, qe::QuadraticExtension)
    !iszero(_b(qe)) && !iszero(_r(qe)) && throw(DomainError("Given QuadraticExtension not trivial."))
    return convert(to, _a(qe))
end

# compatibility with Float64
Float64(x::QuadraticExtension{T}) where T<:qe_suppT = Float64(_a(x)) + Float64(_b(x)) * sqrt(Float64(_r(x)))
Base.promote_rule(::Type{<:QuadraticExtension{Rational}}, ::Type{<:AbstractFloat}) = Float64

convert(to::Type{<:AbstractFloat}, qe::QuadraticExtension) = convert(to, Float64(qe))
