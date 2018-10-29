

function complete_property(obj::pm_perl_Object,prefix::String)
   return Polymake.call_function("complete_property",Array{Any,1}([obj,prefix]))
end

