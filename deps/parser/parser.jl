using JSON

struct UnknownPolymakeType <: Exception
    msg::String
    UnknownPolymakeType(type_string) = new("Unknown polymake type: $type_string")
end

struct UnparsablePolymakeFunction <: Exception
    msg::String
    UnparsablePolymakeFunction(function_name) = new("Cannot parse function: $function_name")
end

type_translate_list = Dict(
    "BigObject"          => "pm_perl_Object",
    "OptionSet"          => "pm_perl_OptionSet",
    "Matrix"             => "pm_Matrix{T} where T",
    "Matrix<Rational>"   => "pm_Matrix{pm_Rational}",
    "Matrix<Integer>"    => "pm_Matrix{pm_Integer}",
    "Vector"             => "pm_Vector{T} where T",
    "Vector<Rational>"   => "pm_Vector{pm_Rational}",
    "Vector<Integer>"    => "pm_Vector{pm_Integer}",
    "Integer"            => "pm_Integer",
    "Rational"           => "pm_Rational",
    "Set"                => "pm_Set",
    "Anything"           => "Any"
)

## Dummy, will soon be generated
filenames_list = Array{String,1}(
    [ abspath(joinpath( @__DIR__, "..", "..", "tmp", "polytope.json")) ]
)

function julia_function_string(julia_name::String, polymake_name::String, app_name::String, julia_args::String, call_args::String, parameter_string::String )

    return """
function $julia_name( $julia_args, ::Val{Convert}=Val(true) ) where Convert
    application( "$app_name" )
    return_value = call_function( "$polymake_name$parameter_string", Array{Any,1}([ $call_args ]) )
    if Convert
        return convert_from_property_value(return_value)
    else
        return return_value
    end
end

"""
end

function julia_method_string(julia_name::String, polymake_name::String, app_name::String, julia_args::String, call_args::String, parameter_string::String )
    return """
function $julia_name( $julia_args, ::Val{Convert}=Val(true) ) where Convert
    application( "$app_name" )
    return_value = call_method( "$polymake_name$parameter_string", dispatch_obj, Array{Any,1}([ $call_args ]) )
    if Convert
        convert_from_property_value(return_value)
    else
        return return_value
    end
end

"""
end

function create_argument_string_from_type( type_string::String, number::Int64 )
    ## Special case for BigObject (we do not care 'bout the type here)
    if startswith(type_string,"BigObject")
        return "arg" * string(number) * "::" * type_translate_list["BigObject"]
    end
    ## We only translate the known cases
    if !haskey(type_translate_list,type_string)
        throw(UnknownPolymakeType(type_string))
    end
    return "arg" * string(number) * "::" * type_translate_list[type_string]
end

function parse_definition(method_dict::Dict, app_name::String)
    name = method_dict["name"]
    arguments = method_dict["args"]
    mandatory = method_dict["mandatory"]
    type_params = method_dict["type_params"]
    is_method = haskey(method_dict,"method_of")
    ## for now, we use the same name for Julia and Polymake
    julia_name = name
    polymake_name = name

    ## Check for option set
    has_option_set = length(arguments) > 0 && last(arguments) == "OptionSet"

    ## Make type parameters
    param_list_header = Array{String,1}()
    param_list = Array{String,1}()
    for i in 1:type_params
        push!(param_list_header,"param$i::String")
        push!(param_list,"\$param$i")
    end
    if length(param_list) >= 1
        parameter_string = "<" * join(param_list,",") * ">"
    else
        parameter_string = ""
    end

    ## Compute the argument range
    max_argument_number = length(arguments) - (has_option_set ? 1 : 0)
    min_argument_number = mandatory

    ## Option set parameter
    option_set_argument = "option_set::" * type_translate_list["OptionSet"]
    option_set_parameter = "option_set"

    ## Real arguments
    if is_method
        if ! startswith(method_dict["method_of"],"BigObject")
            throw(UnparsablePolymakeFunction(name))
        end
        argument_list_header = Array{String,1}(["dispatch_obj::pm_perl_Object"])
        ## Fixme: good?
    else
        argument_list_header = Array{String,1}()
    end
    argument_list = Array{String,1}()


    for i in 1:max_argument_number
        try
            push!(argument_list_header,create_argument_string_from_type(arguments[i],i))
        catch exception
            if exception isa UnknownPolymakeType
                @warn(exception.msg)
                break
            else
                rethrow(exception)
            end
        end
        push!(argument_list,"arg$i")
    end

    if is_method
        min_argument_number = min_argument_number + 1
        max_argument_number = max_argument_number + 1
    end

    actual_arguments = length(argument_list_header)
    if actual_arguments < min_argument_number
        throw(UnparsablePolymakeFunction(name))
    elseif actual_arguments < max_argument_number
        @warn("Ignoring " * string(max_argument_number-actual_arguments) * " arguments of function " * name)
        max_argument_number = actual_arguments
    end

    return_string = ""

    if is_method
        function_string_creator = julia_method_string
    else
        function_string_creator = julia_function_string
    end

    julia_argument_list = vcat(param_list_header,argument_list_header)
    for number_arguments in min_argument_number:max_argument_number
        julia_args = join(julia_argument_list[1:number_arguments+type_params],",")
        if is_method
            call_args = join(argument_list[1:number_arguments - 1],",")
        else
            call_args = join(argument_list[1:number_arguments],",")
        end
        return_string = return_string * function_string_creator(julia_name,polymake_name,app_name,julia_args,call_args,parameter_string)
        if has_option_set
            julia_args = julia_args * "," * option_set_argument
            call_args = call_args * "," * option_set_parameter
            return_string = return_string * function_string_creator(julia_name,polymake_name,app_name,julia_args,call_args,parameter_string)
        end
    end
    return return_string
end

function parse_app_definitions(filename::String,outputfileposition::String,include_file::String)
    println("Parsing "*filename)
    parsed_dict = JSON.Parser.parsefile(filename)
    app_name = parsed_dict["app"]
    return_string = """
module $app_name

import ..pm_Integer, ..pm_Rational, ..pm_Matrix, ..pm_Vector, ..pm_Set,
       ..pm_perl_Object, ..pm_perl_OptionSet, ..pm_perl_PropertyValue,
       ..application, ..call_function, ..call_method,
       ..convert_from_property_value

"""
    for current_function in parsed_dict["functions"]
        return_value = ""
        try
            return_value = parse_definition(current_function,app_name)
        catch exception
            if exception isa UnparsablePolymakeFunction
                @warn(exception.msg)
            end
        end
        return_string = return_string * return_value
    end
    return_string = return_string * "\n\nend\nexport $app_name\n"
    open(abspath(joinpath(outputfileposition, app_name * ".jl" )),"w") do outputfile
        print(outputfile,return_string)
    end
    open(abspath(include_file),"a") do outputfile
        print(outputfile,"include(\"$app_name.jl\")\n")
    end
end

outputfolder = abspath(joinpath(@__DIR__, "..", "..", "src","generated"))
include_file = abspath(joinpath(@__DIR__, "..", "..", "src","generated","includes.jl"))
isfile(include_file) && rm(include_file)


for current_file in filenames_list
    parse_app_definitions(current_file, outputfolder, include_file)
end
