
function complete_property(obj::pm_perl_Object,prefix::String)
   return convert_from_property_value(Polymake.call_function("complete_property",Array{Any,1}([obj,prefix])))
end

function list_applications()
   return convert_from_property_value(Polymake.call_function("list_applications",Array{Any,1}([])))
end

function list_big_objects(app::String)
   return convert_from_property_value(call_function("list_big_objects",Array{Any,1}([app])))
end

