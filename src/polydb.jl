module Polydb

import Polymake: call_function

using Polymake

# julia itself also has a cert.pem but this one should be more recent
# and provides a variable for the path
using MozillaCACerts_jll

using Mongoc

import Mongoc: find

#Polymake.Polydb's types store information via
# a corresponding Mongoc type variable

"""
      Database

Type for referencing a specific database (usually the `polyDB`)
"""
struct Database
   mdb::Mongoc.Database
end

"""
      Collection{T}

Type for referencing a specific collection.
`T<:Union{Polymake.BigObject, Mongoc.BSON}` defines the template and/or element types
returned by operations applied on objects of this type.
"""
struct Collection{T}
   mcol::Mongoc.Collection
end

"""
      Cursor{T}

Type containing the results of a query.
Can be iterated, but the iterator can not be reset. For this cause, one has to query again.
`T<:Union{Polymake.BigObject, Mongoc.BSON}` defines the element types.
"""
struct Cursor{T}
   mcursor::Mongoc.Cursor{Mongoc.Collection}
end

"""
      get_db()

Connect to the `polyDB` and return `Database` instance.

The uri of the server can be set in advance by writing its `String` representation
into ENV["POLYDB_TEST_URI"].
(used to connect to the github services container for testing)
# Examples
```julia-repl
julia> db = Polymake.Polydb.get_db();

julia> typeof(db)
Polymake.Polydb.Database
```
"""
function get_db()
   # we explicitly set the cacert file, otherwise we might get connection errors because the certificate cannot be validated
   client = Mongoc.Client(get(ENV, "POLYDB_TEST_URI", "mongodb://polymake:database@db.polymake.org/?authSource=admin&ssl=true&sslCertificateAuthorityFile=$(cacert)"))
   return Database(client["polydb"])
end

"""
      getindex(db::Database, name::AbstractString)

Return a `Polymake.Polydb.Collection{Polymake.BigObject}` instance
from `db` with the given `name`.
Sections and collections in the name are connected with the '.' sign.
# Examples
```julia-repl
julia> db = Polymake.Polydb.get_db();

julia> collection = getindex(db, "Polytopes.Lattice.SmoothReflexive")
Polymake.Polydb.Collection{Polymake.BigObject}: Polytopes.Lattice.SmoothReflexive

julia> collection = db["Matroids.Small"]
Polymake.Polydb.Collection{Polymake.BigObject}: Matroids.Small
```
"""
Base.getindex(db::Database, name::AbstractString) = Collection{Polymake.BigObject}(db.mdb[name])

"""
      find(c::Collection{T}, d::Dict=Dict(); opts::Union{Nothing, Dict})

Search a collection `c` for documents matching the criteria given by `d`.
Apply search options `opts`.
# Examples
```julia-repl
julia> db = Polymake.Polydb.get_db();

julia> collection = db["Polytopes.Lattice.SmoothReflexive"];

julia> query = Dict("DIM"=>3, "N_FACETS"=>5);

julia> results = Polymake.Polydb.find(collection, query);

julia> typeof(results)
Polymake.Polydb.Cursor{Polymake.BigObject}
```
"""
function Mongoc.find(c::Collection{T}, d::Dict=Dict(); opts::Union{Nothing, Dict}=nothing) where T
   return Cursor{T}(Mongoc.find(c.mcol, Mongoc.BSON(d); options=(isnothing(opts) ? nothing : Mongoc.BSON(opts))))
end

"""
      find(c::Collection{T}, d::Pair...)

Search a collection `c` for documents matching the criteria given by `d`.
# Examples
```julia-repl
julia> db = Polymake.Polydb.get_db();

julia> collection = db["Polytopes.Lattice.SmoothReflexive"];

julia> results = Polymake.Polydb.find(collection, "DIM"=>3, "N_FACETS"=>5);

julia> typeof(results)
Polymake.Polydb.Cursor{Polymake.BigObject}
```
"""
function Mongoc.find(c::Collection{T}, d::Pair...) where T
   return Cursor{T}(Mongoc.find(c.mcol, Mongoc.BSON(d...)))
end

