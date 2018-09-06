
### convert TO polymake object

for (T, f) in [
    (Int32, :new_set_int32),
    (Int64, :new_set_int64),
    ]
    @eval begin
        function convert(::Type{Polymake.pm_Set}, v::Vector{$T})
            return Polymake.$f(v)
        end
    end
end

### convert FROM polymake object

function convert(::Type{Vector}, s::Polymake.pm_Set{T}) where T<:Integer
    return Vector{T}(s)
end

function convert(::Type{Vector{I}}, s::Polymake.pm_Set{J}) where {I,J<:Integer}
    return convert(Vector{I}, Vector(s))
end

for (T, f) in [
    (Int32, :fill_jlarray_int32_from_set32),
    (Int64, :fill_jlarray_int64_from_set64)
    ]
    @eval begin
        function convert(::Type{Vector{$T}}, s::Polymake.pm_Set{$T})
            v = Vector{$T}(length(s))
            Polymake.$f(v, s)
            return v
        end
    end
end
