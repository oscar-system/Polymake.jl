const TropicalNumber_suppAddition = Union{Min, Max}
const TropicalNumber_suppScalar = Union{Rational}

#convert input to supported Scalar type
TropicalNumber{A,S}(scalar::Union{Real, TropicalNumber}) where {A <: TropicalNumber_suppAddition, S <: TropicalNumber_suppScalar} = TropicalNumber{A,S}(convert(S,scalar))

#Rational es default Scalar
TropicalNumber{A}(scalar::Union{Real, TropicalNumber}) where A = TropicalNumber{A,Rational}(scalar)
TropicalNumber{A}() where A = TropicalNumber{A, Rational}()

#polymake requires an explicit statement what kind of tropical number (i.e. min or max) we want to construct
TropicalNumber(x...) = throw(ArgumentError("TropicalNumber needs to be called with type parameter 'Max' or 'Min'."))
TropicalNumber(::TropicalNumber) = TropicalNumber()

# workaround for https://github.com/JuliaInterop/CxxWrap.jl/issues/199
for (jlF, pmF) in (
    (:(==), :_isequal),
    (:+, :_add),
    (:*, :_mul),
    )
    @eval begin
        function Base.$(jlF)(x::TropicalNumber{A,S}, y::TropicalNumber{A,S}) where {A,S}
            return $pmF(x, y)
        end
    end
end

function Base.:(==)(x::TropicalNumber{A,S},y::Real) where {A, S}
    return x == TropicalNumber{A,S}(y)
end

Base.:(==)(x::Real,y::TropicalNumber{A,S}) where {A, S} = (y == x)

#catch wrong typings for basic operations
Base.promote_rule(::Type{<:TropicalNumber{A, S1}}, ::Type{<:TropicalNumber{A, S2}}) where {A, S1, S2} = TropicalNumber{A, promote_type(S1,S2)}

for op in (:+, :*, ://, :<)
    @eval begin
        Base.$(op)(x::TropicalNumber{A, S}, y::TropicalNumber{A, T}) where {A,S,T} = $(op)(promote(x,y)...)
        Base.$(op)(x::TropicalNumber{A}, y::TropicalNumber{B}) where {A,B} =
            throw(DomainError((x,y), "The operation $(string($op)) for tropical numbers with $A and $B is not defined"))
    end
end

#at the moment we do not distinct between // and /, so / just refers to //
Base.:/(x::TropicalNumber, y::TropicalNumber) = x//y

#zero/one

Base.zero(::Type{<:TropicalNumber{A}}) where A = zero(TropicalNumber{A}())
Base.one(::Type{<:TropicalNumber{A}}) where A = one(TropicalNumber{A}())
dual_zero(::Type{<:TropicalNumber{A}}) where A = dual_zero(TropicalNumber{A}())
orientation(::TropicalNumber{Min}) = 1
orientation(::Type{<:TropicalNumber{Min}}) = 1
orientation(::TropicalNumber{Max}) = -1
orientation(::Type{<:TropicalNumber{Max}}) = -1

function TropicalNumber{A, S}(x::Float64) where {A <: TropicalNumber_suppAddition, S <: TropicalNumber_suppScalar}
    if isinf(x)
        if x * orientation(TropicalNumber{A}) > 0
            return zero(TropicalNumber{A, S})
        else
            return dual_zero(TropicalNumber{A, S})
        end
    else
        return TropicalNumber{A, S}(Rational(x))
    end
end

convert(::Type{T}, tr::TropicalNumber) where T<:Union{Base.Integer, Base.Rational, Integer, Rational} = convert(T, scalar(tr))