"""
      Collection{T}(c::Collection)

Create another `Collection` object with a specific template parameter
referencing the same collection as `c`.
`T` can be chosen from `Polymake.BigObject` and `Mongoc.BSON`.
# Examples
```julia-repl
julia> db = Polymake.Polydb.get_db();

julia> collection = db["Polytopes.Lattice.SmoothReflexive"]
Polymake.Polydb.Collection{Polymake.BigObject}: Polytopes.Lattice.SmoothReflexive

julia> collection_bson = Polymake.Polydb.Collection{Mongoc.BSON}(collection)
Polymake.Polydb.Collection{Mongoc.BSON}: Polytopes.Lattice.SmoothReflexive

julia> collection_bo = Polymake.Polydb.Collection{Polymake.BigObject}(collection_bson)
Polymake.Polydb.Collection{Polymake.BigObject}: Polytopes.Lattice.SmoothReflexive
```
"""
function Collection{T}(c::Collection) where T<:Union{Polymake.BigObject, Mongoc.BSON}
   return Collection{T}(c.mcol)
end

"""
      Cursor{T}(cur::Cursor)

Create another `Cursor` object with a specific template parameter
referencing the same data set as `cur`.
`T` can be chosen from `Polymake.BigObject` and `Mongoc.BSON`.
# Examples
```julia-repl
julia> db = Polymake.Polydb.get_db();

julia> collection = db["Polytopes.Lattice.SmoothReflexive"]
Polymake.Polydb.Collection{Polymake.BigObject}: Polytopes.Lattice.SmoothReflexive

julia> results = Polymake.Polydb.find(collection, "DIM"=>3, "N_FACETS"=>5);

julia> results_bson = Polymake.Polydb.Cursor{Mongoc.BSON}(results);

julia> typeof(results_bson)
Polymake.Polydb.Cursor{Mongoc.BSON}

julia> results_bo = Polymake.Polydb.Cursor{Polymake.BigObject}(results_bson);

julia> typeof(results_bo)
Polymake.Polydb.Cursor{Polymake.BigObject}
```
"""
function Cursor{T}(cursor::Cursor) where T<:Union{Polymake.BigObject, Mongoc.BSON}
   return Cursor{T}(cursor.mcursor)
end

"""
      parse_document(bson::Mongoc.BSON)
Create a `Polymake.BigObject` from the data given by `bson`.
# Examples
```julia-repl
julia> db = Polymake.Polydb.get_db();

julia> collection = Polymake.Polydb.Collection{Mongoc.BSON}(db["Polytopes.Lattice.SmoothReflexive"])
Polymake.Polydb.Collection{Mongoc.BSON}: Polytopes.Lattice.SmoothReflexive

julia> bson = collect(Polymake.Polydb.find(collection, "DIM"=>3, "N_FACETS"=>5))[1];

julia> bo = Polymake.Polydb.parse_document(bson);

julia> typeof(bo)
Polymake.BigObjectAllocated
```
"""
function parse_document(bson::Mongoc.BSON)
   str = Mongoc.as_json(bson)
   return @pm common.deserialize_json_string(str)
end

# Iterator

Base.IteratorSize(::Type{<:Cursor}) = Base.SizeUnknown()
Base.eltype(::Cursor{T}) where T = T
Base.IteratorSize(::Type{<:Collection}) = Base.SizeUnknown()
Base.eltype(::Collection{T}) where T = T

# default iteration functions returning `Polymake.BigObject`s
function Base.iterate(cursor::Polymake.Polydb.Cursor{Polymake.BigObject}, state::Nothing=nothing)
    next = iterate(cursor.mcursor, state)
    isnothing(next) && return nothing
    return Polymake.Polydb.parse_document(first(next)), nothing
end

Base.iterate(coll::Polymake.Polydb.Collection{Polymake.BigObject}) =
    return iterate(coll, find(coll))

function Base.iterate(coll::Polymake.Polydb.Collection{Polymake.BigObject}, state::Polymake.Polydb.Cursor)
    next = iterate(state, nothing)
    isnothing(next) && return nothing
    doc, _ = next
    return doc, state
end

# functions for `BSON` iteration
Base.iterate(cursor::Cursor{Mongoc.BSON}, state::Nothing=nothing) =
    iterate(cursor.mcursor, state)

Base.iterate(coll::Collection{Mongoc.BSON}) =
   iterate(coll.mcol)

Base.iterate(coll::Collection{Mongoc.BSON}, state::Mongoc.Cursor) =
   iterate(coll.mcol, state)

#Info

