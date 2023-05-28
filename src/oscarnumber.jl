function Base.promote_rule(::Type{<:OscarNumber},
    ::Type{<:Union{Integer, Rational, Base.Integer, Base.Rational{<:Base.Integer}}})
    return OscarNumber
end

OscarNumber(a::Union{Integer, Base.Integer, Base.Rational{<:Base.Integer}}) = OscarNumber(Rational(a))

Base.zero(::Type{<:OscarNumber}) = OscarNumber(0)
Base.zero(::OscarNumber) = OscarNumber(0)
Base.one(::Type{<:OscarNumber}) = OscarNumber(1)
Base.one(::OscarNumber) = OscarNumber(1)
Base.sign(e::OscarNumber) = OscarNumber(_sign(e))

import Base: <, //, <=
# defining for `Real` to avoid disambiguities
#Base.:<(x::Real, y::OscarNumber) = convert(OscarNumber, x) < y
#Base.:<(x::OscarNumber, y::Real) = x < convert(OscarNumber, y)
#Base.://(x::Real, y::OscarNumber) = convert(OscarNumber, x) // y
#Base.://(x::OscarNumber, y::Real) = x // convert(OscarNumber, y)

Base.:<=(x::OscarNumber, y::OscarNumber) = x < y || x == y
Base.:/(x::OscarNumber, y::OscarNumber) = x // y

# no-copy convert
convert(::Type{<:OscarNumber}, on::OscarNumber) = on

mutable struct oscar_number_dispatch_helper
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
oscar_number_dispatch_helper() = oscar_number_dispatch_helper(-1, repeat([C_NULL], 19)...)

#mutable struct jl_pm_type_map{T}
#   index::Int
#   gc::Dict{T,Int}
#end

_on_gc_refs = IdDict()

field_count = 0

# mapping parent -> (id, element, dispatch)
_on_dispatch_helper = Dict{Any, Tuple{Clong, oscar_number_dispatch_helper}}()
_on_parent_by_id = Dict{Clong, Any}()

@generated _on_gen_add(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.:+, Ref{ArgT}, (Ref{ArgT}, Ref{ArgT}))
   end
@generated _on_gen_sub(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.:-, Ref{ArgT}, (Ref{ArgT}, Ref{ArgT}))
   end
@generated _on_gen_mul(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.:*, Ref{ArgT}, (Ref{ArgT}, Ref{ArgT}))
   end
