const pm_TropicalNumber_suppAddition = Union{pm_Min, pm_Max}
const pm_TropicalNumber_suppScalar = Union{pm_Rational}

#convert input to supported Scalar type
pm_TropicalNumber{A,S}(scalar::Union{Real, pm_TropicalNumber}) where {A <: pm_TropicalNumber_suppAddition, S <: pm_TropicalNumber_suppScalar} = pm_TropicalNumber{A,S}(convert(S,scalar))

#pm_Rational es default Scalar
pm_TropicalNumber{A}(scalar::Union{Real, pm_TropicalNumber}) where A = pm_TropicalNumber{A,pm_Rational}(scalar)
pm_TropicalNumber{A}() where A = pm_TropicalNumber{A, pm_Rational}()

#polymake requires an explicit statement what kind of tropical number (i.e. min or max) we want to construct
pm_TropicalNumber(x...) = throw(ArgumentError("pm_TropicalNumber needs to be called with type parameter 'pm_Max' or 'pm_Min'."))
pm_TropicalNumber(::pm_TropicalNumber) = pm_TropicalNumber()

function Base.:(==)(x::pm_TropicalNumber{A,S},y::Real) where {A, S}
    return x == pm_TropicalNumber{A,S}(y)
end

Base.:(==)(x::Real,y::pm_TropicalNumber{A,S}) where {A, S} = (y == x)

#catch wrong typings for basic operations
Base.promote_rule(::Type{<:pm_TropicalNumber{A, S1}}, ::Type{<:pm_TropicalNumber{A, S2}}) where {A, S1, S2} = pm_TropicalNumber{A, promote_type(S1,S2)}

for op in (:+, :*, ://, :<)
    @eval begin
        Base.$(op)(x::pm_TropicalNumber{A, S}, y::pm_TropicalNumber{A, T}) where {A,S,T} = $(op)(promote(x,y)...)
        Base.$(op)(x::pm_TropicalNumber{A}, y::pm_TropicalNumber{B}) where {A,B} =
            throw(DomainError((x,y), "The operation $(string($op)) for tropical numbers with $A and $B is not defined"))
    end
end

#at the moment we do not distinct between // and /, so / just refers to //
Base.:/(x::pm_TropicalNumber, y::pm_TropicalNumber) = x//y

#zero/one

Base.zero(::Type{<:pm_TropicalNumber{A}}) where A = zero(pm_TropicalNumber{A}())
Base.one(::Type{<:pm_TropicalNumber{A}}) where A = one(pm_TropicalNumber{A}())
dual_zero(::Type{<:pm_TropicalNumber{A}}) where A = dual_zero(pm_TropicalNumber{A}())
orientation(::pm_TropicalNumber{pm_Min}) = 1
orientation(::Type{<:pm_TropicalNumber{pm_Min}}) = 1
orientation(::pm_TropicalNumber{pm_Max}) = -1
orientation(::Type{<:pm_TropicalNumber{pm_Max}}) = -1

function pm_TropicalNumber{A, S}(x::Float64) where {A <: pm_TropicalNumber_suppAddition, S <: pm_TropicalNumber_suppScalar}
    if isinf(x)
        if x * orientation(pm_TropicalNumber{A}) > 0
            return zero(pm_TropicalNumber{A, S})
        else
            return dual_zero(pm_TropicalNumber{A, S})
        end
    else
        return pm_TropicalNumber{A, S}(pm_Rational(x))
    end
end

convert(::Type{T}, tr::pm_TropicalNumber) where T<:Union{Integer, Rational, pm_Integer, pm_Rational} = convert(T, scalar(tr))
