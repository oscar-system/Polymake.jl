#include "polymake_includes.h"
#include <polymake/polytope/beneath_beyond_impl.h>
#include "polymake_type_modules.h"

namespace polymake { namespace polytope {

template <typename E>
class beneath_beyond_algo_for_ml: public beneath_beyond_algo<E>{
    public:
        typedef E value_type;
        typedef const beneath_beyond_algo<E> Base;

        beneath_beyond_algo_for_ml(): Base()
        {
            initialized = false;
        };

        template <typename Iterator>
        void initialize(const Matrix<E>& rays, const Matrix<E>& lins, Iterator perm);
        void initialize(const Matrix<E>& rays, const Matrix<E>& lins)
        {
        #if POLYMAKE_DEBUG
            enable_debug_output();
        #endif
            initialize(rays, lins, entire(sequence(0, rays.rows())));
        };

        void process_point(Int p);

        void clear();


        // TODO: bundle all results in a structure, move all numbers into it
        template <typename Iterator>
        void compute(const Matrix<E>& rays, const Matrix<E>& lins, Iterator perm);
        void compute(const Matrix<E>& rays, const Matrix<E>& lins)
        {
        #if POLYMAKE_DEBUG
            enable_debug_output();
        #endif
            compute(rays, lins, entire(sequence(0, rays.rows())));
        };

    protected:
        void stop_cleanup();

        using Base::source_points;
        using Base::source_linealities;
        using Base::linealities_so_far;
        using Base::expect_redundant;
        using Base::source_lineality_basis;
        using Base::linealities;
        using Base::transform_points;
        using Base::points;
        using Base::generic_position;
        using Base::triang_size;
        using Base::AH;
        using Base::interior_points;
        using Base::vertices_this_step;
        using Base::interior_points_this_step;
        using Base::facet_normals_valid;
        using Base::facet_normals_low_dim;
        using Base::dual_graph;
        using Base::vertices_so_far;
        using Base::make_triangulation;
        using Base::triangulation;
        using Base::is_cone;
        using Base::facets;
        
        class stop_calculation {};

        enum class compute_state { zero, one, low_dim, full_dim };
        compute_state state;

    private:
        bool initialized;
        Bitset points_added;
};


template <typename E>
template <typename Iterator>
void beneath_beyond_algo_for_ml<E>::initialize(const Matrix<E>& rays, const Matrix<E>& lins, Iterator perm)
{
    source_points = &rays;
    source_linealities = &lins;

    linealities_so_far.resize(0,rays.cols());

    try {
        if (lins.rows() != 0) {
            if (expect_redundant) {
                source_lineality_basis = basis_rows(lins);
                linealities_so_far = lins.minor(source_lineality_basis, All);
                linealities = &linealities_so_far;
            } else {
                linealities = source_linealities;
            }
            transform_points(); // the only place where stop_calculation could be thrown
        } else {
            points = source_points;
            linealities = expect_redundant ? &linealities_so_far : source_linealities;
        }

        generic_position = !expect_redundant;
        triang_size = 0;
        AH = unit_matrix<E>(points->cols());
        if (expect_redundant) {
            interior_points.resize(points->rows());
            vertices_this_step.resize(points->rows());
            interior_points_this_step.resize(points->rows());
        }

        state = compute_state::zero; // moved from the main compute loop

        points_added = Bitset();
        initialized = true;
    }
    catch (const stop_calculation&) { 
#if POLYMAKE_DEBUG
        if (debug >= do_dump) cout << "stop: failed to initialize beneath_beyond_algo" << endl;
#endif
        // TODO: some cleanup??
    }
};

template <typename E>
void beneath_beyond_algo_for_ml<E>::process_point(Int p){
    if ( !points_added.contains(p) ){
        Base::process_point(p);
        points_added += p;
#if POLYMAKE_DEBUG
        std::cout << "processed point p = " << p << std::endl;
#endif
    };
};

template <typename E>
template <typename Iterator>
void beneath_beyond_algo_for_ml<E>::compute(const Matrix<E>& rays, const Matrix<E>& lins, Iterator perm){
    
    initialize(rays, lins);

    try
    {
        for (; !perm.at_end(); ++perm)
            process_point(*perm);
    }
    catch (const stop_calculation&){
#if POLYMAKE_DEBUG
        if (debug >= do_dump) cout << "stop: degenerated to full linear space" << endl;
#endif
        stop_cleanup();
    }

    clear();

#if POLYMAKE_DEBUG
    if (debug >= do_dump) {
        cout << "final ";
        dump();
    }
#endif

};

template <typename E>
void beneath_beyond_algo_for_ml<E>::stop_cleanup(){
    state = compute_state::zero;
    dual_graph.clear();
    vertices_so_far.clear();
    points = source_points;
    interior_points = sequence(0, source_points->rows());
    if (make_triangulation) {
        triangulation.clear();
        triang_size = 0;
    }
}

template <typename E>
void beneath_beyond_algo_for_ml<E>::clear(){

    switch (state) {
    case compute_state::zero:
        if (!is_cone) {
            // empty polyhedron
            AH.resize(0, source_points->cols());
            linealities_so_far.resize(0, source_points->cols());
        }
        break;
    case compute_state::one:
        // There is one empty facet in this case and the point is also a facet normal
        facets[dual_graph.add_node()].normal = points->row(vertices_so_far.front());
        if (make_triangulation) {
            triang_size=1;
            triangulation.push_back(vertices_so_far);
        }
        break;
    case compute_state::low_dim:
        if ( !facet_normals_valid )
        {
            try
            {
                facet_normals_low_dim();
            }
            catch(const stop_calculation& )
            {
                stop_cleanup();
            }
        }
        break;
    case compute_state::full_dim:
        dual_graph.squeeze();
        break;
    }
}

}
}


