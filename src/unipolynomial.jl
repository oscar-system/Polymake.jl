function UniPolynomial{C,E}(coefficients::AbstractVector, exponents::AbstractVector) where {C <: VecOrMat_eltypes, E <: Union{CxxWrap.CxxLong, Int64, Polymake.Rational}}
    v = convert(Vector{C}, coefficients)
    m = convert(Vector{E}, exponents)
    return UniPolynomial{to_cxx_type(C),to_cxx_type(E)}(v, m)
end

function UniPolynomial{C,E}(p::UniPolynomial) where {C,E}
    v = coefficients_as_vector(p)
    m = monomials_as_vector(p)
    return UniPolynomial{C,E}(v, m)
end

function UniPolynomial{C,E}(c::Number) where {C,E}
   return UniPolynomial{C,E}(C[c], E[0])
end
function UniPolynomial{C,E}() where {C,E}
   return UniPolynomial{C,E}(0)
end

# deriving template type from input
UniPolynomial(c::AbstractVector{C}, e::AbstractVector{E}) where {C,E} =
    UniPolynomial{promote_to_pm_type(Vector,C),promote_to_pm_type(Vector,E)}(c, e)
UniPolynomial{C}(c::AbstractVector, e::AbstractVector{E}) where {C,E} =
    UniPolynomial{C,promote_to_pm_type(Vector,E)}(c, e)

# defaulting to {Rational,Int64}
UniPolynomial(x...) = UniPolynomial{Rational,Int64}(x)
UniPolynomial{C}(x...) where C = UniPolynomial{C,Int64}(x)

set_var_names(p::UniPolynomial, names::AbstractArray{S}) where {S <: AbstractString} =
    set_var_names(p, Array{String}(names))

Base.promote_rule(::Type{<:UniPolynomial{C1,E1}}, ::Type{<:UniPolynomial{C2,E2}}) where {C1,C2,E1,E2} =
    UniPolynomial{Base.promote_type(to_jl_type(C1),to_jl_type(C2)),Base.promote_type(to_jl_type(E1),to_jl_type(E2))}

# first function in eval block: workaround for https://github.com/JuliaInterop/CxxWrap.jl/issues/199
# pmF only needed in that context
# jlF and other methods also needed for compatibility between polynomials and (polynomials or numbers)
for (jlF,pmF) in (
    (:(==), :_isequal),
    (:+, :_add),
    (:-, :_sub),
    (:*, :_mul),
    )
    @eval begin
        function Base.$(jlF)(p::UniPolynomial{C,E}, q::UniPolynomial{C,E}) where {C,E}
            return $pmF(p, q)
        end
        function Base.$(jlF)(p::UniPolynomial, q::UniPolynomial)
            return $(jlF)(promote(p,q)...)
        end
        function Base.$(jlF)(p::Number, q::UniPolynomial{C,E}) where {C,E}
           return $(jlF)(UniPolynomial{C,E}(p),q)
        end
        function Base.$(jlF)(p::UniPolynomial{C,E}, q::Number) where {C,E}
            return $(jlF)(p,UniPolynomial{C,E}(q))
        end
    end
end

Base.:/(p::UniPolynomial{C}, d::Number) where C = p / C(d)

Base.:-(p::UniPolynomial{C,E}) where {C,E} = UniPolynomial{C,E}(-coefficients_as_vector(p), monomials_as_vector(p))

Base.hash(p::Polymake.UniPolynomial, h::UInt) = hash(UniPolynomial, hash(coefficients_as_vector(p), hash(monomials_as_vector(p), h)))
