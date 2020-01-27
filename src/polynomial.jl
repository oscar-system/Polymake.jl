@inline function Polynomial{C,E}(vec::AbstractVector, mat::AbstractMatrix) where {C <: VecOrMat_eltypes, E <: Int64}
    vec = Vector{C}(vec)
    mat = Matrix{E}(mat)
    return Polynomial{C,E}(vec, mat)
end

Polynomial(vec::AbstractVector{C}, mat::AbstractMatrix{E}) where {C,E} = Polynomial{promote_to_pm_type(Vector,C),Int64}(vec, mat)
Polynomial{C}(vec::AbstractVector, mat::AbstractMatrix{E}) where {C <: VecOrMat_eltypes,E} = Polynomial{C,promote_to_pm_type(Matrix,E)}(vec, mat)

# Polynomial{C}(vec::AbstractVector, mat::AbstractMatrix{E}) where {C <: VecOrMat_eltypes, E <: Int32} = Polynomial{C,Int32}(vec, mat)
# Polynomial{C}(vec::AbstractVector, mat::AbstractMatrix{E}) where {C <: VecOrMat_eltypes, E <: Integer} = Polynomial{C,Integer}(vec, mat)
# Polynomial{C}(vec::AbstractVector, mat::AbstractMatrix{E}) where {C <: VecOrMat_eltypes, E <: Union{Rational, Rational}} = Polynomial{C,Rational}(vec, mat)
# Polynomial{C}(vec::AbstractVector, mat::AbstractMatrix{E}) where {C <: VecOrMat_eltypes, E <: AbstractFloat} = Polynomial{C,Float64}(vec, mat)
#
# Polynomial(vec::AbstractVector{C}, mat::AbstractMatrix) where {C <: Int32} = Polynomial{Int32}(vec, mat)
# Polynomial(vec::AbstractVector{C}, mat::AbstractMatrix) where {C <: Integer} = Polynomial{Int32}(vec, mat)
# Polynomial(vec::AbstractVector{C}, mat::AbstractMatrix) where {C <: Union{Rational, Rational}} = Polynomial{Rational}(vec, mat)
# Polynomial(vec::AbstractVector{C}, mat::AbstractMatrix) where {C <: AbstractFloat} = Polynomial{Float64}(vec, mat)

set_var_names(p::Polynomial, names::AbstractArray{S}) where {S <: AbstractString} = set_var_names(p, Array{String}(names))

Base.promote_rule(::Type{<:Polynomial{C1,E1}}, ::Type{<:Polynomial{C2,E2}}) where {C1,C2,E1,E2} = Polynomial{promote_type(C1,C2),promote_type(E1,E2)}
