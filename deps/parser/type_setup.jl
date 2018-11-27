type_tuples = [
( "pm_perl_PropertyValue",         "pm::perl::PropertyValue",            "pm_perl_PropertyValue" ),
( "pm_perl_OptionSet",             "pm::perl::OptionSet",                "pm_perl_OptionSet" ),
( "pm_perl_Object",                "pm::perl::Object",                   "pm_perl_Object" ),
( "pm_Integer",                    "pm::Integer",                        "pm_Integer" ),
( "pm_Rational",                   "pm::Rational",                       "pm_Rational" ),
( "pm_Matrix_pm_Integer",          "pm::Matrix<pm::Integer>",            "pm_Matrix{pm_Integer}" ),
( "pm_Matrix_pm_Rational",         "pm::Matrix<pm::Rational>",           "pm_Matrix{pm_Rational}" ),
( "pm_Vector_pm_Integer",          "pm::Vector<pm::Integer>",            "pm_Vector{pm_Integer}" ),
( "pm_Vector_pm_Rational",         "pm::Vector<pm::Rational>",           "pm_Vector{pm_Rational}" ),
( "pm_Set_Int32",                  "pm::Set<int32_t>",                   "pm_Set{Int32}" ),
( "pm_Set_Int64",                  "pm::Set<long>",                      "pm_Set{Int64}" ),
( "pm_Array_Int32",                "pm::Array<int32_t>",                 "pm_Array{Int32}" ),
( "pm_Array_Int64",                "pm::Array<long>",                    "pm_Array{Int64}" ),
( "pm_Array_pm_Integer",           "pm::Array<pm::Integer>",             "pm_Array{pm_Integer}" ),
( "pm_Array_String",               "pm::Array<std::string>",             "pm_Array{String}" ),
( "pm_Array_pm_Set_Int32",         "pm::Array<pm::Set<int32_t>>",        "pm_Array{pm_Set{Int32}}" ),
( "pm_Array_pm_Array_Int32",       "pm::Array<pm::Array<int32_t>>",      "pm_Array{pm_Array{Int32}}" ),
( "pm_Array_pm_Array_Int64",       "pm::Array<pm::Array<long>>",         "pm_Array{pm_Array{Int64}}" ),
( "pm_Array_pm_Array_pm_Integer",  "pm::Array<pm::Array<pm::Integer>>",  "pm_Array{pm_Array{pm_Integer}}" ),
( "pm_Array_pm_Matrix_pm_Integer", "pm::Array<pm::Matrix<pm::Integer>>", "pm_Array{pm_Matrix{pm_Integer}}" )
]

type_var_file = abspath( @__DIR__, "..", "src", "generated", "type_vars.h" )
map_insert = abspath( @__DIR__, "..", "src", "generated", "map_inserts.h" )
to_polymake_function = abspath( @__DIR__, "..", "src", "generated", "to_polymake_function.h" )
to_julia_types = abspath( @__DIR__, "..", "..", "src", "generated", "type_translator.jl" )

open(type_var_file,"w") do outputfile
    for (type_string,_,_) in type_tuples
        println(outputfile,"CreatePolymakeTypeVar($type_string);")
    end
end

open(map_insert,"w") do outputfile
    for (type_string,_,_) in type_tuples
        println(outputfile,"POLYMAKE_INSERT_TYPE_IN_MAP($type_string);")
    end
end

open(to_polymake_function,"w") do outputfile
    for (type_string,c_type,_) in type_tuples
        println(outputfile,"TO_POLYMAKE_FUNCTION($type_string,$c_type)")
    end
end

open(to_julia_types,"w") do outputfile
    println(outputfile,"const C_TYPES=[")
    for (type_string,_,jl_type) in type_tuples
        println(outputfile,"""("$type_string",$jl_type),""")
    end
    println(outputfile,"]")
end
