type_tuples = [
( "pm_perl_PropertyValue",         "pm::perl::PropertyValue",            "pm_perl_PropertyValue",           nothing ),
( "pm_perl_OptionSet",             "pm::perl::OptionSet",                "pm_perl_OptionSet",               nothing ),
( "pm_perl_Object",                "pm::perl::Object",                   "pm_perl_Object",                  "to_perl_object" ),
( "pm_Integer",                    "pm::Integer",                        "pm_Integer",                      "to_pm_Integer" ),
( "pm_Rational",                   "pm::Rational",                       "pm_Rational",                     "to_pm_Rational" ),
( "pm_Matrix_pm_Integer",          "pm::Matrix<pm::Integer>",            "pm_Matrix{pm_Integer}",           "to_matrix_Integer" ),
( "pm_Matrix_pm_Rational",         "pm::Matrix<pm::Rational>",           "pm_Matrix{pm_Rational}",          "to_matrix_Rational" ),
( "pm_Matrix_double",              "pm::Matrix<double>",                 "pm_Matrix{Float64}",              "to_matrix_double" ),
( "pm_Vector_pm_Integer",          "pm::Vector<pm::Integer>",            "pm_Vector{pm_Integer}",           "to_vector_Integer" ),
( "pm_Vector_pm_Rational",         "pm::Vector<pm::Rational>",           "pm_Vector{pm_Rational}",          "to_vector_Rational" ),
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
]

type_var_file = abspath( @__DIR__, "src", "generated", "type_vars.h" )
map_insert = abspath( @__DIR__, "src", "generated", "map_inserts.h" )
to_polymake_function = abspath( @__DIR__, "src", "generated", "to_polymake_function.h" )
polymake_type_names = abspath( @__DIR__, "src", "generated", "real_type_names.h" )
to_julia_types = abspath( @__DIR__, "..", "src", "generated", "type_translator.jl" )

open(type_var_file,"w") do outputfile
    for (type_string,_,_,_) in type_tuples
        println(outputfile,"CreatePolymakeTypeVar($type_string);")
    end
end

open(map_insert,"w") do outputfile
    for (type_string,_,_,_) in type_tuples
        println(outputfile,"POLYMAKE_INSERT_TYPE_IN_MAP($type_string);")
    end
end

open(to_polymake_function,"w") do outputfile
    for (type_string,c_type,_,_) in type_tuples
        println(outputfile,"TO_POLYMAKE_FUNCTION($type_string,$c_type)")
    end
end

open(to_julia_types,"w") do outputfile
    println(outputfile,"const C_TYPES=[")
    for (type_string,_,jl_type,_) in type_tuples
        println(outputfile,"""("$type_string",$jl_type),""")
    end
    println(outputfile,"]")
end

open(polymake_type_names,"w") do outputfile
    iteration_array = filter( i -> i[4] != nothing, type_tuples )
    println(outputfile,"#define NUMBER_OF_TYPES $(length(iteration_array))")
    println(outputfile,"#define TYPE_TRANSLATIONS \\")
    for (_,c_type,_,convert_func) in iteration_array
        println(outputfile,"""TYPE_TRANSLATOR($c_type,$convert_func) \\""")
    end
    println(outputfile,"")
end