template<> struct jlcxx::IsMirroredType<
    polymake::polytope::beneath_beyond_algo<pm::Rational>> : std::false_type { };

void polymake_module_add_beneath_beyond(jlcxx::Module& polymake)
{
    polymake
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("_BeneathBeyondAlgo")
        .apply<polymake::polytope::beneath_beyond_algo<pm::Rational>>([](auto wrapped) {});
    
    polymake
        .add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("BeneathBeyondAlgo")
        .apply<polymake::polytope::beneath_beyond_algo_for_ml<pm::Rational>>([](auto wrapped) {
            typedef typename decltype(wrapped)::type             WrappedT;
            typedef typename decltype(wrapped)::type::value_type E;
            wrapped.template constructor();

            wrapped.method("bb_expecting_redundant", &WrappedT::expecting_redundant);
            wrapped.method("bb_for_cone", &WrappedT::for_cone);
            wrapped.method("bb_making_triangulation", &WrappedT::making_triangulation);
            wrapped.method("bb_computing_vertices", &WrappedT::computing_vertices);

            wrapped.method("bb_compute!", static_cast<
                void (polymake::polytope::beneath_beyond_algo_for_ml<E>::*)(const pm::Matrix<E>&, const pm::Matrix<E>&)
            >(&WrappedT::compute));

            wrapped.method("bb_initialize!", static_cast<
                void (polymake::polytope::beneath_beyond_algo_for_ml<E>::*)(const pm::Matrix<E>&, const pm::Matrix<E>&)
            >(&WrappedT::initialize));

            // wrapped.method("initialize", &WrappedT::initialize);
            wrapped.method("bb_add_point!", &WrappedT::process_point);
            wrapped.method("bb_clear!", &WrappedT::clear);

            wrapped.method("getFacets", &WrappedT::getFacets);
            wrapped.method("getVertexFacetIncidence", &WrappedT::getVertexFacetIncidence);
            wrapped.method("getAffineHull", &WrappedT::getAffineHull);
            wrapped.method("getVertices", &WrappedT::getVertices);
            // wrapped.method("getNonRedundantPoints", &WrappedT::getNonRedundantPoints);
            wrapped.method("getNonRedundantLinealities", &WrappedT::getNonRedundantLinealities);
            wrapped.method("getLinealities", &WrappedT::getLinealities);
            // wrapped.method("getDualGraph", &WrappedT::getDualGraph);
            wrapped.method("getTriangulation", &WrappedT::getTriangulation);
        });
}
