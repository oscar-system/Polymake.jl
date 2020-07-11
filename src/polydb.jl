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
#
# the uri of the server can be set in advance by writing its `String` representation
# into ENV["POLYDB_TEST_URI"]
# (used to connect to the github services container for testing)
function get_db()
   # we explicitly set the cacert file, otherwise we might get connection errors because the certificate cannot be validated
   client = Mongoc.Client(get(ENV, "POLYDB_TEST_URI", "mongodb://polymake:database@db.polymake.org/?authSource=admin&ssl=true&sslCertificateAuthorityFile=$(cacert)"))
   return Database(client["polydb"])
end

# returns a Polymake.Polydb.Collection instance with the given name
# sections and collections in the name are connected with the '.' sign,
# i.e. names = "Polytopes.Lattice.SmoothReflexive"
Base.getindex(db::Database, name::AbstractString) = Collection{Polymake.BigObject}(db.mdb[name])

# search a collection for documents matching the criteria given by d
function Mongoc.find(c::Collection{T}, d::Dict=Dict(); opts::Union{Nothing, Dict}=nothing) where T
   return Cursor{T}(Mongoc.find(c.mcol, Mongoc.BSON(d); options=(isnothing(opts) ? nothing : Mongoc.BSON(opts))))
end

function Mongoc.find(c::Collection{T}, d::Pair...) where T
   return Cursor{T}(Mongoc.find(c.mcol, Mongoc.BSON(d...)))
end

# creating `BSON` iterators from the respective `Polymake.BigObject` iterator
# and vice versa
function Collection{T}(c::Collection) where T<:Union{Polymake.BigObject, Mongoc.BSON}
   return Collection{T}(c.mcol)
end

function Cursor{T}(cursor::Cursor) where T<:Union{Polymake.BigObject, Mongoc.BSON}
   return Cursor{T}(cursor.mcursor)
end

# returns a Polymake.BigObject from a Mongoc.BSON document
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

# returns an array cotaining the names of all collections in the Polydb, excluding meta collections
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

# prints a structured list of the sections and collections of the Polydb
# together with information about each of these, if existent
#
# relying on the structure of Polydb
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

# prints customized information about a collection
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

TODO: doctext
"""
macro select(args...)
   if length(args) > 1 || !(args[1] isa String)
      throw(ArgumentError("`Polymake.Polydb.@select` macro needs to be called together with a String representing a collection's name, e.g. `Polymake.Polydb.@select \"Polytopes.Lattice.SmoothReflexive\"`"))
   end
   :(x -> getindex(x, $args[1]))
end

"""
   Polymake.Polydb.@filter conditions...

TODO:  doctext
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

TODO: doctext
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
