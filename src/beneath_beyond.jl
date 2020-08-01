mutable struct BeneathBeyond{T}
    algo::Polymake.BeneathBeyondAlgoAllocated{T}
    perm::Vector{Int}

    function BeneathBeyond(
        rays::AbstractMatrix{T},
        lineality::AbstractMatrix{T}=similar(rays, (0,size(rays,2)));
        perm = collect(0:size(rays, 1)-1),
        redundant = true,
        triangulation = true,
        iscone = true,
        vertices = false,
    ) where {T}

        @assert !isempty(perm)

        algo = Polymake.BeneathBeyondAlgo{T}()
        Polymake.bb_expecting_redundant(algo, redundant)
        Polymake.bb_making_triangulation(algo, triangulation)
        Polymake.bb_for_cone(algo, iscone)
        Polymake.bb_computing_vertices(algo, vertices)

        Polymake.bb_initialize!(
            algo,
            convert(Polymake.Matrix{Polymake.Rational}, rays),
            convert(Polymake.Matrix{Polymake.Rational}, lineality),
        )

        bb = new{T}(algo, perm)

        # finalizer(x->bb_clear!(x.algo), bb)

        return bb
    end
end

Base.length(bb::BeneathBeyond) = length(bb.perm)
function Base.iterate(bb::BeneathBeyond, s = 1)
    if s > length(bb)
        return nothing
    end
    _, time, _ = @timed bb_add_point!(bb.algo, bb.perm[s])
    @info "Iteration $s; adding point $(bb.perm[s]+1), time = $time (s)"
    return nothing, s + 1
end
