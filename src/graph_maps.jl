function Base.getindex(M::EdgeMap{TK, TV}, i::Int, j::Int) where {TK, TV}
  index = to_zero_based_indexing.([i, j])
  return convert(to_jl_type(TV), _get_entry(M, index...))
end

function Base.setindex!(M::EdgeMap{T, TV}, i::Int, j::Int, val) where {T, TV}
  index = to_zero_based_indexing.([i, j])
  _set_entry(M, index..., val)
  return val
end

function Base.getindex(M::EdgeMap{TK, TV}, index::NTuple{2, Int}) where {TK, TV}
  return convert(to_jl_type(TV), _get_entry(M, to_zero_based_indexing.(index)...))
end

function Base.setindex!(M::EdgeMap{TK, TV}, index::NTuple{2, Int}, val) where {TK, TV}
  index = to_zero_based_indexing.(index)
  _set_entry(M, index..., val)
  return val
end

function Base.getindex(M::NodeMap{TK, TV}, i::Int) where {TK, TV}
  return convert(to_jl_type(TV), _get_entry(M, to_zero_based_indexing(i)))
end

function Base.setindex!(M::NodeMap{TK, TV}, i::Int, val) where {TK, TV}
  _set_entry(M, to_zero_based_indexing(i), val)
  return val
end
