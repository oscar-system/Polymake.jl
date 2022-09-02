function Base.promote_rule(::Type{<:JuliaFieldElement},
    ::Type{<:Union{Integer, Rational, Base.Integer, Base.Rational{<:Base.Integer}}})
    return JuliaFieldElement
end

JuliaFieldElement(a::Union{Integer, Rational, Base.Integer, Base.Rational{<:Base.Integer}}) = JuliaFieldElement(Rational(a))

Base.zero(::Type{<:JuliaFieldElement}) = JuliaFieldElement(0)
Base.zero(::JuliaFieldElement) = JuliaFieldElement(0)
Base.one(::Type{<:JuliaFieldElement}) = JuliaFieldElement(1)
Base.one(::JuliaFieldElement) = JuliaFieldElement(1)
Base.sign(e::JuliaFieldElement) = JuliaFieldElement(_sign(e))

import Base: <, //, <=
# defining for `Real` to avoid disambiguities
#Base.:<(x::Real, y::JuliaFieldElement) = convert(JuliaFieldElement, x) < y
#Base.:<(x::JuliaFieldElement, y::Real) = x < convert(JuliaFieldElement, y)
#Base.://(x::Real, y::JuliaFieldElement) = convert(JuliaFieldElement, x) // y
#Base.://(x::JuliaFieldElement, y::Real) = x // convert(JuliaFieldElement, y)

Base.:<=(x::JuliaFieldElement, y::JuliaFieldElement) = x < y || x == y
Base.:/(x::JuliaFieldElement, y::JuliaFieldElement) = x // y

# no-copy convert
convert(::Type{<:JuliaFieldElement}, jfe::JuliaFieldElement) = jfe

mutable struct julia_field_dispatch_helper
    index::Clong
    init::Ptr{Cvoid}
    init_from_mpz::Ptr{Cvoid}
    copy::Ptr{Cvoid}
    gc_protect::Ptr{Cvoid}
    gc_free::Ptr{Cvoid}
    add::Ptr{Cvoid}
    sub::Ptr{Cvoid}
    mul::Ptr{Cvoid}
    div::Ptr{Cvoid}
    pow::Ptr{Cvoid}
    negate::Ptr{Cvoid}
    cmp::Ptr{Cvoid}
    to_string::Ptr{Cvoid}
    from_string::Ptr{Cvoid}
    is_zero::Ptr{Cvoid}
    is_one::Ptr{Cvoid}
    is_inf::Ptr{Cvoid}
    sign::Ptr{Cvoid}
    abs::Ptr{Cvoid}
end
julia_field_dispatch_helper() = julia_field_dispatch_helper(-1, repeat([C_NULL], 19)...)

#mutable struct jl_pm_type_map{T}
#   index::Int
#   gc::Dict{T,Int}
#end

_jfe_gc_refs = IdDict()

field_count = 0

# mapping parent -> (id, element, dispatch)
_jfe_dispatch_helper = Dict{Any, Tuple{Clong, julia_field_dispatch_helper}}()
_jfe_parent_by_id = Dict{Clong, Any}()

@generated _jfe_gen_add(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.:+, Ref{ArgT}, (Ref{ArgT}, Ref{ArgT}))
   end
@generated _jfe_gen_sub(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.:-, Ref{ArgT}, (Ref{ArgT}, Ref{ArgT}))
   end
@generated _jfe_gen_mul(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.:*, Ref{ArgT}, (Ref{ArgT}, Ref{ArgT}))
   end
