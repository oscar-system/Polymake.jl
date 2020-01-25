const SmallObject = Union{Integer, Rational, Matrix, Vector, Set, Array, SparseMatrix, TropicalNumber, IncidenceMatrix}
const VecOrMat_eltypes = Union{Int64, Integer, Rational, Float64}

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
