const pm_TropicalNumber_suppAddition = Union{pm_Min, pm_Max}
const pm_TropicalNumber_suppScalar = Union{pm_Rational}

#convert input to supported Scalar type
pm_TropicalNumber{A,S}(scalar::Real) where {A <: pm_TropicalNumber_suppAddition, S <: pm_TropicalNumber_suppScalar} = pm_TropicalNumber{A,S}(convert(S,scalar))

#pm_Rational es default Scalar
pm_TropicalNumber{A}(scalar::Real) where A <: pm_TropicalNumber_suppAddition = pm_TropicalNumber{A,pm_Rational}(scalar)
pm_TropicalNumber{A}() where A <: pm_TropicalNumber_suppAddition = pm_TropicalNumber{A,pm_Rational}()

function Base.:(==)(x::pm_TropicalNumber{A,S},y::Real) where {A <: pm_TropicalNumber_suppAddition, S <: pm_TropicalNumber_suppScalar}
    return x == pm_TropicalNumber{A,S}(y)
end

Base.:(==)(x::Real,y::pm_TropicalNumber{A,S}) where {A <: pm_TropicalNumber_suppAddition, S <: pm_TropicalNumber_suppScalar} = (y == x)

#catch wrong typings for basic operations
function Base.:+(x::pm_TropicalNumber{A1,S1},y::pm_TropicalNumber{A2,S2}) where {A1,A2 <: pm_TropicalNumber_suppAddition, S1,S2 <: pm_TropicalNumber_suppScalar}
    throw(ArgumentError("addition of two instances of pm_TropicalNumber only allowed when both parameter types match"))
end

function Base.:*(x::pm_TropicalNumber{A1,S1},y::pm_TropicalNumber{A2,S2}) where {A1,A2 <: pm_TropicalNumber_suppAddition, S1,S2 <: pm_TropicalNumber_suppScalar}
    throw(ArgumentError("multiplication of two instances of pm_TropicalNumber only allowed when both parameter types match"))
end

function Base.://(x::pm_TropicalNumber{A1,S1},y::pm_TropicalNumber{A2,S2}) where {A1,A2 <: pm_TropicalNumber_suppAddition, S1,S2 <: pm_TropicalNumber_suppScalar}
    throw(ArgumentError("division of two instances of pm_TropicalNumber only allowed when both parameter types match"))
end

Base.:/(x::pm_TropicalNumber{A1,S}, y::pm_TropicalNumber{A2, S}) where{A1, A2, S <: Union{pm_Integer, pm_Rational}} = x//y

function Base.:<(x::pm_TropicalNumber{A1,S1},y::pm_TropicalNumber{A2,S2}) where {A1,A2 <: pm_TropicalNumber_suppAddition, S1,S2 <: pm_TropicalNumber_suppScalar}
    throw(ArgumentError("comparison of two instances of pm_TropicalNumber only allowed when both parameter types match"))
end

#zero/one

Base.zero(i::Type{<:pm_TropicalNumber{A}}) where A <: pm_TropicalNumber_suppAddition = zero(pm_TropicalNumber{A}())
Base.one(i::Type{<:pm_TropicalNumber{A}}) where A <: pm_TropicalNumber_suppAddition = one(pm_TropicalNumber{A}())
dual_zero(i::Type{<:pm_TropicalNumber{A}}) where A <: pm_TropicalNumber_suppAddition = dual_zero(pm_TropicalNumber{A}())
orientation(i::pm_TropicalNumber{pm_Min}) = pm_Integer(1)
orientation(i::Type{<:pm_TropicalNumber{pm_Min}}) = pm_Integer(1)
orientation(i::pm_TropicalNumber{pm_Max}) = pm_Integer(-1)
orientation(i::Type{<:pm_TropicalNumber{pm_Max}}) = pm_Integer(-1)

function pm_TropicalNumber{pm_Min, pm_Rational}(x::Float64)
    if isinf(x)
        if x > 0
            return zero(pm_TropicalNumber{pm_Min}())
        else
            return dual_zero(pm_TropicalNumber{pm_Min})
        end
    else
        return pm_TropicalNumber{pm_Min}(pm_Rational(x))
    end
end

function pm_TropicalNumber{pm_Max, pm_Rational}(x::Float64)
    if isinf(x)
        if x < 0
            return zero(pm_TropicalNumber{pm_Max}())
        else
            return dual_zero(pm_TropicalNumber{pm_Max})
        end
    else
        return pm_TropicalNumber{pm_Max}(pm_Rational(x))
    end
end

convert(::Type{T}, tr::pm_TropicalNumber) where T<:Union{Integer, Rational, pm_Integer, pm_Rational} = convert(T, scalar(tr))
