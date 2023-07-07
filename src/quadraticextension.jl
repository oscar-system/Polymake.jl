const qe_suppT = Union{Polymake.Rational}

QuadraticExtension{T}(a::Number, b::Number, r::Number) where T<:qe_suppT =
    QuadraticExtension{T}(convert(T, a), convert(T, b), convert(T, r))
    
QuadraticExtension{T}(a::Number) where T<:qe_suppT = QuadraticExtension{T}(a, 0, 0)
(::Type{<:QuadraticExtension{T}})(a::Number) where T<:qe_suppT = QuadraticExtension{T}(a, 0, 0)

QuadraticExtension(x...) = QuadraticExtension{Rational}(x...)
(::Type{<:QuadraticExtension})(x...) = QuadraticExtension{Rational}(x...)

# needed to avoid ambiguities
QuadraticExtension{T}(a::Integer) where T<:qe_suppT = QuadraticExtension{T}(a, 0, 0)
(::Type{<:QuadraticExtension{T}})(a::Integer) where T<:qe_suppT = QuadraticExtension{T}(a, 0, 0)
QuadraticExtension(x::Integer) = QuadraticExtension{Rational}(x)
QuadraticExtension{T}(a::Rational) where T<:qe_suppT = QuadraticExtension{T}(a, 0, 0)
(::Type{<:QuadraticExtension{T}})(a::Rational) where T<:qe_suppT = QuadraticExtension{T}(a, 0, 0)
QuadraticExtension(a::Rational) = QuadraticExtension{Rational}(a, 0, 0)

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
(::Type{<:QuadraticExtension{T}})(qe::QuadraticExtension{T}) where T<:qe_suppT = qe
(QuadraticExtension{T})(qe::QuadraticExtension{T}) where T<:qe_suppT = qe

function _qe_to_rational(::Type{T}, qe::QuadraticExtension) where T<:Number
    !iszero(_b(qe)) && !iszero(_r(qe)) && throw(DomainError("Given QuadraticExtension not trivial."))
    return convert(T, _a(qe))
end

# compatibility with Float64
Float64(x::QuadraticExtension{T}) where T<:qe_suppT = Float64(_a(x)) + Float64(_b(x)) * sqrt(Float64(_r(x)))
Base.promote_rule(::Type{<:QuadraticExtension{Rational}}, ::Type{<:AbstractFloat}) = Float64

(::Type{T})(qe::QuadraticExtension) where {T<:AbstractFloat} = convert(T, Float64(qe))

# avoid ambiguities
(::Type{<:Rational})(qe::QuadraticExtension) = _qe_to_rational(Rational,qe)
(::Type{<:Integer})(qe::QuadraticExtension) = _qe_to_rational(Integer,qe)
Rational(qe::QuadraticExtension) = _qe_to_rational(Rational,qe)
Integer(qe::QuadraticExtension) = _qe_to_rational(Integer,qe)
(::Type{T})(qe::QuadraticExtension) where {T<:Base.Integer} = _qe_to_rational(T,qe)
