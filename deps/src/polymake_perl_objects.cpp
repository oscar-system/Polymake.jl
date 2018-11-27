#include "polymake_includes.h"

#include "polymake_tools.h"

#include "polymake_functions.h"

#include "polymake_perl_objects.h"

void polymake_module_add_perl_object(jlcxx::Module& polymake){

  polymake.add_type<pm::perl::PropertyValue>("pm_perl_PropertyValue");
  polymake.add_type<pm::perl::OptionSet>("pm_perl_OptionSet");


  polymake.add_type<pm::perl::Object>("pm_perl_Object")
    .constructor<const std::string&>()
    .method("internal_give",[](pm::perl::Object p, const std::string& s){ return p.give(s); })
    .method("exists",[](pm::perl::Object p, const std::string& s){ return p.exists(s); })
    .method("properties",[](pm::perl::Object p){ std::string x = p.call_method("properties");
                                                 return x;
                                                });

  polymake.method("to_bool",[](pm::perl::PropertyValue p){ return static_cast<bool>(p);});
  polymake.method("to_int",[](pm::perl::PropertyValue p){ return static_cast<int64_t>(p);});
  polymake.method("to_double",[](pm::perl::PropertyValue p){ return static_cast<double>(p);});
  polymake.method("to_perl_object",&to_perl_object);

  polymake.method("typeinfo_string", [](pm::perl::PropertyValue p){
    PropertyValueHelper ph(p);
    return ph.get_typename();
  });

  polymake.method("take",[](pm::perl::Object p, const std::string& s, const std::string& t){
      p.take(s) << t;
  });
  polymake.method("take",[](pm::perl::Object p, const std::string& s, const pm::perl::PropertyValue& v){
      p.take(s) << v;
  });

}
