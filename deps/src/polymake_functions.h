#ifndef POLYMAKE_WRAP_FUNCTIONS
#define POLYMAKE_WRAP_FUNCTIONS


void initialize_polymake();

polymake::perl::Object call_func_0args(std::string);

polymake::perl::Object call_func_1args(std::string, int);

polymake::perl::Object call_func_2args(std::string, int, int);

pm::perl::Object to_perl_object(pm::perl::PropertyValue);

pm::Integer to_pm_Integer(pm::perl::PropertyValue);

pm::Rational to_pm_Rational(pm::perl::PropertyValue);

bool to_bool(pm::perl::PropertyValue);

extern pm::Vector<pm::Integer> (*to_vector_integer)(pm::perl::PropertyValue);
extern pm::Vector<pm::Rational> (*to_vector_rational)(pm::perl::PropertyValue);

extern pm::Matrix<pm::Integer> (*to_matrix_integer)(pm::perl::PropertyValue);
extern pm::Matrix<pm::Rational> (*to_matrix_rational)(pm::perl::PropertyValue);

pm::Integer new_integer_from_bigint(jl_value_t*);

extern void (*fill_jlarray_int32_from_set32)(jlcxx::ArrayRef<int32_t>, pm::Set<int32_t>);
extern void (*fill_jlarray_int64_from_set64)(jlcxx::ArrayRef<int64_t>, pm::Set<int64_t>);

// We can do better templating here
template<typename T>
std::string show_small_object(const T& obj){
    std::ostringstream buffer;
    wrap(buffer) << polymake::legible_typename(typeid(obj)) << pm::endl << obj;
    return buffer.str();
}

extern std::string (*show_integer)(const pm::Integer&);
extern std::string (*show_rational)(const pm::Rational&);
extern std::string (*show_vec_integer)(const pm::Vector<pm::Integer>&);
extern std::string (*show_vec_rational)(const pm::Vector<pm::Rational>&);
extern std::string (*show_mat_integer)(const pm::Matrix<pm::Integer>&);
extern std::string (*show_mat_rational)(const pm::Matrix<pm::Rational>&);

#endif