@generated _jfe_gen_div(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.://, Ref{ArgT}, (Ref{ArgT}, Ref{ArgT}))
   end

@generated _jfe_gen_pow(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.:^, Ref{ArgT}, (Ref{ArgT}, Clong))
   end
@generated _jfe_gen_negate(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.:-, Ref{ArgT}, (Ref{ArgT},))
   end

function _jfe_abs_fallback(e::ArgT)::ArgT where ArgT
   return Base.cmp(e,0) < 0 ? -e : deepcopy(e)
end
@generated function _jfe_gen_abs(::Type{ArgT}) where ArgT
   if hasmethod(abs, (ArgT,))
      @info "abs using Base.abs"
      return quote
         @cfunction(Base.abs, Ref{ArgT}, (Ref{ArgT},))
      end
   else
      @info "abs using fallback"
      return quote
         @cfunction(_jfe_abs_fallback, Ref{ArgT}, (Ref{ArgT},))
      end
   end
end

@generated _jfe_gen_cmp(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.cmp, Clong, (Ref{ArgT}, Ref{ArgT}))
   end

@generated _jfe_gen_is_zero(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.iszero, Bool, (Ref{ArgT},))
   end
@generated _jfe_gen_is_one(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.isone, Bool, (Ref{ArgT},))
   end

_jfe_sign_int(e::T) where T = Base.cmp(e,0)
@generated _jfe_gen_sign_int(::Type{ArgT}) where ArgT =
   quote
      @cfunction(_jfe_sign_int, Clong, (Ref{ArgT},))
   end

# the Ptr arg in the following functions allows us to fix the return type
# from the @cfunction call
function _jfe_init(id::Clong, ::Ptr{ArgT}, i::Clong)::ArgT where ArgT
   #@info "init jfe $i"
   return _jfe_parent_by_id[id](i)
end
@generated _jfe_gen_init(::Type{ArgT}) where ArgT =
   quote
      @cfunction(_jfe_init, Ref{ArgT}, (Clong, Ptr{ArgT}, Clong))
   end

function _jfe_init_frac(id::Clong, ::Ptr{ArgT}, np::Ptr{BigInt}, dp::Ptr{BigInt})::ArgT where ArgT
   n = unsafe_load(np)::BigInt
   d = unsafe_load(dp)::BigInt
   #@info "init jfe frac $n // $d"
   #rat = Base.Rational{BigInt}(n, d)
   #@info "init jfe frac -> $rat $(typeof(rat))"
   #res = _jfe_parent_by_id[id](rat)
   #@info "init jfe frac -> -> $res $(typeof(res))"
   #return res::ArgT
   return _jfe_parent_by_id[id](Base.Rational{BigInt}(n, d))
end
@generated _jfe_gen_init_frac(::Type{ArgT}) where ArgT =
   quote
      @cfunction(_jfe_init_frac, Ref{ArgT}, (Clong, Ptr{ArgT}, Ptr{BigInt}, Ptr{BigInt}))
   end

function _jfe_copy(e::T)::T where T
   #@info "copy jfe $e"
   return deepcopy(e)
end
@generated _jfe_gen_copy(::Type{ArgT}) where ArgT =
   quote
      @cfunction(_jfe_copy, Ref{ArgT}, (Ref{ArgT},))
   end


function _jfe_gc_protect(x::T) where T
   if haskey(Polymake._jfe_gc_refs, x)
      @error "gc_protect: duplicate jfe $x : $(objectid(x))"
   end
   Polymake._jfe_gc_refs[x] = x
   return nothing
end
@generated _jfe_gen_gc_protect(::Type{ArgT}) where ArgT =
   quote
      @cfunction(_jfe_gc_protect, Cvoid, (Ref{ArgT},))
   end

function _jfe_gc_free(x::T) where T
   if !haskey(Polymake._jfe_gc_refs, x)
      @error "gc_free: invalid jfe $x : $(objectid(x))"
   end
   delete!(Polymake._jfe_gc_refs, x)
   return nothing
end
@generated _jfe_gen_gc_free(::Type{ArgT}) where ArgT =
   quote
      @cfunction(_jfe_gc_free, Cvoid, (Ref{ArgT},))
   end


#function _jfe_to_string(fp::Ptr{Nothing}, str::Ptr{Ptr{UInt8}})
#   f = unsafe_pointer_to_objref(fp)::jfe_t
#   @info "to_string jfe $(f) at $fp"
#   Base.unsafe_convert(Cstring,string(f))
#end

function JuliaFieldElement(e)
   id = register_julia_element(parent(e), typeof(e))
   #@info "copying $e from $(objectid(e)) in construction"
   return GC.@preserve e begin
      jfe = JuliaFieldElement(pointer_from_objref(e), id)
   end
   return jfe
end

function register_julia_element(p, t::Type)
   if haskey(_jfe_dispatch_helper, p)
      return _jfe_dispatch_helper[p][1]
   end
   global field_count+=1
   dispatch = julia_field_dispatch_helper()
   dispatch.index = field_count
   dispatch.init = _jfe_gen_init(t)
   dispatch.init_from_mpz = _jfe_gen_init_frac(t)
   dispatch.copy = _jfe_gen_copy(t)

   dispatch.gc_protect = _jfe_gen_gc_protect(t)
   dispatch.gc_free = _jfe_gen_gc_free(t)

   dispatch.add = _jfe_gen_add(t)
   dispatch.sub = _jfe_gen_sub(t)
   dispatch.mul = _jfe_gen_mul(t)
   dispatch.div = _jfe_gen_div(t)
   dispatch.pow = _jfe_gen_pow(t)

   dispatch.negate = _jfe_gen_negate(t)
   dispatch.abs    = _jfe_gen_abs(t)

   dispatch.is_zero = _jfe_gen_is_zero(t)
   dispatch.is_one  = _jfe_gen_is_one(t)
   dispatch.sign    = _jfe_gen_sign_int(t)

   dispatch.cmp = _jfe_gen_cmp(t)

   # to_string done on c++ side
   # to_string::Ptr{Cvoid}
   # TODO:
   # from_string::Ptr{Cvoid}

   # no inf value for nemo types ...
   #dispatch.is_inf  = _jfe_gen_is_inf(t)

   _register_julia_field(pointer_from_objref(dispatch), field_count)
   _jfe_dispatch_helper[p] = (field_count, dispatch)
   _jfe_parent_by_id[field_count] = p

   return field_count

end