@generated _on_gen_div(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.://, Ref{ArgT}, (Ref{ArgT}, Ref{ArgT}))
   end

@generated _on_gen_pow(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.:^, Ref{ArgT}, (Ref{ArgT}, Clong))
   end
@generated _on_gen_negate(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.:-, Ref{ArgT}, (Ref{ArgT},))
   end

function _on_abs_fallback(e::ArgT)::ArgT where ArgT
   return Base.cmp(e,0) < 0 ? -e : deepcopy(e)
end
@generated function _on_gen_abs(::Type{ArgT}) where ArgT
   if hasmethod(abs, (ArgT,))
      @info "abs using Base.abs"
      return quote
         @cfunction(Base.abs, Ref{ArgT}, (Ref{ArgT},))
      end
   else
      @info "abs using fallback"
      return quote
         @cfunction(_on_abs_fallback, Ref{ArgT}, (Ref{ArgT},))
      end
   end
end

@generated _on_gen_cmp(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.cmp, Clong, (Ref{ArgT}, Ref{ArgT}))
   end

@generated _on_gen_is_zero(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.iszero, Bool, (Ref{ArgT},))
   end
@generated _on_gen_is_one(::Type{ArgT}) where ArgT =
   quote
      @cfunction(Base.isone, Bool, (Ref{ArgT},))
   end

_on_sign_int(e::T) where T = Base.cmp(e,0)::Int
@generated _on_gen_sign_int(::Type{ArgT}) where ArgT =
   quote
      @cfunction(_on_sign_int, Clong, (Ref{ArgT},))
   end

# the Ptr arg in the following functions allows us to fix the return type
# from the @cfunction call
function _on_init(id::Clong, ::Ptr{ArgT}, i::Clong)::ArgT where ArgT
   #@info "init on $i"
   return _on_parent_by_id[id](i)
end
@generated _on_gen_init(::Type{ArgT}) where ArgT =
   quote
      @cfunction(_on_init, Ref{ArgT}, (Clong, Ptr{ArgT}, Clong))
   end

function _on_init_frac(id::Clong, ::Ptr{ArgT}, np::Ptr{BigInt}, dp::Ptr{BigInt})::ArgT where ArgT
   n = unsafe_load(np)::BigInt
   d = unsafe_load(dp)::BigInt
   #@info "init on frac $n // $d"
   #rat = Base.Rational{BigInt}(n, d)
   #@info "init on frac -> $rat $(typeof(rat))"
   #res = _on_parent_by_id[id](rat)
   #@info "init on frac -> -> $res $(typeof(res))"
   #return res::ArgT
   return _on_parent_by_id[id](Base.Rational{BigInt}(n, d))
end
@generated _on_gen_init_frac(::Type{ArgT}) where ArgT =
   quote
      @cfunction(_on_init_frac, Ref{ArgT}, (Clong, Ptr{ArgT}, Ptr{BigInt}, Ptr{BigInt}))
   end

function _on_copy(e::T)::T where T
   #@info "copy on $e"
   return deepcopy(e)
end
@generated _on_gen_copy(::Type{ArgT}) where ArgT =
   quote
      @cfunction(_on_copy, Ref{ArgT}, (Ref{ArgT},))
   end


function _on_gc_protect(x::T) where T
   if haskey(Polymake._on_gc_refs, x)
      @error "gc_protect: duplicate on $x : $(objectid(x))"
   end
   Polymake._on_gc_refs[x] = x
   return nothing
end
@generated _on_gen_gc_protect(::Type{ArgT}) where ArgT =
   quote
      @cfunction(_on_gc_protect, Cvoid, (Ref{ArgT},))
   end

function _on_gc_free(x::T) where T
   if !haskey(Polymake._on_gc_refs, x)
      @error "gc_free: invalid on $x : $(objectid(x))"
   end
   delete!(Polymake._on_gc_refs, x)
   return nothing
end
@generated _on_gen_gc_free(::Type{ArgT}) where ArgT =
   quote
      @cfunction(_on_gc_free, Cvoid, (Ref{ArgT},))
   end


#function _on_to_string(fp::Ptr{Nothing}, str::Ptr{Ptr{UInt8}})
#   f = unsafe_pointer_to_objref(fp)::on_t
#   @info "to_string on $(f) at $fp"
#   Base.unsafe_convert(Cstring,string(f))
#end

function OscarNumber(e)
   id = register_julia_element(e, parent(e), typeof(e))
   #@info "copying $e from $(objectid(e)) in construction"
   return GC.@preserve e begin
      on = OscarNumber(pointer_from_objref(e), id)
   end
   return on
end

function register_julia_element(e, p, t::Type)
   if haskey(_on_dispatch_helper, p)
      return _on_dispatch_helper[p][1]
   end
   newid = field_count+1

   if isimmutable(e)
      @error "OscarNumber: immutable julia types not supported"
   end

   for type in (Int64, Base.Rational{BigInt})
      hasmethod(p, (type,)) ||
         @error "OscarNumber: no constructor ($p)($type)"
   end


   # maybe add some code block to evaluate and check if all required operations
   # are available

   dispatch = oscar_number_dispatch_helper()
   dispatch.index = newid
   dispatch.init = _on_gen_init(t)
   dispatch.init_from_mpz = _on_gen_init_frac(t)
   dispatch.copy = _on_gen_copy(t)

   dispatch.gc_protect = _on_gen_gc_protect(t)
   dispatch.gc_free = _on_gen_gc_free(t)

   dispatch.add = _on_gen_add(t)
   dispatch.sub = _on_gen_sub(t)
   dispatch.mul = _on_gen_mul(t)
   dispatch.div = _on_gen_div(t)
   dispatch.pow = _on_gen_pow(t)

   dispatch.negate = _on_gen_negate(t)
   dispatch.abs    = _on_gen_abs(t)

   dispatch.is_zero = _on_gen_is_zero(t)
   dispatch.is_one  = _on_gen_is_one(t)
   dispatch.sign    = _on_gen_sign_int(t)

   dispatch.cmp = _on_gen_cmp(t)

   # to_string done on c++ side
   # to_string::Ptr{Cvoid}
   # TODO:
   # from_string::Ptr{Cvoid}

   # no inf value for nemo types ...
   #dispatch.is_inf  = _on_gen_is_inf(t)
   #
   #TODO:
   #retrieve oscar object?

   _register_oscar_number(pointer_from_objref(dispatch), newid)
   _on_dispatch_helper[p] = (newid, dispatch)
   _on_parent_by_id[newid] = p

   global field_count=newid
   return field_count
end

