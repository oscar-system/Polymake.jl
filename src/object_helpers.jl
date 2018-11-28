
function complete_property(obj::pm_perl_Object,prefix::String)
   return convert_from_property_value(internal_call_function("complete_property",Any[obj,prefix]))
end

function list_applications()
   return convert_from_property_value(internal_call_function("list_applications",Any[]))
end

function list_big_objects(app::String)
   return convert_from_property_value(internal_call_function("list_big_objects",Any[app]))
end
