const pm_TropicalNumber_suppAddition = Union{pm_Min, pm_Max}
const pm_TropicalNumber_suppScalar = Union{pm_Rational}

#convert input to supported Scalar type
pm_TropicalNumber{A,S}(scalar::Real) where {A <: pm_TropicalNumber_suppAddition, S <: pm_TropicalNumber_suppScalar} = pm_TropicalNumber{A,S}(convert(S,scalar))

#pm_Rational es default Scalar
pm_TropicalNumber{A}(scalar::Real) where A <: pm_TropicalNumber_suppAddition = pm_TropicalNumber{A,pm_Rational}(scalar)
pm_TropicalNumber{A}() where A <: pm_TropicalNumber_suppAddition = pm_TropicalNumber{A,pm_Rational}()

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

Base.zero(i::pm_TropicalNumber{A}) where A <: pm_TropicalNumber_suppAddition = pm_TropicalNumber{A}()
Base.zero(i::Type{<:pm_TropicalNumber{A}}) where A <: pm_TropicalNumber_suppAddition = pm_TropicalNumber{A}()
Base.one(i::pm_TropicalNumber{A}) where A <: pm_TropicalNumber_suppAddition = pm_TropicalNumber{A}(0)
Base.one(i::Type{<:pm_TropicalNumber{A}}) where A <: pm_TropicalNumber_suppAddition = pm_TropicalNumber{A}(0)
dual_zero(i::pm_TropicalNumber{pm_Min}) = zero(pm_TropicalNumber{pm_Max})
dual_zero(i::Type{<:pm_TropicalNumber{pm_Min}}) = zero(pm_TropicalNumber{pm_Max})
dual_zero(i::pm_TropicalNumber{pm_Max}) = zero(pm_TropicalNumber{pm_Min})
dual_zero(i::Type{<:pm_TropicalNumber{pm_Max}}) = zero(pm_TropicalNumber{pm_Min})
orientation(i::pm_TropicalNumber{pm_Min}) = pm_Integer(1)
orientation(i::Type{<:pm_TropicalNumber{pm_Min}}) = pm_Integer(1)
orientation(i::pm_TropicalNumber{pm_Max}) = pm_Integer(-1)
orientation(i::Type{<:pm_TropicalNumber{pm_Max}}) = pm_Integer(-1)

function Base.promote_rule(::Type{<:pm_TropicalNumber{A,S}}, ::Type{<:Union{Integer, Rational, pm_Integer, pm_Rational}}) where {A <: pm_TropicalNumber_suppAddition, S <: pm_TropicalNumber_suppScalar}
    return pm_TropicalNumber{A,S}
end

# convert(::Type{S}, tr::pm_TropicalNumber) where {T<:Number} = convert(T, BigInt(int))
