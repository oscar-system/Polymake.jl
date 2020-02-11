type_tuples = let NT = NamedTuple{(:type_string, :ctype, :jltype, :convert_f)}
    type_tuples = [
( "PropertyValue",               "pm::perl::PropertyValue",                  "PropertyValue",                nothing ),
( "OptionSet",                   "pm::perl::OptionSet",                      "OptionSet",                    nothing ),
( "BigObject",                   "pm::perl::BigObject",                      "BigObject",                    "to_bigobject" ),
( "Integer",                     "pm::Integer",                              "Integer",                      "to_integer" ),
( "Rational",                    "pm::Rational",                             "Rational",                     "to_rational" ),
( "Matrix_Int",                  "pm::Matrix<long>",                         "Matrix{CxxWrap.CxxLong}",                "to_matrix_int" ),
( "Matrix_Integer",              "pm::Matrix<pm::Integer>",                  "Matrix{Integer}",              "to_matrix_integer" ),
( "Matrix_Rational",             "pm::Matrix<pm::Rational>",                 "Matrix{Rational}",             "to_matrix_rational" ),
( "Matrix_double",               "pm::Matrix<double>",                       "Matrix{Float64}",              "to_matrix_double" ),
( "Vector_Int",                  "pm::Vector<long>",                         "Vector{CxxWrap.CxxLong}",                "to_vector_int" ),
( "Vector_Integer",              "pm::Vector<pm::Integer>",                  "Vector{Integer}",              "to_vector_integer" ),
( "Vector_Rational",             "pm::Vector<pm::Rational>",                 "Vector{Rational}",             "to_vector_rational" ),
( "Vector_double",               "pm::Vector<double>",                       "Vector{Float64}",              "to_vector_double" ),
( "Set_Int",                     "pm::Set<long>",                            "Set{CxxWrap.CxxLong}",                   "to_set_int" ),
( "Array_Int",                   "pm::Array<long>",                          "Array{CxxWrap.CxxLong}",                 "to_array_int" ),
( "Array_Integer",               "pm::Array<pm::Integer>",                   "Array{Integer}",               "to_array_integer" ),
( "Array_String",                "pm::Array<std::string>",                   "Array{String}",                "to_array_string" ),
( "Array_Set_Int",               "pm::Array<pm::Set<long>>",                 "Array{Set{CxxWrap.CxxLong}}",            "to_array_set_int" ),
( "Array_Array_Int",             "pm::Array<pm::Array<long>>",               "Array{Array{CxxWrap.CxxLong}}",          "to_array_array_int" ),
( "Array_Array_Integer",         "pm::Array<pm::Array<pm::Integer>>",        "Array{Array{Integer}}",        "to_array_array_integer" ),
( "Array_Matrix_Integer",        "pm::Array<pm::Matrix<pm::Integer>>",       "Array{Matrix{Integer}}",       "to_array_matrix_integer" ),
( "Array_BigObject",             "pm::Array<pm::perl::BigObject>",           "Array{BigObject}",             "to_array_bigobject" ),
( "SparseMatrix_Integer",        "pm::SparseMatrix<pm::Integer>",            "SparseMatrix{Integer}",        "to_sparsematrix_integer"),
( "SparseMatrix_Rational",       "pm::SparseMatrix<pm::Rational>",           "SparseMatrix{Rational}",       "to_sparsematrix_rational"),
( "SparseMatrix_Int",            "pm::SparseMatrix<long>",                   "SparseMatrix{CxxWrap.CxxLong}",          "to_sparsematrix_int"),
( "SparseMatrix_double",         "pm::SparseMatrix<double>",                 "SparseMatrix{Float64}",        "to_sparsematrix_double"),
( "IncidenceMatrix_NonSymmetric","pm::IncidenceMatrix<pm::NonSymmetric>",    "IncidenceMatrix{NonSymmetric}","to_incidencematrix_nonsymmetric"),
( "IncidenceMatrix_Symmetric",   "pm::IncidenceMatrix<pm::Symmetric>",       "IncidenceMatrix{Symmetric}",   "to_incidencematrix_symmetric"),
( "TropicalNumber_Max_Rational", "pm::TropicalNumber<pm::Max,pm::Rational>", "TropicalNumber{Max,Rational}", "to_tropicalnumber_max_rational"),
( "TropicalNumber_Min_Rational", "pm::TropicalNumber<pm::Min,pm::Rational>", "TropicalNumber{Min,Rational}", "to_tropicalnumber_min_rational"),
# ( "pm_TropicalNumber_pm_Max_pm_Integer",    "pm::TropicalNumber<pm::Max,pm::Integer>",   "pm_TropicalNumber{pm_Max,pm_Integer}",  "to_pm_tropicalnumber_max_Integer"),
# ( "pm_TropicalNumber_pm_Min_pm_Integer",    "pm::TropicalNumber<pm::Min,pm::Integer>",   "pm_TropicalNumber{pm_Min,pm_Integer}",  "to_pm_tropicalnumber_min_Integer"),
]
    NT.(type_tuples)
end

insert_type_map(type_string) = "insert_type_in_map(\"$type_string\", &POLYMAKETYPE_$type_string);"

function map_inserts_code(type_tuples)
    return join((insert_type_map(tt.type_string) for tt in type_tuples), "\n")
end

