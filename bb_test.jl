using Revise
using Test
using Polymake

function BB_iterator(c)
    N = polytope.dim(c)
    @info "running bb using iterator over $N-dimensional polytope"
    bb = Polymake.BeneathBeyond(c.POINTS, c.LINEALITY_SPACE, redundant=true, triangulation=true, iscone=true)
    tr = GC.@preserve bb begin
        for x in bb
            @show length(Polymake.getTriangulation(bb.algo))
        end
        tr = Polymake.getTriangulation(bb.algo)
        @show last(tr)
        tr
    end
    @info "bb is done!"
    return tr
end


function BB_direct_call(c)
    N = polytope.dim(c)
    @info "running bb using direct calls over $N-dimensional polytope"
    bb = Polymake.BeneathBeyondAlgo{Polymake.Rational}()
    P, L = c.POINTS, c.LINEALITY_SPACE
    tr = GC.@preserve bb P L begin    
        Polymake.bb_initialize!(bb, P, L)
        
        for p in 0:6
            @time Polymake.bb_add_point!(bb, p)
        end
        
        @show Polymake.getTriangulation(bb)
        
        @time for p in 2:size(c.POINTS, 1)-1
            Polymake.bb_add_point!(bb, p)
        end
        tr = Polymake.getTriangulation(bb)
        @show last(tr)
        @info "bb is done!"
        tr
    end
    return tr
end;



const rs = polytope.rand_sphere(4,30);

@info "running placing_triangulation"
t1 = polytope.placing_triangulation(rs.POINTS)
t2 = let rs = rs
    N = polytope.dim(rs)
    @info "running bb using bb_compute! over $N-dimensional polytope"
    bbalgo = Polymake.BeneathBeyondAlgo{Polymake.Rational}()
    P, L = rs.POINTS, rs.LINEALITY_SPACE
    GC.@preserve bbalgo P L begin
        Polymake.bb_compute!(bbalgo, P, L)
        Polymake.getTriangulation(bbalgo)
    end
end

@test t1 == t2

t3 = BB_direct_call(rs)
@test t1 == t3
t4 = BB_iterator(rs)
@test t1 == t4