"""
      get_fields(c::Collection)
Return an `Array{String, 1}` containing the names of the fields of `c`.
# Examples
```julia-repl
julia> db = Polymake.Polydb.get_db();

julia> collection = db["Matroids.Small"]
Polymake.Polydb.Collection{Polymake.BigObject}: Matroids.Small

julia> Polymake.Polydb.get_fields(collection)
27-element Array{String,1}:
 "DUAL"
 "N_BASES"
 "TUTTE_POLYNOMIAL"
 "SERIES_PARALLEL"
 "N_FLATS"
 "SPLIT_FLACETS"
 ⋮
 "TERNARY"
 "REGULAR"
 "TRANSVERSAL"
 "IDENTICALLY_SELF_DUAL"
 "BETA_INVARIANT"
```
"""
function get_fields(coll::Collection)
   db = coll.mcol.database
   coll_c = db[string("_collectionInfo.", coll.mcol.name)]
   info1 = Mongoc.find_one(coll_c, Mongoc.BSON("_id" => "info.2.1"))
   info2 = Mongoc.find_one(coll_c, Mongoc.BSON("_id" => info1["schema"]))
   schema = info2["schema"]
   temp = Array{String, 1}()
   if haskey(schema, "required")
      temp = Array{String, 1}(schema["required"])
   else
      temp = _read_fields(schema)
   end
   return temp[(!startswith).(temp, "_")]
end

# recursive helpers to read more complex metadata
# currently only neccessary for `Polytopes.Lattice.SmoothReflexive`
function _read_fields(a::Array)
   res = Array{String, 1}()
   for entry in a
      append!(res, _read_fields(entry))
   end
   return res
end

function _read_fields(d::Dict)
   if haskey(d, "required")
      return d["required"]
   elseif haskey(d, "then")
      return _read_fields(d["then"])
   elseif haskey(d, "allOf")
      return _read_fields(d["allOf"])
   else
      throw(ArgumentError(string("could not read required fields due to invalid entry: ", d)))
   end
end

# shows information about a specific Collection
function Base.show(io::IO, coll::Collection)
   db = Database(coll.mcol.database)
   print(io, typeof(coll), "\n", _get_collection_string(db, coll.mcol.name, 5))
end

Base.show(io::IO, ::MIME"text/plain", coll::Collection) = print(io, typeof(coll), ": ", coll.mcol.name)

# returns an array containing the names of all collections in the Polydb, also including meta collections
function _get_collection_names(db::Database)
   opts = Mongoc.BSON("authorizedCollections" => true, "nameOnly" => true)
   return Mongoc.get_collection_names(db.mdb;options=opts)
end

"""
      get_collection_names(db::Database)

Return an `Array{String, 1}` containing the names of all collections in the
Polydb, excluding meta collections.
# Examples
```julia-repl
julia> db = Polymake.Polydb.get_db();

julia> Polymake.Polydb.get_collection_names(db)
16-element Array{String,1}:
 "Polytopes.Combinatorial.FacesBirkhoffPolytope"
 "Polytopes.Combinatorial.SmallSpheresDim4"
 "Polytopes.Geometric.01Polytopes"
 "Polytopes.Lattice.SmoothReflexive"
 "Polytopes.Lattice.ExceptionalMaximalHollow"
 "Tropical.TOM"
 ⋮
 "Polytopes.Lattice.Panoptigons"
 "Tropical.Cubics"
 "Tropical.SchlaefliFan"
 "Polytopes.Lattice.Reflexive"
 "Polytopes.Combinatorial.CombinatorialTypes"
```
"""
function get_collection_names(db::Database)
   names = _get_collection_names(db)
   res = Array{String, 1}()
   sizehint!(res, floor(Int, length(names)/2))
   for name in names
      if startswith(name, "_c")
         push!(res, SubString(name, 17))
      end
   end
   return res
end

# functions helping printing metadata for sections or collections
function _get_contact(s::String)
   return s
end

function _get_contact(a::Array)
   res = Array{String, 1}()
   for dict in a
      str = Array{String, 1}()
      for key in ["name", "email", "www", "affiliation"]
         if !isempty(get(dict, key, ""))
            push!(str, dict[key])
         end
      end
      push!(res, join(str, ", "))
   end
   return string("\t\t", join(res, "\n\t\t"))
end

# returns information `String` about a specific section
function _get_section_string(db::Database, name::String, level::Base.Integer)
   info = _get_info_document(db, string("_sectionInfo.", name))
   res = [string("SECTION: ", join(info["section"], "."))]
   if level == 1 && haskey(info, "short_description")
      push!(res, string("\t", info["short_description"]))
   end
   if level >= 2 && haskey(info, "description")
      push!(res, info["description"])
   end
   if level >= 3 && haskey(info, "maintainer")
      push!(res, string("Maintained by ", info["maintainer"]["name"], ", ", info["maintainer"]["email"], ", ", info["maintainer"]["affiliation"]))
   end
   return join(res, "\n")
