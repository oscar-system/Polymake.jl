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

    bool check_defined() const noexcept
    {
        return this->is_defined();
    }
    std::string get_typename()
    {
        if (!this->is_defined()) {
            return "undefined";
        }
        switch (this->classify_number()) {

            // primitives
            case number_is_zero:
            case number_is_int:
                return "int";
            case number_is_float:
                return "double";

            // with typeinfo ptr (nullptr for Objects)
            case number_is_object:
                // some non-primitive Scalar type with typeinfo (e.g.
                // Rational)
            case not_a_number:
                // a c++ type with typeinfo or a perl Object
                {
                    const std::type_info* ti = this->get_canned_typeinfo();
                    if (ti == nullptr) {
                        // perl object
                        return "perl::Object";
                    }
                    else {
                        return legible_typename(*ti);
                    }
                }
            default:
                throw std::runtime_error(
                    "get_typename: could not determine property type");
        }
    }
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
