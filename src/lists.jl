const List_suppT = Union{Std.Pair{CxxWrap.CxxLong, CxxWrap.CxxLong}}

### convert TO polymake object
StdList{T}() where T<:Set_suppT = StdList{to_cxx_type(T)}()

### julia functions for lists

# empty!  : Defined on the C++ side
Base.empty(l::StdList{T}, ::Type{U}=T) where {T, U} = StdList{to_cxx_type(U)}()

# push! : Defined on the C++ side
Base.push!(s::StdList{T}, p::StdPair{CxxWrap.CxxLong, CxxWrap.CxxLong}) where T = push!(s, T(p))

