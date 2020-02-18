function Polynomial{C,E}(coefficients::AbstractVector, exponents::AbstractMatrix) where {C <: VecOrMat_eltypes, E <: Union{CxxWrap.CxxLong, Int64}}
    v = convert(Vector{C}, coefficients)
    m = convert(Matrix{E}, exponents)
    return Polynomial{to_cxx_type(C),to_cxx_type(E)}(v, m)
end

function Polynomial{C,E}(p::Polynomial) where {C,E}
    v = coefficients_as_vector(p)
    m = monomials_as_matrix(p)
    return Polynomial{C,E}(v, m)
end

function Polynomial{C,E}(c::Number, nvars::Base.Integer) where {C,E}
    m = Matrix{E}(undef,1,nvars)
    return Polynomial{C,E}([c],m)
end

# deriving template type from input
Polynomial(vec::AbstractVector{C}, mat::AbstractMatrix{E}) where {C,E} =
    Polynomial{promote_to_pm_type(Vector,C),promote_to_pm_type(Matrix,E)}(vec, mat)
Polynomial{C}(vec::AbstractVector, mat::AbstractMatrix{E}) where {C,E} =
    Polynomial{C,promote_to_pm_type(Matrix,E)}(vec, mat)

# defaulting to {Rational,Int64}
Polynomial(x...) = Polynomial{Rational,Int64}(x)
Polynomial{C}(x...) where C = Polynomial{C,Int64}(x)

set_var_names(p::Polynomial, names::AbstractArray{S}) where {S <: AbstractString} =
    set_var_names(p, Array{String}(names))

Base.promote_rule(::Type{<:Polynomial{C1,E1}}, ::Type{<:Polynomial{C2,E2}}) where {C1,C2,E1,E2} =
    Polynomial{Base.promote_type(to_jl_type(C1),to_jl_type(C2)),Base.promote_type(to_jl_type(E1),to_jl_type(E2))}

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
        function Base.$(jlF)(p::Polynomial{C,E}, q::Polynomial{C,E}) where {C,E}
            return $pmF(p, q)
        end
        function Base.$(jlF)(p::Polynomial, q::Polynomial)
            return $(jlF)(promote(p,q)...)
        end
        function Base.$(jlF)(p::Number, q::Polynomial{C,E}) where {C,E}
            return $(jlF)(Polynomial{C,E}(p,size(monomials_as_matrix(q),2)),q)
        end
        function Base.$(jlF)(p::Polynomial{C,E}, q::Number) where {C,E}
            return $(jlF)(p,Polynomial{C,E}(q,size(monomials_as_matrix(p),2)))
        end
    end
end

Base.:/(p::Polynomial{C}, d::Number) where C = p / C(d)

Base.:-(p::Polynomial{C,E}) where {C,E} = Polynomial{C,E}(-coefficients_as_vector(p), monomials_as_matrix(p))

Base.hash(p::Polymake.Polynomial, h::UInt) = hash(Polynomial, hash(coefficients_as_vector(p), hash(monomials_as_matrix(p), h)))
