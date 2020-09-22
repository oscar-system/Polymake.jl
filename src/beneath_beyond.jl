mutable struct BeneathBeyond{T}
    algo::BeneathBeyondAlgoAllocated{T}
    rays::Matrix{T}
    lineality::Matrix{T}
    perm::Base.Vector{Int}

    function BeneathBeyond(
        rays::AbstractMatrix{T},
        lineality::AbstractMatrix{T} = similar(rays, (0, size(rays, 2)));
        perm::AbstractVector{<:Base.Integer} = 1:size(rays, 1),
        redundant = true,
        triangulation = true,
        iscone = true,
        vertices = false,
    ) where {T}

        @assert !isempty(perm)
        @assert all(>(0), perm)

        bb = new{T}(BeneathBeyondAlgo{T}(), rays, lineality, perm)

        _bb_expecting_redundant(bb.algo, redundant)
        _bb_making_triangulation(bb.algo, triangulation)
        _bb_for_cone(bb.algo, iscone)
        _bb_computing_vertices(bb.algo, vertices)

        _bb_initialize!(bb.algo, bb.rays, bb.lineality)

        finalizer(_bb_clear!, bb)
        return bb
    end
    function BeneathBeyond{T}(
        a::BeneathBeyondAlgo,
        rays::AbstractMatrix,
        lineality::AbstractMatrix,
        perm::AbstractVector,
    ) where {T}
        bb = new{T}(a, rays, lineality, perm)
        finalizer(_bb_clear!, bb)
        return bb
    end
end

Base.length(bb::BeneathBeyond) = length(bb.perm)

function add_point!(bb::BeneathBeyond, i::Base.Integer)
    @boundscheck 0 < i <= length(bb) || throw(BoundsError(bb, i))
    GC.@preserve bb begin
        _bb_add_point!(bb.algo, i - 1)
    end
    return bb
end

function Base.iterate(bb::BeneathBeyond, s = 1)
    if s > length(bb)
        return nothing
    end
    add_point!(bb, bb.perm[s])
    return nothing, s + 1
end

for f in (
    :_bb_clear!,
    :facets,
    :vertex_facet_incidence,
    :affine_hull,
    :vertices,
    :non_redundant_linealities,
    :linealities,
    :triangulation,
    :triangulation_size,
)
    @eval begin
        $f(bb::BeneathBeyond) = GC.@preserve bb begin
            $f(bb.algo)
        end
    end
end

function Base.deepcopy_internal(bb::BeneathBeyond{T}, dict::IdDict) where {T}

    GC.@preserve bb begin
        res = BeneathBeyond{T}(
            copy(bb.algo),
            copy(bb.rays),
            copy(bb.lineality),
            copy(bb.perm),
        )
    end
    return res
end