end

# returns information `String` about a specific collection
function _get_collection_string(db::Database, name::String, level::Base.Integer)
   info = _get_info_document(db, string("_collectionInfo.", name))
   res = [string("\tCOLLECTION: ", name)]
   if level == 1 && haskey(info, "short_description")
      push!(res, string("\t", info["short_description"]))
   end
   if level >= 2 && haskey(info, "description")
      push!(res, string("\t", info["description"]))
   end
   if level >= 3 && haskey(info, "author")
      push!(res, string("\tAuthored by ", "\n", _get_contact(info["author"])))
   end
   if level >= 3 && haskey(info, "maintainer")
      push!(res, string("\tMaintained by", "\n", _get_contact(info["maintainer"])))
   end
   if level >= 5
      push!(res, string("\tFields: ", join(get_fields(db[name]), ", ")))
   end
   return join(res, "\n")
end

"""
      info(db::Database, level::Base.Integer=1)
Print a structured list of the sections and collections of the Polydb
together with information about each of these (if existent).

Detail of the output determined by value of `level`:
 * 1: short description,
 * 2: description,
 * 3: description, authors, maintainers,
 * 4: full info,
 * 5: full info and list of recommended search fields.
"""
function info(db::Database, level::Base.Integer=1, io::IO=stdout)
   dbtree = _get_db_tree(db)
   println(io, join(_get_info_strings(db, dbtree, level), "\n\n"))
end

# returns a tree-like nesting of `Dict`s and `Array{String}`s
# representing polyDB's structure
function _get_db_tree(db)
   root = Dict{String, Union{Dict, Array{String, 1}}}()
   cnames =  get_collection_names(db)
   for name in cnames
      path = split(name, ".")
      temp = root
      for i=1:length(path)-2
         if !haskey(temp, path[i])
            temp[path[i]] = Dict{String, Union{Dict, Array{String, 1}}}()
         end
         temp = temp[path[i]]
      end
      if !haskey(temp, path[length(path)-1])
         temp[path[length(path)-1]] = Array{String, 1}()
      end
      temp = temp[path[length(path)-1]]
      push!(temp, path[end])
   end
   return root
end

# recursively generates the info `String`s from the tree received by `_get_db_tree`
function _get_info_strings(db::Database, tree::Dict, level::Base.Integer, path::String="")
   res = Array{String, 1}()
   for (key, value) in tree
      new_path = path == "" ? key : string(path, ".", key)
      push!(res, _get_section_string(db, new_path, level))
      append!(res, _get_info_strings(db, value, level, new_path))
   end
   return res
end

# leaves of the tree are the collections, whose names are stored in an `Array{String}`
function _get_info_strings(db:: Database, colls::Array{String, 1}, level::Base.Integer, path::String="")
   res = Array{String, 1}()
   for coll in colls
      push!(res, _get_collection_string(db, string(path, ".", coll), level))
   end
   return res
end

# for a given collection or section name,
# returns the `Mongoc.BSON` document we read the meta information from
function _get_info_document(db::Database, name::String)
   i = startswith(name, "_c") ? 17 : 14
   return Mongoc.find_one(db.mdb[name], Mongoc.BSON("_id" => string(SubString(name, i), ".2.1")))
end

"""
      info(c::Collection, level::Base.Integer=1)
Print information about collection `c` (if existent).

Detail of the output determined by value of `level`:
 * 1: short description,
 * 2: description,
 * 3: description, authors, maintainers,
 * 4: full info,
 * 5: full info and list of recommended search fields.
"""
function info(coll::Collection, level::Base.Integer=5)
   db = Database(coll.mcol.database)
   name = coll.mcol.name
   parts = split(name, ".")
   res = Array{String, 1}()
   for (i, section) in enumerate(parts[1:length(parts) - 1])
      push!(res, _get_section_string(db, join(parts[1:i], "."), level))
   end
   push!(res, _get_collection_string(db, coll.mcol.name, level))
   println(join(res, "\n\n"))
end

# Advanced Querying

# this table contains operations in julia syntax and the corresponding
# `String` for the mongo query
# used by `@filter` macro. expanding this table can increase the supported operations
_operationToMongo = Dict{Symbol, String}(
   :(==) => "\$eq",
   :< => "\$lt",
   :<= => "\$lte",
   :> => "\$gt",
   :>= => "\$gte",
   :!= => "\$ne"
)

