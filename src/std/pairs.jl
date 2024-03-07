StdPair(a::T,b::T) where T = StdPair{T,T}(a,b)
StdPair(p::Pair) = StdPair(first(p), last(p))
StdPair(t::Tuple{A,B}) where {A,B} = StdPair{A,B}(first(t),last(t))

Base.convert(::Type{<:StdPair{A,B}}, t::Tuple{C,D}) where {A,B,C,D} = StdPair{A,B}(A(first(t)), B(last(t)))

Base.Pair(p::StdPair) = Pair(first(p), last(p))
Base.Pair{S, T}(p::StdPair) where {S, T} = Pair{S, T}(first(p), last(p))

Base.length(p::StdPair) = 2
Base.eltype(p::StdPair{S,T}) where {S, T} = Union{S,T}
Base.iterate(p::StdPair) = first(p), Val{:first}()
Base.iterate(p::StdPair, ::Val{:first}) = last(p), Val{:last}()
Base.iterate(p::StdPair, ::Val{:last}) = nothing

Base.:(==)(p::StdPair{S, T}, q::Union{StdPair{U, V}, Pair{U, V}}) where {S, T, U, V} = Pair(first(p), last(p)) == Pair(first(q), last(q))
Base.:(==)(p::Pair, q::StdPair{S, T}) where {S, T} = p == Pair(first(q), last(q))
