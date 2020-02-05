const Array_suppT = Union{Int64, CxxWrap.CxxLong,
                        Integer, Rational,
                        String, CxxWrap.StdString,
                        Set{Int64}, Set{CxxWrap.CxxLong},
                        Array{Int64}, Array{CxxWrap.CxxLong},
                        Array{Integer}, Matrix{Integer}}

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

Array{T}(n::Base.Integer, elt) where T<:Array_suppT = Array{T}(Int64(n), T(elt))
Array(n::Base.Integer, elt::T) where T = Array{T}(Int64(n), elt)

Array(vec::AbstractVector) = Array{convert_to_pm_type(eltype(vec))}(vec)

ArrayAllocated{T}(v) where T = Array{T}(v)

Base.size(a::Array) = (length(a),)
Base.eltype(v::Array{T}) where T = to_jl_type(T)

Base.@propagate_inbounds function getindex(A::Array, n::Base.Integer)
    @boundscheck 1 <= n <= length(A) || throw(BoundsError(A, n))
    return _getindex(A, convert(Int64, n))
end

Base.@propagate_inbounds function Base.setindex!(A::Array{T}, val, n::Base.Integer) where T
    @boundscheck 1 <= n <= length(A) || throw(BoundsError(A, n))
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

# workarounds for Array{String}
Array{T}(n::Base.Integer) where T<:AbstractString = Array{AbstractString}(Int64(n))
Array{T}(n::Base.Integer, elt::T) where T<:AbstractString =
Array{AbstractString}(Int64(n), elt)

Base.@propagate_inbounds function Base.setindex!(A::Array{S}, val, n::Base.Integer) where {S<:AbstractString}
    @boundscheck 1 <= n <= length(A) || throw(BoundsError(A, n))
    _setindex!(A, string(val), Int64(n))
    return A
end
