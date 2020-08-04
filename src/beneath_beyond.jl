mutable struct BeneathBeyond{T}
    algo::Polymake.BeneathBeyondAlgoAllocated{T}
    rays::Matrix{T}
    lineality::Matrix{T}
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

        algo = BeneathBeyondAlgo{T}()
        R = convert(Matrix{T}, rays)
        L = convert(Matrix{T}, lineality)
        p = convert(Vector{T}, perm)
        bb = new{T}(algo, R, L, p)

        bb_expecting_redundant(bb.algo, redundant)
        bb_making_triangulation(bb.algo, triangulation)
        bb_for_cone(bb.algo, iscone)
        bb_computing_vertices(bb.algo, vertices)

        bb_initialize!(bb.algo, R, L)

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
