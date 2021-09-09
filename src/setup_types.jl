const SmallObject = Union{
    StdPair,
    StdList,
    Integer,
    Rational,
    Matrix,
    Vector,
    Set,
    Array,
    SparseMatrix,
    SparseVector,
    TropicalNumber,
    IncidenceMatrix,
    Polynomial,
    Map,
}
const VecOrMat_eltypes = Union{Int64, Integer, Rational, Float64, CxxWrap.CxxLong}

const TypeConversionFunctions = Dict(
    Symbol("Int") => to_int,
    Symbol("double") => to_double,
    Symbol("bool") => to_bool,
    Symbol("std::string") => to_string,
    Symbol("undefined") => x -> nothing,
)

function fill_wrapped_types!(wrapped_types_dict, function_type_list)
    function_names = function_type_list[1:2:end]
    type_names = function_type_list[2:2:end]
    for (fn, tn) in zip(function_names, type_names)
        fns = Symbol(fn)
        tn = replace(tn," "=>"")
        @eval $wrapped_types_dict[Symbol($tn)] = Polymake.$fns
    end
    return wrapped_types_dict
end

fill_wrapped_types!(TypeConversionFunctions, get_type_names())

# libcxxwrap-julia prior to 0.8 mapped C++ copy to Base.deepcopy
# now it is mapped to Base.copy
# we make sure both really do a C++ copy for polymake types
# whether this is deep or not cannot be enforced anyway
#
# relevant is the libcxxwrap version that is used at build-time
# which is fixed to 0.8.0 for binarybuilder
# and cxxwrap 0.10 with libcxxwrap 0.7 might still work

if libcxxwrap_build_version() >= v"0.8.0"
    Base.deepcopy_internal(x::T, dict::IdDict) where T<:SmallObject = Base.copy(x)
else
    Base.copy(x::T) where T<:SmallObject = Base.deepcopy(x)
end
