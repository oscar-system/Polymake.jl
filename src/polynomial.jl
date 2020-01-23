@inline function pm_Polynomial{C,E}(vec::AbstractVector, mat::AbstractMatrix) where {C <: pm_VecOrMat_eltypes, E <: pm_VecOrMat_eltypes}
    pm_vec = pm_Vector{C}(vec)
    pm_mat = pm_Matrix{E}(mat)
    return pm_Polynomial{C,E}(pm_vec, pm_mat)
end

pm_Polynomial(vec::AbstractVector{C}, mat::AbstractMatrix{E}) where {C,E} = pm_Polynomial{promote_to_pm_type(pm_Vector,C),promote_to_pm_type(pm_Matrix,E)}(vec, mat)
pm_Polynomial{C}(vec::AbstractVector, mat::AbstractMatrix{E}) where {C <: pm_VecOrMat_eltypes ,E} = pm_Polynomial{C,promote_to_pm_type(pm_Matrix,E)}(vec, mat)

# pm_Polynomial{C}(vec::AbstractVector, mat::AbstractMatrix{E}) where {C <: pm_VecOrMat_eltypes, E <: Int32} = pm_Polynomial{C,Int32}(vec, mat)
# pm_Polynomial{C}(vec::AbstractVector, mat::AbstractMatrix{E}) where {C <: pm_VecOrMat_eltypes, E <: Integer} = pm_Polynomial{C,pm_Integer}(vec, mat)
# pm_Polynomial{C}(vec::AbstractVector, mat::AbstractMatrix{E}) where {C <: pm_VecOrMat_eltypes, E <: Union{Rational, pm_Rational}} = pm_Polynomial{C,pm_Rational}(vec, mat)
# pm_Polynomial{C}(vec::AbstractVector, mat::AbstractMatrix{E}) where {C <: pm_VecOrMat_eltypes, E <: AbstractFloat} = pm_Polynomial{C,Float64}(vec, mat)
#
# pm_Polynomial(vec::AbstractVector{C}, mat::AbstractMatrix) where {C <: Int32} = pm_Polynomial{Int32}(vec, mat)
# pm_Polynomial(vec::AbstractVector{C}, mat::AbstractMatrix) where {C <: Integer} = pm_Polynomial{Int32}(vec, mat)
# pm_Polynomial(vec::AbstractVector{C}, mat::AbstractMatrix) where {C <: Union{Rational, pm_Rational}} = pm_Polynomial{pm_Rational}(vec, mat)
# pm_Polynomial(vec::AbstractVector{C}, mat::AbstractMatrix) where {C <: AbstractFloat} = pm_Polynomial{Float64}(vec, mat)

set_var_names(p::pm_Polynomial, names::AbstractArray{S}) where {S <: AbstractString} = set_var_names(p, pm_Array{String}(names))

Base.promote_rule(::Type{<:pm_Polynomial{C1,E1}}, ::Type{<:pm_Polynomial{C2,E2}}) where {C1,C2,E1,E2} = pm_Polynomial{promote_type(C1,C2),promote_type(E1,E2)}