function call_function_feed_argument_if(juliatype, ctype)
    return """
\telse if (jl_subtype(current_type, POLYMAKETYPE_$juliatype)) {
        function << jlcxx::unbox<const $ctype&>(value);
    }"""
end

function call_function_feed_argument_code(type_tuples)
    feeding_ifs = join(
        (call_function_feed_argument_if(tt.type_string, tt.ctype) for tt in type_tuples),
        "\n")
    return """
template <typename T>
void polymake_call_function_feed_argument(T& function, jl_value_t* value)
{
    jl_value_t* current_type = jl_typeof(value);
    if (jl_is_int64(value)) {
        // check size of long, to be sure
        static_assert(sizeof(long) == 8, "long must be 64 bit");
        function << static_cast<long>(jl_unbox_int64(value));
    } else if (jl_is_bool(value)) {
        function << jl_unbox_bool(value);
    } else if (jl_is_string(value)) {
        function << std::string(jl_string_data(value));
    } else if (jl_typeis(value, jl_float64_type)){
        function << jl_unbox_float64(value);
    } $feeding_ifs
    else {
        throw std::runtime_error(
            "Cannot pass function value: conversion failed for argument of type " + std::string(jl_typeof_str(value))
        );
    }
    return;
}
"""
end

function option_set_take_if(type_string, ctype)
    return """
\telse if (jl_subtype(current_type, POLYMAKETYPE_$type_string)) {
        optset[key] << jlcxx::unbox<const $ctype&>(value);
    }"""
end

function option_set_take_code(type_tuples)
    option_set_ifs = join(
    (option_set_take_if(tt.type_string, tt.ctype) for tt in type_tuples), "\n")

    content ="""
void option_set_take(pm::perl::OptionSet optset,
                     std::string         key,
                     jl_value_t*         value)
{
    jl_value_t* current_type = jl_typeof(value);
    if (jl_is_int64(value)) {
        // check size of long, to be sure
        static_assert(sizeof(long) == 8, "long must be 64 bit");
        optset[key] << static_cast<long>(jl_unbox_int64(value));
    } else if (jl_is_bool(value)) {
        optset[key] << jl_unbox_bool(value);
    } else if (jl_is_string(value)) {
        optset[key] << std::string(jl_string_data(value));
    } else if (jl_typeis(value, jl_float64_type)){
        optset[key] << jl_unbox_float64(value);
    } $option_set_ifs
    else {
        throw std::runtime_error(
            "Cannot create OptionSet: conversion failed for (key, value) = (" +
            key +
            ", ::" +
            std::string(jl_typeof_str(value)) +
            ")"
        );
    }
    return;
}
"""
    return content
end

function type_translator_code_jl(type_tuples)
    content = join(("(\"$(tt.type_string)\", $(tt.jltype))," for tt in type_tuples), "\n")
    return "const C_TYPES=[$content]"
end

function type_translator(ctype, convert_f)
    return """
\t  type_name_tuples[i] = jl_cstr_to_string(\"$convert_f\");
    realname = abi::__cxa_demangle(typeid($ctype).name(), nullptr, nullptr, &status);
    type_name_tuples[i + 1] = jl_cstr_to_string(realname);
    free(realname);
    i += 2;
    """
end

function get_type_names_code(type_tuples)
    non_nothing_types = filter( i -> i.convert_f != nothing, type_tuples )

    type_translations = join(
        (type_translator(tt.ctype, tt.convert_f) for tt in non_nothing_types),
        "\n")

    return """
#include <cxxabi.h>
#include <typeinfo>

jlcxx::ArrayRef<jl_value_t*> get_type_names() {
    int          status;
    char*        realname;
    int          number_of_types = $(length(non_nothing_types));
    jl_value_t** type_name_tuples = new jl_value_t*[2 * number_of_types];
    int          i = 0;
$type_translations
    return jlcxx::make_julia_array(type_name_tuples, 2 * number_of_types);
}
"""
end

let file = abspath( @__DIR__, "src", "generated", "map_inserts.h" )
    open(file,"w") do outputfile
        println(outputfile, map_inserts_code(type_tuples))
    end
end

let decls = ["jl_value_t* POLYMAKETYPE_$(tt.type_string);" for tt in type_tuples]

    intern = join(decls, "\n")
    open(abspath( @__DIR__, "src", "generated", "type_declarations.h"), "w") do outputfile
        println(outputfile, intern)
    end

    extern = join(("extern $d" for d in decls), "\n")
    open(abspath( @__DIR__, "src", "generated", "type_declarations_extern.h"), "w") do outputfile
        println(outputfile, extern)
    end
end

let file = abspath( @__DIR__, "src", "generated", "polymake_call_function_feed_argument.h")
    open(file, "w") do outputfile
        println(outputfile, call_function_feed_argument_code(type_tuples))
    end
end

let file = abspath( @__DIR__, "src", "generated", "option_set_take.h")
    open(file,"w") do outputfile
        println(outputfile, option_set_take_code(type_tuples))
    end
end

let file = abspath( @__DIR__, "..", "src", "generated", "type_translator.jl" )
    open(file,"w") do outputfile
        println(outputfile, type_translator_code_jl(type_tuples))
    end
end

let file = abspath( @__DIR__, "src", "generated", "get_type_names.h" )
    open(file,"w") do outputfile
        println(outputfile,get_type_names_code(type_tuples))
    end
end
