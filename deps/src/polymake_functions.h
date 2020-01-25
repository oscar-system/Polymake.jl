#ifndef POLYMAKE_WRAP_FUNCTIONS
#define POLYMAKE_WRAP_FUNCTIONS


void initialize_polymake(bool interactive);

pm::perl::BigObject to_bigobject(const pm::perl::PropertyValue&);

std::string typeinfo_helper(const pm::perl::PropertyValue& p, bool demangle);

template <typename T> T to_SmallObject(const pm::perl::PropertyValue& pv)
{
    T obj = pv;
    return obj;
};

pm::Integer new_integer_from_bigint(jl_value_t*);

// We can do better templating here
template <typename T>
std::string show_small_object(const T& obj, bool print_typename = true)
{
    std::ostringstream buffer;
    auto               wrapped_buffer = wrap(buffer);
    if (print_typename) {
        wrapped_buffer << polymake::legible_typename(typeid(obj)) << pm::endl;
    }
    wrapped_buffer << obj;
    return buffer.str();
}

struct VecOrMat_supported
{
    typedef jlcxx::ParameterList<pm::Int, pm::Integer, pm::Rational, double> value_type;
};

#endif
