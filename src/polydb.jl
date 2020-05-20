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
struct Database
   mdb::Mongoc.Database
end

struct Collection{T}
   mcol::Mongoc.Collection
end

struct Cursor{T}
   mcursor::Mongoc.Cursor{Mongoc.Collection}
end

# connects to the Polydb and
# returns a Polymake.Polydb.Database instance
function get_db()
   # we explicitly set the cacert file, otherwise we might get connection errors because the certificate cannot be validated
   client = Mongoc.Client("mongodb://polymake:database@db.polymake.org/?authSource=admin&ssl=true&sslCertificateAuthorityFile=$(cacert)")
   return Database(client["polydb"])
end

# returns a Polymake.Polydb.Collection instance with the given name
# sections and collections in the name are connected with the '.' sign,
# i.e. names = "Polytopes.Lattice.SmoothReflexive"
Base.getindex(db::Database, name::AbstractString) = Collection{Polymake.BigObject}(db.mdb[name])

# search a collection for documents matching the criteria given by d
function Mongoc.find(c::Collection{T}, d::Dict=Dict(); opts::Union{Nothing, Dict}=nothing) where T
   return Cursor{T}(Mongoc.find(c.mcol, Mongoc.BSON(d); options=opts))
end

function Mongoc.find(c::Collection{T}, d::Pair...) where T
   return Cursor{T}(Mongoc.find(c.mcol, Mongoc.BSON(d...)))
end

# creating `BSON` iterators from the respective `Polymake.BigObject` iterator
function Collection{Mongoc.BSON}(c::Collection{Polymake.BigObject})
   return Collection{Mongoc.BSON}(c.mcol)
end

function Cursor{Mongoc.BSON}(cursor::Cursor{Polymake.BigObject})
   return Cursor{Mongoc.BSON}(cursor.mcursor)
end

# returns a Polymake.BigObject from a Mongoc.BSON document
function parse_document(bson::Mongoc.BSON)
   str = Mongoc.as_json(bson)
   return @pm common.deserialize_json_string(str)
end

#Iterator

Base.IteratorSize(::Type{<:Cursor}) = Base.SizeUnknown()
Base.eltype(::Cursor{T}) where T = T

# default iteration functions returning `Polymake.BigObject`s
function Base.iterate(cursor::Polymake.Polydb.Cursor{Polymake.BigObject}, state::Nothing=nothing)
    next = iterate(cursor.mcursor, state)
    isnothing(next) && return nothing
    return Polymake.Polydb.parse_document(first(next)), nothing
end

Base.iterate(coll::Polymake.Polydb.Collection{T}) where T =
    return iterate(coll, Cursor{T}(find(coll)))

function Base.iterate(coll::Polymake.Polydb.Collection, state::Polymake.Polydb.Cursor)
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

# returns an `Array{String, 1}` of the fields of a collection

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
   else
      return _read_fields(d["allOf"])
   end
end

# shows information about a specific Collection
function Base.show(io::IO, coll::Collection)
   db = Database(coll.mcol.database)
   print(io, typeof(coll), "\n", _get_collection_string(db, coll.mcol.name))
end

Base.show(io::IO, ::MIME"text/plain", coll::Collection) = print(io, typeof(coll), ": ", coll.mcol.name)

# returns an array containing the names of all collections in the Polydb, also including meta collections
function _get_collection_names(db::Database)
   opts = Mongoc.BSON("authorizedCollections" => true, "nameOnly" => true)
   return Mongoc.get_collection_names(db.mdb;options=opts)
end

# returns an array cotaining the names of all collections in the Polydb, excluding meta collections
function get_collection_names(db::Database)
   names = _get_collection_names(db)
   res = Array{String, 1}()
   sizehint!(res, floor(Int, length(names)/2))
   for name in names
      if !startswith(name, "_")
         push!(res, name)
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

# returns information String about a specific section
function _get_section_string(db::Database, name::String)
   info = _get_info_document(db, string("_sectionInfo.", name))
   res = [string("SECTION: ", join(info["section"], "."), "\n", info["description"])]
   if haskey(info, "maintainer")
      push!(res, string("Maintained by ", info["maintainer"]["name"], ", ", info["maintainer"]["email"], ", ", info["maintainer"]["affiliation"]))
   end
   return join(res, "\n")
end

# returns information String about a specific collection
function _get_collection_string(db::Database, name::String)
   info = _get_info_document(db, string("_collectionInfo.", name))
   res = [string("\tCOLLECTION: ", name)]
   if haskey(info, "description")
      push!(res, string("\t", info["description"]))
   end
   if haskey(info, "author")
      push!(res, string("\tAuthored by ", "\n", _get_contact(info["author"])))
   end
   if haskey(info, "maintainer")
      push!(res, string("\tMaintained by", "\n", _get_contact(info["maintainer"])))
   end
   return join(res, "\n")
end

# prints a sorted list of the sections and collections of the Polydb
# together with information about each of these, if existent
# relying on the structure of Polydb
function info(db::Database)
   dbtree = _get_db_tree(db)
   println(join(_get_info_strings(db, dbtree), "\n\n"))
end

# returns a tree-like nesting of Dicts and Array{String}s
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

# recursively generates the info Strings from the tree received by `_get_db_tree`
function _get_info_strings(db::Database, tree::Dict, path::String="")
   res = Array{String, 1}()
   for (key, value) in tree
      new_path = path == "" ? key : string(path, ".", key)
      push!(res, _get_section_string(db, new_path))
      append!(res, _get_info_strings(db, value, new_path))
   end
   return res
end

# leaves of the tree are the collections, whose names are stored in an Array{String}
function _get_info_strings(db:: Database, colls::Array{String, 1}, path::String="")
   res = Array{String, 1}()
   for coll in colls
      push!(res, _get_collection_string(db, string(path, ".", coll)))
   end
   return res
end

# for a given collection or section name,
# returns the `BSON` document we read the meta information from
function _get_info_document(db::Database, name::String)
   i = startswith(name, "_c") ? 17 : 14
   return Mongoc.find_one(db.mdb[name], Mongoc.BSON("_id" => string(SubString(name, i), ".2.1")))
end

end