"""
   Polymake.Polydb.@select collectionName

This macro can be used as part of a chain for easy (i.e. human readable)
querying.
Generate a method asking a container for the entry with key `collectionName`.

See also: [`@filter`](@ref), [`@map`](@ref)

# Examples
```julia-repl
julia> db = Polymake.Polydb.get_db();

julia> collection = db |>
       Polymake.Polydb.@select("Polytopes.Lattice.SmoothReflexive")
Polymake.Polydb.Collection{Polymake.BigObject}: Polytopes.Lattice.SmoothReflexive
```
"""
macro select(args...)
   if length(args) > 1 || !(args[1] isa String)
      throw(ArgumentError("`Polymake.Polydb.@select` macro needs to be called together with a String representing a collection's name, e.g. `Polymake.Polydb.@select \"Polytopes.Lattice.SmoothReflexive\"`"))
   end
   :(x -> getindex(x, $args[1]))
end

"""
   Polymake.Polydb.@filter conditions...

This macro can be used as part of a chain for easy (i.e. human readable)
querying.
Convert `conditions` into the corresponding `Dict` and
generate a method expanding its input by this `Dict`.
Multiple conditions can be passed in the same line and/or in different lines.

See also: [`@select`](@ref), [`@map`](@ref)

# Examples
```julia-repl
julia> db = Polymake.Polydb.get_db();

julia> query_tuple = db |>
       Polymake.Polydb.@select("Polytopes.Lattice.SmoothReflexive") |>
       Polymake.Polydb.@filter("DIM" <= 3) |>
       Polymake.Polydb.@filter("N_VERTICES" == 8)
(Polymake.Polydb.Collection{Polymake.BigObject}
    COLLECTION: Polytopes.Lattice.SmoothReflexive
    Smooth reflexive lattice polytopes in dimensions up to 9, up to lattice equivalence. The lists were computed with the algorithm of Mikkel Oebro (see [[http://arxiv.org/abs/0704.0049|arxiv: 0704.0049]]) and are taken from the [[http://polymake.org/polytopes/paffenholz/www/fano.html|website of Andreas Paffenholz]]. They also contain splitting data according to [[https://arxiv.org/abs/1711.02936| arxiv: 1711.02936]].
    Authored by
        Andreas Paffenholz, paffenholz@opt.tu-darmstadt.de, TU Darmstadt
        Benjamin Lorenz, paffenholz@opt.tu-darmstadt.de, TU Berlin
        Mikkel Oebro
    Fields: AFFINE_HULL, CONE_DIM, DIM, EHRHART_POLYNOMIAL, F_VECTOR, FACET_SIZES, FACET_WIDTHS, FACETS, H_STAR_VECTOR, LATTICE_DEGREE, LATTICE_VOLUME, LINEALITY_SPACE, N_BOUNDARY_LATTICE_POINTS, N_EDGES, N_FACETS, N_INTERIOR_LATTICE_POINTS, N_LATTICE_POINTS, N_RIDGES, N_VERTICES, REFLEXIVE, SMOOTH, SELF_DUAL, SIMPLE, TERMINAL, VERTEX_SIZES, VERTICES, VERTICES_IN_FACETS, VERY_AMPLE, ALTSHULER_DET, BALANCED, CENTROID, DIAMETER, NORMAL, N_HILBERT_BASIS, IS_PRISM, IS_PRODUCT, IS_SKEW_PRISM, IS_SIMPLEX_SUM, PRISM_BASE, PRODUCT_FACTORS, SIMPLEX_SUM_BASES, SKEW_PRISM_BASES, Dict{String,Any}("DIM" => Dict{String,Any}("\$lte" => 3),"N_VERTICES" => Dict{String,Any}("\$eq" => 8)))

julia> query_tuple = db |>
       Polymake.Polydb.@select("Polytopes.Lattice.SmoothReflexive") |>
       Polymake.Polydb.@filter("DIM" <= 3, "N_VERTICES" == 8)
(Polymake.Polydb.Collection{Polymake.BigObject}
    COLLECTION: Polytopes.Lattice.SmoothReflexive
    Smooth reflexive lattice polytopes in dimensions up to 9, up to lattice equivalence. The lists were computed with the algorithm of Mikkel Oebro (see [[http://arxiv.org/abs/0704.0049|arxiv: 0704.0049]]) and are taken from the [[http://polymake.org/polytopes/paffenholz/www/fano.html|website of Andreas Paffenholz]]. They also contain splitting data according to [[https://arxiv.org/abs/1711.02936| arxiv: 1711.02936]].
    Authored by
        Andreas Paffenholz, paffenholz@opt.tu-darmstadt.de, TU Darmstadt
        Benjamin Lorenz, paffenholz@opt.tu-darmstadt.de, TU Berlin
        Mikkel Oebro
    Fields: AFFINE_HULL, CONE_DIM, DIM, EHRHART_POLYNOMIAL, F_VECTOR, FACET_SIZES, FACET_WIDTHS, FACETS, H_STAR_VECTOR, LATTICE_DEGREE, LATTICE_VOLUME, LINEALITY_SPACE, N_BOUNDARY_LATTICE_POINTS, N_EDGES, N_FACETS, N_INTERIOR_LATTICE_POINTS, N_LATTICE_POINTS, N_RIDGES, N_VERTICES, REFLEXIVE, SMOOTH, SELF_DUAL, SIMPLE, TERMINAL, VERTEX_SIZES, VERTICES, VERTICES_IN_FACETS, VERY_AMPLE, ALTSHULER_DET, BALANCED, CENTROID, DIAMETER, NORMAL, N_HILBERT_BASIS, IS_PRISM, IS_PRODUCT, IS_SKEW_PRISM, IS_SIMPLEX_SUM, PRISM_BASE, PRODUCT_FACTORS, SIMPLEX_SUM_BASES, SKEW_PRISM_BASES, Dict{String,Any}("DIM" => Dict{String,Any}("\$lte" => 3),"N_VERTICES" => Dict{String,Any}("\$eq" => 8)))
```
"""
macro filter(args...)
   d = Dict{String, Any}()
   for i=1:length(args)
      if length(args[i].args) != 3
         throw(ArgumentError(string("no applicable condition: ", args[i])))
      end
      op, key, val = args[i].args
      if haskey(d, key)
         d[key][_operationToMongo[Symbol(op)]] = val
      else
         d[key] = Dict{String, Any}(_operationToMongo[Symbol(op)] => val)
      end
   end
   :(x -> x isa Polymake.Polydb.Collection ? (x, $d) : (x[1], merge(x[2], $d)))
