import Base: convert, show

const give = Polymake.give

function cube(dim)
    return Polymake.call_func_1args("cube",dim)
end

function cross(dim)
    return Polymake.call_func_1args("cross",dim)
end

function rand_sphere(n,d)
    return Polymake.call_func_2args("rand_sphere",n,d)
end

function upper_bound_theorem(n,d)
    return Polymake.call_func_2args("upper_bound_theorem",n,d)
end


convert_to_pm(x::T) where T <:Integer = Base.convert(Polymake.pm_Integer,x)

convert_to_pm(x::Rational{T}) where T <:Integer = Base.convert(Polymake.pm_Rational,x)

convert_to_pm(x::Array{T,2}) where T <:Integer = Base.convert(Polymake.pm_Matrix{Polymake.pm_Integer},x)

convert_to_pm(x::Array{Rational{T},2}) where T <:Integer = Base.convert(Polymake.pm_Matrix{Polymake.pm_Rational},x)

function perlobj(name::String,input_data::Dict{String,T}) where T
    polytope = Polymake.pm_perl_Object(name)
    for value in input_data
        key = value[1]
        val = convert_to_pm(value[2])
        Polymake.take(polytope,key,val)
    end
    return polytope
end