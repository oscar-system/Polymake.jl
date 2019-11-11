const AbstractRational = Union{Rational, pm_Rational}

for (m, flag) in [(:min, false), (:max, true)]
    @eval begin
        function solve_LP(
            inequalities::AbstractMatrix{<:AbstractRational},
            equalities::AbstractMatrix{<:AbstractRational},
            objective::AbstractVector{<:AbstractRational}, ::typeof($m))

            return direct_call_solve_LP(
                convert(pm_Matrix{pm_Rational}, inequalities),
                convert(pm_Matrix{pm_Rational}, equalities),
                convert(pm_Vector{pm_Rational}, objective),
                $flag
            )
        end

        function solve_LP(
            inequalities::AbstractMatrix{<:AbstractFloat},
            equalities::AbstractMatrix{<:AbstractFloat},
            objective::AbstractVector{<:AbstractFloat}, ::typeof($m))

            return direct_call_solve_LP_float(
                convert(pm_Matrix{Float64}, inequalities),
                convert(pm_Matrix{Float64}, equalities),
                convert(pm_Vector{Float64}, objective),
                $flag
            )
        end
    end
end

solve_LP(inequalities::AbstractMatrix{T}, objective::AbstractVector; sense=max) where T = solve_LP(inequalities, Matrix{T}(undef, 0, 0), objective, sense)

solve_LP(inequalities::AbstractMatrix, equalities::AbstractMatrix, objective::AbstractVector; sense=max) = solve_LP(inequalities, equalities, objective, sense)
