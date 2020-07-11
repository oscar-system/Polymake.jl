function Map{String,String}()
    return Map{to_cxx_type(String),to_cxx_type(String)}()
end

function Base.getindex(M::Map{TV, TK}, key) where {TV, TK}
    return convert(to_jl_type(TV), _getindex(M, convert(to_cxx_type(String), key)))
end

function Base.setindex!(M::Map{TV, TK}, val, key::AbstractString) where {TV, TK}
    _setindex!(M, convert(TV, val), convert(TK, key))
    return val
end
