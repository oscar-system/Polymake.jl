const AbstractRational = Union{Base.Rational, Rational}

for (pm_solve_LP, scalarT, concreteT) in [
    (:direct_call_solve_LP, AbstractRational, Rational),
    (:direct_call_solve_LP_float, AbstractFloat, Float64),
    ]
    for (m, flag) in [(:min, false), (:max, true)]
        @eval begin
            function solve_LP(
                inequalities::AbstractMatrix{<:$scalarT},
                equalities::AbstractMatrix{<:$scalarT},
                objective::AbstractVector{<:$scalarT},
                sense::typeof($m))

                return $pm_solve_LP(
                    convert(Matrix{$concreteT}, inequalities),
                    convert(Matrix{$concreteT}, equalities),
                    convert(Vector{$concreteT}, objective),
                    $flag
                )
            end
        end
    end
end

solve_LP(inequalities::AbstractMatrix{T}, objective::AbstractVector; sense=max) where T = solve_LP(inequalities, Base.Matrix{T}(undef, 0, 0), objective, sense)

solve_LP(inequalities::AbstractMatrix, equalities::AbstractMatrix, objective::AbstractVector; sense=max) = solve_LP(inequalities, equalities, objective, sense)
