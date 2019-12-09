const pm_TropicalNumber_suppAddition = Union{pm_Min, pm_Max}
const pm_TropicalNumber_suppScalar = Union{pm_Integer, pm_Rational}

#convert input to supported Scalar type
pm_TropicalNumber{T1,T2}(scalar::Number) where {T1 <: pm_TropicalNumber_suppAddition, T2 <: pm_TropicalNumber_suppScalar} = pm_TropicalNumber{T1,T2}(convert(T2,scalar))

#pm_Rational es default Scalar
pm_TropicalNumber{T1}(scalar::Number) where T1 <: pm_TropicalNumber_suppAddition = pm_TropicalNumber{T1,pm_Rational}(convert(pm_Rational,scalar))
pm_TropicalNumber{T1}() where T1 <: pm_TropicalNumber_suppAddition = pm_TropicalNumber{T1,pm_Rational}()
