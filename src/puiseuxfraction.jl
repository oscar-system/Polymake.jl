function PuiseuxFraction{M,Rational,Rational}(num::Number=Rational(0)) where {M <: TropicalNumber_suppAddition}
   return PuiseuxFraction{M,Rational,Rational}(Rational(num))
end

PuiseuxFraction{M}(x...) where M = PuiseuxFraction{M,Rational,Rational}(x...)

set_var_names(p::PuiseuxFraction, names::AbstractArray{S}) where {S <: AbstractString} =
    set_var_names(p, Array{String}(names))

Base.:(^)(x::PuiseuxFraction{M,<:Rational,<:Rational}, i::Base.Integer) where {M<:TropicalNumber_suppAddition} = PuiseuxFraction{M}(numerator(x)^i, denominator(x)^i)
Base.:(==)(x::Number, y::PuiseuxFraction) = Rational(x) == y
Base.:(==)(x::PuiseuxFraction, y::Number) = x == Rational(y)
Base.:<(x::Number, y::PuiseuxFraction) = Rational(x) < y
Base.:<(x::PuiseuxFraction, y::Number) = x < Rational(y)
Base.:+(x::Number, y::PuiseuxFraction) = Rational(x) + y
Base.:+(x::PuiseuxFraction, y::Number) = x + Rational(y)
Base.:-(x::Number, y::PuiseuxFraction) = Rational(x) - y
Base.:-(x::PuiseuxFraction, y::Number) = x - Rational(y)
Base.:*(x::Number, y::PuiseuxFraction) = Rational(x) * y
Base.:*(x::PuiseuxFraction, y::Number) = x * Rational(y)
Base.:/(x::Number, y::PuiseuxFraction) = Rational(x) // y
Base.:/(x::PuiseuxFraction, y::Number) = x // Rational(y)
Base.://(x::Rational, y::PuiseuxFraction{M,<:Rational,<:Rational}) where {M<:TropicalNumber_suppAddition} = PuiseuxFraction{M}(x) // y
Base.://(x::PuiseuxFraction{M,<:Rational,<:Rational}, y::Rational) where {M<:TropicalNumber_suppAddition} = x // PuiseuxFraction{M}(y)

Base.hash(p::Polymake.PuiseuxFraction{M,C,E}, h::UInt) where {M,C,E} = hash(M, hash(get_hash(p), h))
