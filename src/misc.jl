Base.:(==)(a::BasicDecoration, b::BasicDecoration) = 
  Polymake.decoration_face(a) == Polymake.decoration_face(b) &&
  Polymake.decoration_rank(a) == Polymake.decoration_rank(b)
