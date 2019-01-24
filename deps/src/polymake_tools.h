#ifndef POLYMAKE_WRAP_TOOLS
#define POLYMAKE_WRAP_TOOLS

namespace pm {
template <typename PointedT, typename CppT>
struct iterator_cross_const_helper<jlcxx::array_iterator_base<PointedT, CppT>,
                                   true> {
    typedef jlcxx::array_iterator_base<std::remove_const_t<PointedT>,
                                       std::remove_const_t<CppT>>
        iterator;
    typedef jlcxx::array_iterator_base<std::add_const_t<PointedT>,
                                       std::add_const_t<CppT>>
        const_iterator;
};
}    // namespace pm

using namespace polymake;

namespace {

class PropertyValueHelper : public pm::perl::PropertyValue {
  public:
    PropertyValueHelper(const pm::perl::PropertyValue& pv)
        : pm::perl::PropertyValue(pv){};

    // in some form these will be moved to the polymake code
    bool is_boolean() const
    {
        return call_function("is_boolean_wrapper", *this);
    };

    using Value::classify_number;
    using Value::get_canned_typeinfo;
    using Value::is_defined;
    using Value::not_a_number;
    using Value::number_is_float;
    using Value::number_is_int;
    using Value::number_is_object;
    using Value::number_is_zero;
};

}    // namespace


struct Polymake_Data {
    polymake::Main*        main_polymake_session;
    polymake::perl::Scope* main_polymake_scope;
};

extern Polymake_Data data;

template <typename T> struct WrappedSetIterator {
    typename pm::Set<T>::const_iterator iterator;
    using value_type = T;
    WrappedSetIterator<T>(pm::Set<T>& S)
    {
        iterator = pm::entire(S);
    }
};


static inline void* get_ptr_from_cxxwrap_obj(jl_value_t* obj)
{
    return *reinterpret_cast<void**>(obj);
}

    // Safe way
    // void* get_ptr_from_cxxwrap_obj(jl_value_t* obj){
    //     return jl_unbox_voidpointer(jl_get_field(obj,"cpp_object"));
    // }

#endif
