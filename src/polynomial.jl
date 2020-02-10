# function Polynomial{C,E}(vec::AbstractVector, mat::AbstractMatrix) where {C <: Union{CxxWrap.CxxLong,VecOrMat_eltypes}, E <: Union{CxxWrap.CxxLong, Int64}}
#     v = Vector{C}(vec)
#     m = Matrix{E}(mat)
#     return Polynomial{to_cxx_type(C),to_cxx_type(E)}(v, m)
# end
#
# function Polynomial{C,E}(p::Polynomial) where {C,E}
#     v = coefficients_as_vector(p)
#     m = monomials_as_matrix(p)
#     return Polynomial{C,E}(v, m)
# end
#
# function Polynomial{C,E}(n::Number, d::Base.Integer) where {C,E}
#     m = zeros(1,d)
#     return Polynomial{C,E}([n],m)
# end
#
# Polynomial(vec::AbstractVector{C}, mat::AbstractMatrix{E}) where {C,E} = Polynomial{promote_to_pm_type(Vector,C),Int64}(vec, mat)
# Polynomial{C}(vec::AbstractVector, mat::AbstractMatrix{E}) where {C <: VecOrMat_eltypes,E} = Polynomial{C,promote_to_pm_type(Matrix,E)}(vec, mat)
#
# set_var_names(p::Polynomial, names::AbstractArray{S}) where {S <: AbstractString} = set_var_names(p, Array{String}(names))
#
# Base.promote_rule(::Type{<:Polynomial{C1,E1}}, ::Type{<:Polynomial{C2,E2}}) where {C1,C2,E1,E2} = Polynomial{Base.promote_type(C1,C2),Base.promote_type(E1,E2)}
#
# for op in (:+, :-, :*, :(==))
#     @eval begin
#         function Base.$(op)(p::Polynomial, q::Polynomial)
#             return $(op)(promote(p,q)...)
#         end
#         function Base.$(op)(p::Number, q::Polynomial{C,E}) where {C,E}
#             return $(op)(Polynomial{C,E}(p,(size(monomials_as_matrix(q)))[2]),q)
#         end
#         function Base.$(op)(p::Polynomial{C,E}, q::Number) where {C,E}
#             return $(op)(p,Polynomial{C,E}(q,(size(monomials_as_matrix(p)))[2]))
#         end
#     end
# end
#
# Base.:^(p::Polynomial, i::Integer) = p^(Int64(i))
#
# Base.:/(p::Polynomial{C}, d::Number) where C = p / C(d)
#
# Base.:-(p::Polynomial) = 0 - p
#
# Base.hash(p::Polymake.Polynomial, h::UInt) = hash(Polynomial, hash(coefficients_as_vector(p),h))
#
# function nvars(p::Polynomial)
#     return size(monomials_as_matrix(p))[2]
# end