end

"""
   Polymake.Polydb.@map

This macro can be used as part of a chain for easy (i.e. human readable)
querying.
Convert `conditions` into the corresponding `Dict` and
generate a method expanding its input by this `Dict`.
Multiple conditions can be passed in the same line and/or in different lines.

See also: [`@select`](@ref), [`@filter`](@ref)

# Examples
```julia-repl
julia> db = Polymake.Polydb.get_db();

julia> results = db |>
       Polymake.Polydb.@select("Polytopes.Lattice.SmoothReflexive") |>
       Polymake.Polydb.@filter("DIM" == 3, "N_VERTICES" == 8) |>
       Polymake.Polydb.@map() |>
       collect
7-element Array{Polymake.BigObject,1}:
 Polymake.BigObjectAllocated(Ptr{Nothing} @0x00000000028c5320)
 Polymake.BigObjectAllocated(Ptr{Nothing} @0x000000000abd7b40)
 Polymake.BigObjectAllocated(Ptr{Nothing} @0x000000000a6d7bf0)
 Polymake.BigObjectAllocated(Ptr{Nothing} @0x000000000a431470)
 Polymake.BigObjectAllocated(Ptr{Nothing} @0x000000000bcaf290)
 Polymake.BigObjectAllocated(Ptr{Nothing} @0x00000000098fb670)
 Polymake.BigObjectAllocated(Ptr{Nothing} @0x000000000a1ba460)
```
"""
macro map(args...)
   if length(args) == 0
      :(x -> find(x[1], x[2]))
   else
      d = Dict{String, Dict{String, Bool}}("projection" => Dict{String, Bool}()) #TODO: add necessary fields
      for field in args
         d["projection"][field] = true
      end
      :(x -> _find(x[1], x[2], $d))
   end
end

# this method is generated by the `@map` macro
# only opt_set is different depending on input of the macro. this will be used for
# projecting to the union of the minimum neccessary fields and the user given fields
function _find(c::Collection, d::Dict, opt_set::Dict{String, Dict{String, Bool}})
   for field in get_fields(c)
      opt_set["projection"][field] = true
   end
   return find(c, d; opts=opt_set)
end

end
