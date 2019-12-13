type_tuples = let NT = NamedTuple{(:type_string, :ctype, :jltype, :convert_f)}
    type_tuples = [
( "pm_perl_PropertyValue",         "pm::perl::PropertyValue",            "pm_perl_PropertyValue",           nothing ),
( "pm_perl_OptionSet",             "pm::perl::OptionSet",                "pm_perl_OptionSet",               nothing ),
( "pm_perl_Object",                "pm::perl::Object",                   "pm_perl_Object",                  "to_perl_object" ),
( "pm_Integer",                    "pm::Integer",                        "pm_Integer",                      "to_pm_Integer" ),
( "pm_Rational",                   "pm::Rational",                       "pm_Rational",                     "to_pm_Rational" ),
( "pm_Matrix_int",                 "pm::Matrix<int>",                    "pm_Matrix{Int32}",                "to_matrix_int" ),
( "pm_Matrix_pm_Integer",          "pm::Matrix<pm::Integer>",            "pm_Matrix{pm_Integer}",           "to_matrix_Integer" ),
( "pm_Matrix_pm_Rational",         "pm::Matrix<pm::Rational>",           "pm_Matrix{pm_Rational}",          "to_matrix_Rational" ),
( "pm_Matrix_double",              "pm::Matrix<double>",                 "pm_Matrix{Float64}",              "to_matrix_double" ),
( "pm_Vector_pm_int",              "pm::Vector<int>",                    "pm_Vector{Int32}",                "to_vector_int" ),
( "pm_Vector_pm_Integer",          "pm::Vector<pm::Integer>",            "pm_Vector{pm_Integer}",           "to_vector_Integer" ),
( "pm_Vector_pm_Rational",         "pm::Vector<pm::Rational>",           "pm_Vector{pm_Rational}",          "to_vector_Rational" ),
( "pm_Vector_double",              "pm::Vector<double>",                 "pm_Vector{Float64}",              "to_vector_double" ),
( "pm_Set_Int32",                  "pm::Set<int32_t>",                   "pm_Set{Int32}",                   "to_set_int32" ),
( "pm_Set_Int64",                  "pm::Set<long>",                      "pm_Set{Int64}",                   "to_set_int64" ),
( "pm_Array_Int32",                "pm::Array<int32_t>",                 "pm_Array{Int32}",                 "to_array_int32" ),
( "pm_Array_Int64",                "pm::Array<long>",                    "pm_Array{Int64}",                 "to_array_int64" ),
( "pm_Array_pm_Integer",           "pm::Array<pm::Integer>",             "pm_Array{pm_Integer}",            "to_array_Integer" ),
( "pm_Array_String",               "pm::Array<std::string>",             "pm_Array{String}",                "to_array_string" ),
( "pm_Array_pm_Set_Int32",         "pm::Array<pm::Set<int32_t>>",        "pm_Array{pm_Set{Int32}}",         "to_array_set_int32" ),
( "pm_Array_pm_Array_Int32",       "pm::Array<pm::Array<int32_t>>",      "pm_Array{pm_Array{Int32}}",       "to_array_array_int32" ),
( "pm_Array_pm_Array_Int64",       "pm::Array<pm::Array<long>>",         "pm_Array{pm_Array{Int64}}",       "to_array_array_int64" ),
( "pm_Array_pm_Array_pm_Integer",  "pm::Array<pm::Array<pm::Integer>>",  "pm_Array{pm_Array{pm_Integer}}",  "to_array_array_Integer" ),
( "pm_Array_pm_Matrix_pm_Integer", "pm::Array<pm::Matrix<pm::Integer>>", "pm_Array{pm_Matrix{pm_Integer}}", "to_array_matrix_Integer" ),
( "pm_Array_pm_perl_Object",       "pm::Array<pm::perl::Object>",        "pm_Array{pm_perl_Object}",        "to_array_perl_object" ),
( "pm_SparseMatrix_pm_Integer",    "pm::SparseMatrix<pm::Integer>",      "pm_SparseMatrix{pm_Integer}",     "to_pm_sparsematrix_Integer"),
( "pm_SparseMatrix_pm_Rational",    "pm::SparseMatrix<pm::Rational>",      "pm_SparseMatrix{pm_Rational}",     "to_pm_sparsematrix_Rational"),
( "pm_SparseMatrix_int",    "pm::SparseMatrix<int>",      "pm_SparseMatrix{Int32}",     "to_pm_sparsematrix_int"),
( "pm_SparseMatrix_double",    "pm::SparseMatrix<double>",      "pm_SparseMatrix{Float64}",     "to_pm_sparsematrix_double"),
]
    NT.(type_tuples)
end

insert_type_map(type_string) = "insert_type_in_map(\"$type_string\", &POLYMAKETYPE_$type_string);"

function map_inserts_code(type_tuples)
    return join((insert_type_map(tt.type_string) for tt in type_tuples), "\n")
end

function call_function_feed_argument_if(juliatype, ctype)
    return """
\tif (jl_subtype(current_type, POLYMAKETYPE_$juliatype)) {
        function << *reinterpret_cast<$ctype*>(get_ptr_from_cxxwrap_obj(argument));
        return;
    }"""
end

function call_function_feed_argument_code(type_tuples)
    feeding_ifs = join(
        (call_function_feed_argument_if(tt.type_string, tt.ctype) for tt in type_tuples),
        "\n")
    return """
template <typename T>
void polymake_call_function_feed_argument(T& function, jl_value_t* argument)
{
    jl_value_t* current_type = jl_typeof(argument);
    if (jl_is_int64(argument)) {
        // check size of long, to be sure
        static_assert(sizeof(long) == 8, "long must be 64 bit");
        function << static_cast<long>(jl_unbox_int64(argument));
        return;
    }
    if (jl_is_bool(argument)) {
        function << jl_unbox_bool(argument);
        return;
    }
    if (jl_is_string(argument)) {
        function << std::string(jl_string_data(argument));
        return;
    }
$feeding_ifs
}
"""
end

function option_set_take_if(type_string, ctype)
    return """
\tif (jl_subtype(current_type, POLYMAKETYPE_$type_string)) {
        optset[key] << *reinterpret_cast<$ctype*>(get_ptr_from_cxxwrap_obj(value));
        return;
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
        return;
    }
    if (jl_is_bool(value)) {
        optset[key] << jl_unbox_bool(value);
        return;
    }
    if (jl_is_string(value)) {
        optset[key] << std::string(jl_string_data(value));
        return;
    }
$option_set_ifs
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
    realname = abi::__cxa_demangle(typeid($ctype).name(), 0, 0, &status);
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
