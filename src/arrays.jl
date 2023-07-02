const Array_suppT = Union{Int64, CxxWrap.CxxLong,
                        Integer, Rational, QuadraticExtension{Rational},
                        OscarNumber,
                        String, CxxWrap.StdString,
                        StdPair{CxxWrap.CxxLong,CxxWrap.CxxLong},
                        StdList{StdPair{CxxWrap.CxxLong,CxxWrap.CxxLong}},
                        Set{Int64}, Set{CxxWrap.CxxLong},
                        Array{Int64}, Array{CxxWrap.CxxLong},
                        Array{Integer}, Array{Rational}, Matrix{Integer}}

function Array{T}(::UndefInitializer, n::Base.Integer) where
    T <: Array_suppT
    return Array{to_cxx_type(T)}(convert(Int64, n))
end

function Array{T}(n::Base.Integer, elt) where T <: Array_suppT
    S = to_cxx_type(T)
    return Array{S}(convert(Int64, n), convert(S, elt))
end

function Array{T}(vec::AbstractVector) where T
    arr = Array{T}(undef, length(vec))
    @inbounds arr .= vec
    return arr
end

Array(n::Base.Integer, elt::T) where T =
    Array{convert_to_pm_type(T)}(n, elt)

Array(vec::AbstractVector) =
    Array{convert_to_pm_type(eltype(vec))}(vec)

Base.size(a::Array) = (length(a),)
Base.eltype(v::Array{T}) where T = to_jl_type(T)

Base.@propagate_inbounds function getindex(A::Array{T}, n::Base.Integer) where T
    @boundscheck checkbounds(A, n)
    return convert(to_jl_type(T), _getindex(A, convert(Int64, n)))
end

Base.@propagate_inbounds function Base.setindex!(A::Array{T}, val, n::Base.Integer) where T
    @boundscheck checkbounds(A, n)
    _setindex!(A, convert(T, val), convert(Int64, n))
    return A
end

function Base.append!(A::Array{T}, itr) where T
    n = length(A)
    m = length(itr)
    resize!(A, n+m)
    for i in 1:m
        A[n+i] = itr[i]
    end
    return A
end
