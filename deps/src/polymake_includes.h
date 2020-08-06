#ifndef POLYMAKE_WRAP_INCLUDES
#define POLYMAKE_WRAP_INCLUDES

#include "polymake_jlcxx.h"

#include <string>
#include <iostream>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wlogical-op-parentheses"
#pragma clang diagnostic ignored "-Wshift-op-parentheses"

#include <polymake/Main.h>
#include <polymake/Matrix.h>
#include <polymake/SparseMatrix.h>
#include <polymake/Vector.h>
#include <polymake/Set.h>
#include <polymake/Array.h>
#include <polymake/Rational.h>
#include <polymake/QuadraticExtension.h>
#include <polymake/TropicalNumber.h>
#include <polymake/IncidenceMatrix.h>
#include <polymake/Polynomial.h>
#include <polymake/SparseVector.h>

#include <polymake/perl/calls.h>

#include <polymake/perl/macros.h>
#include <polymake/perl/wrappers.h>

#pragma clang diagnostic pop

#endif
