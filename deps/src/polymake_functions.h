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


extern std::string (*show_integer)(pm::Integer);
extern std::string (*show_rational)(pm::Rational);
extern std::string (*show_vec_integer)(pm::Vector<pm::Integer>);
extern std::string (*show_vec_rational)(pm::Vector<pm::Rational>);
extern std::string (*show_mat_integer)(pm::Matrix<pm::Integer>);
extern std::string (*show_mat_rational)(pm::Matrix<pm::Rational>);
extern std::string (*show_set_int64)(pm::Set<int64_t>);
extern std::string (*show_set_int32)(pm::Set<int32_t>);

#endif
