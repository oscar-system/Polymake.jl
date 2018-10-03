#include "polymake_includes.h"
#include "polymake_tools.h"
#include "polymake_functions.h"

void initialize_polymake(){
    data.main_polymake_session = new polymake::Main;
    data.main_polymake_scope = new polymake::perl::Scope(data.main_polymake_session->newScope());
    std::cout << data.main_polymake_session->greeting() << std::endl;
}

polymake::perl::Object call_func_0args(std::string func) {
    return polymake::call_function(func);
}

polymake::perl::Object call_func_1args(std::string func, int arg1) {
    return polymake::call_function(func, arg1);
}

polymake::perl::Object call_func_2args(std::string func, int arg1, int arg2) {
    return polymake::call_function(func, arg1, arg2);
}

pm::perl::Object to_perl_object(pm::perl::PropertyValue v){
    pm::perl::Object obj;
    v >> obj;
    return v;
}

pm::Integer to_pm_Integer(pm::perl::PropertyValue v){
    pm::Integer integer = v;
    return integer;
}

pm::Rational to_pm_Rational(pm::perl::PropertyValue v){
    pm::Rational integer = v;
    return integer;
}

bool to_bool(pm::perl::PropertyValue v){
    return static_cast<bool>(v);
}

template<typename T>
pm::Vector<T> to_vector_T(pm::perl::PropertyValue v){
    pm::Vector<T> m = v;
    return m;
}
pm::Vector<pm::Integer> (*to_vector_integer)(pm::perl::PropertyValue) = &to_vector_T<pm::Integer>;
pm::Vector<pm::Rational> (*to_vector_rational)(pm::perl::PropertyValue) = &to_vector_T<pm::Rational>;

template<typename T>
pm::Matrix<T> to_matrix_T(pm::perl::PropertyValue v){
    pm::Matrix<T> m = v;
    return m;
}
pm::Matrix<pm::Integer> (*to_matrix_integer)(pm::perl::PropertyValue) = &to_matrix_T<pm::Integer>;
pm::Matrix<pm::Rational> (*to_matrix_rational)(pm::perl::PropertyValue) = &to_matrix_T<pm::Rational>;

pm::Integer new_integer_from_bigint(jl_value_t* integer){
    pm::Integer* p;
    p = reinterpret_cast<pm::Integer*>(integer);
    return *p;
}

template<typename T>
pm::Set<T> set_T(jlcxx::ArrayRef<T> arr){
   pm::Set<T> s(arr.begin(), arr.end());
   return s;
}
pm::Set<int64_t> (*new_set_int64)(jlcxx::ArrayRef<int64_t> arr) = &set_T<int64_t>;
pm::Set<int32_t> (*new_set_int32)(jlcxx::ArrayRef<int32_t> arr) = &set_T<int32_t>;

template<typename T>
pm::Set<T> to_set_T(pm::perl::PropertyValue v){
   pm::Set<T> s = v;
   return s;
}

pm::Set<int64_t> (*to_set_int64)(pm::perl::PropertyValue) = &to_set_T<int64_t>;
pm::Set<int32_t> (*to_set_int32)(pm::perl::PropertyValue) = &to_set_T<int32_t>;

template<typename T, typename S>
void fill_jlarray_T_from_S(jlcxx::ArrayRef<T> arr, S itr){
   int64_t index{0};
   for(auto i = pm::entire(itr); !i.at_end(); ++i){
      arr[index++] = static_cast<T>(*i);
   }
}

void (*fill_jlarray_int32_from_set32)(jlcxx::ArrayRef<int32_t>, pm::Set<int32_t>) = &fill_jlarray_T_from_S<int32_t, pm::Set<int32_t>>;
void (*fill_jlarray_int64_from_set64)(jlcxx::ArrayRef<int64_t>, pm::Set<int64_t>) = &fill_jlarray_T_from_S<int64_t, pm::Set<int64_t>>;

// We can do better templating here
template<typename T>
std::string show_small_object(T obj){
    std::ostringstream buffer;
    wrap(buffer) << polymake::legible_typename(typeid(obj)) << pm::endl << obj;
    return buffer.str();
}

std::string (*show_integer)(pm::Integer obj) = &show_small_object<pm::Integer>;
std::string (*show_rational)(pm::Rational obj) = &show_small_object<pm::Rational>;
std::string (*show_vec_integer)(pm::Vector<pm::Integer>  obj) = &show_small_object<pm::Vector<pm::Integer> >;
std::string (*show_vec_rational)(pm::Vector<pm::Rational>  obj) = &show_small_object<pm::Vector<pm::Rational> >;
std::string (*show_mat_integer)(pm::Matrix<pm::Integer>  obj) = &show_small_object<pm::Matrix<pm::Integer> >;
std::string (*show_mat_rational)(pm::Matrix<pm::Rational>  obj) = &show_small_object<pm::Matrix<pm::Rational> >;
std::string (*show_set_int64)(pm::Set<int64_t>  obj) = &show_small_object<pm::Set<int64_t> >;
std::string (*show_set_int32)(pm::Set<int32_t>  obj) = &show_small_object<pm::Set<int32_t> >;
