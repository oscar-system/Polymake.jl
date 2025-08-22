function Base.getindex(M::EdgeMap{TK, TV}, i::Int, j::Int) where {TK, TV}
  index = to_zero_based_indexing.([i, j])
  return convert(to_jl_type(TV), _get_entry(M, index...))
end

function Base.setindex!(M::EdgeMap{T, TV}, val, i::Int, j::Int) where {T, TV}
  index = to_zero_based_indexing.([i, j])
  _set_entry(M, index..., convert(to_cxx_type(TV), val))
  return val
end

function Base.getindex(M::EdgeMap{TK, TV}, index::NTuple{2, Int}) where {TK, TV}
  return convert(to_jl_type(TV), _get_entry(M, to_zero_based_indexing.(index)...))
end

function Base.setindex!(M::EdgeMap{TK, TV}, val, index::NTuple{2, Int}) where {TK, TV}
  index = to_zero_based_indexing.(index)
  _set_entry(M, index..., convert(to_cxx_type(TV), val))
  return val
end

function Base.getindex(M::NodeMap{TK, TV}, i::Int) where {TK, TV}
  return convert(to_jl_type(TV), _get_entry(M, to_zero_based_indexing(i)))
end

function Base.setindex!(M::NodeMap{TK, TV}, val, i::Int) where {TK, TV}
  _set_entry(M, to_zero_based_indexing(i), convert(to_cxx_type(TV), val))
  return val
end

function NodeMap{D,V}(g::Graph{D}, d::AbstractDict{Int,VV}) where D<:DirType where V where VV
   nm = NodeMap{D,V}(g)
   for (k,v) in d
      nm[k] = v
   end
   return nm
end
NodeMap(g::Graph{D}, d::AbstractDict{Int,V}) where D<:DirType where V = NodeMap{D,convert_to_pm_type(V)}(g, d)

function EdgeMap{D,V}(g::Graph{D}, d::AbstractDict{E,VV}) where D<:DirType where V where VV where E<:Union{<:Pair{Int,Int},NTuple{2,Int}}
   em = EdgeMap{D,V}(g)
   for (k,v) in d
      em[k] = v
   end
   return em
end
EdgeMap(g::Graph{D}, d::AbstractDict{E,V})  where D<:DirType where V where E<:Union{<:Pair{Int,Int},NTuple{2,Int}} = EdgeMap{D,convert_to_pm_type(V)}(g, d)
