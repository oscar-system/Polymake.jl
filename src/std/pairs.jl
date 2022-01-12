StdPair(a::T,b::T) where T = StdPair{T,T}(a,b)
StdPair(p::Pair) = StdPair(first(p), last(p))

Base.Pair(p::StdPair) = Pair(first(p), last(p))
Base.Pair{S, T}(p::StdPair) where {S, T} = Pair{S, T}(first(p), last(p))
Base.convert(::Type{<:Pair{T,S}}, p::StdPair) where {T,S} =
    Pair(T(first(p)), S(last(p)))

Base.length(p::StdPair) = 2
Base.eltype(p::StdPair{T,T}) where T = T
Base.iterate(p::StdPair) = first(p), Val{:first}()
Base.iterate(p::StdPair, ::Val{:first}) = last(p), Val{:last}()
Base.iterate(p::StdPair, ::Val{:last}) = nothing

Base.:(==)(p::Union{StdPair{S, T}, Pair{S, T}}, q::Union{StdPair{U, V}, Pair{U, V}}) where {S, T, U, V} = convert(Pair{S, T}, p) == convert(Pair{U, V}, q)
