module Polydb

import Polymake: call_function

using Polymake

# julia itself also has a cert.pem but this one should be more recent
# and provides a variable for the path
using MozillaCACerts_jll

using Mongoc

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
function find(c::Collection{T}, d::Dict=Dict(); opts::Union{Nothing, Dict}=nothing) where T
   return Cursor{T}(Mongoc.find(c.mcol, Mongoc.BSON(d); options=opts))
end

function find(c::Collection{T}, d::Pair...) where T
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

# help functions to reduce runtime and keep code clean
function _evaluateIteration(nothing::Nothing)
   return nothing
end

function _evaluateIteration(a::Tuple{Mongoc.BSON, Any})
   return (parse_document(a[1]), a[2])
end

# default iteration functions returning `Polymake.BigObject`s
function Base.iterate(cursor::Cursor{Polymake.BigObject})
   return _evaluateIteration(iterate(cursor.mcursor))
end

function Base.iterate(cursor::Cursor{Polymake.BigObject}, state::Nothing)
   return _evaluateIteration(iterate(cursor.mcursor, state))
end

function Base.iterate(coll::Collection{Polymake.BigObject})
   return _evaluateIteration(iterate(coll.mcol))
end

function Base.iterate(coll::Collection{Polymake.BigObject}, state::Mongoc.Cursor)
   return _evaluateIteration(iterate(coll.mcol, state))
end

# functions for `BSON` iteration
function Base.iterate(cursor::Cursor{Mongoc.BSON})
   return iterate(cursor.mcursor)
end

function Base.iterate(cursor::Cursor{Mongoc.BSON}, state::Nothing)
   return iterate(cursor.mcursor, state)
end

function Base.collect(cursor::Cursor{Mongoc.BSON})
   return collect(cursor.mcursor)
end

function Base.iterate(coll::Collection{Mongoc.BSON})
   return iterate(coll.mcol)
end

function Base.iterate(coll::Collection{Mongoc.BSON}, state::Mongoc.Cursor)
   return iterate(coll.mcol, state)
end

#Info

# prints a list of the fields of a collection

function get_fields(coll::Collection)
   db = coll.mcol.database
   coll_c = db[string("_collectionInfo.", coll.mcol.name)]
   info = collect(coll_c)[2]
   if haskey(info, "fields")
      return _convert_fields(info["fields"])
   else
      return Array{String, 1}()
   end
end

function _convert_fields(d::Dict)
   return [key=>(value == 1 ? "" : value)
      for (key, value) in d]
end

function _convert_fields(a::Array{String, 1})
   return map(p -> p=>"", a)
end

function print_fields(coll::Collection)
   println(_print_fields(get_fields(coll)))
end

# function _print_fields

function _print_fields(a::Array{Pair{String, String}})
   res = ""
   for (key, value) in a
      if value == ""
         res = string(res, key, "\n")
      else
         res = string(res, key, ": ", value, "\n")
      end
   end
   return res
end

# prints information about a specific Collection
# also used for the info(::Database) function
function _info(io::IO, coll::Collection)
   db = coll.mcol.database
   coll_c = db[string("_collectionInfo.", coll.mcol.name)]
   info = iterate(coll_c)[1]
   print(io, typeof(coll), "\n", _get_collection(info))
end

Base.show(io::IO, coll::Collection) = _info(io, coll)

Base.show(io::IO, ::MIME"text/plain", coll::Collection) = print(io, typeof(coll), ": ", coll.mcol.name)

# returns an array containing the names of all collections in the Polydb
function _get_collection_names(db::Database)
   opts = Mongoc.BSON("authorizedCollections" => true, "nameOnly" => true)
   return Mongoc.get_collection_names(db.mdb;options=opts)
end

# for the set of names obtained by the _get_collection_names(::Database) function
# returns two arrays containing the names of the meta data collections
# first one for sections, second one for collections
function _get_meta_names(names::Array{String, 1})
   n = length(names)
   sec_bool = BitArray{1}(undef, n)
   coll_bool = BitArray{1}(undef, n)
   n_secs = 0
   n_colls = 0
   i = 1
   for name in names
      if SubString(name, 1, 2) == "_s"
         sec_bool[i] = true
         coll_bool[i] = false
         n_secs += 1
      elseif SubString(name, 1, 2) == "_c"
         sec_bool[i] = false
         coll_bool[i] = true
         n_colls += 1
      else
         sec_bool[i] = false
         coll_bool[i] = false
      end
      i += 1
   end
   secs = Base.Array{String,1}(undef, n_secs)
   colls = Base.Array{String,1}(undef, n_colls)
   i_s = 1
   i_c = 1
   for j = 1:n
      if sec_bool[j]
         secs[i_s] = names[j]
         i_s += 1
      elseif coll_bool[j]
         colls[i_c] = names[j]
         i_c += 1
      end
   end
   return secs, colls
end

# functions helping printing metadata for sections or collections
function _get_contact(s::String)
   return s
end

function _get_contact(a::Array)
   res = ""
   for dict in a
      str = dict["name"]
      for key in ["email", "www", "affiliation"]
         if !isempty(get(dict, key, ""))
            str = string(str, ", ", dict[key])
         end
      end
      res = string(res, "\t\t", str, "\n")
   end
   return res
end

# prints information about a specific section and
# continues to print information about its content
function _get_section(db::Database, info::Mongoc.BSON, sections::Array{String,1}, collections::Array{String,1})
   res = string("SECTION: ", join(info["section"], "."), "\n", info["description"], "\n")
   if haskey(info, "maintainer")
      res = string(res, "Maintained by ", info["maintainer"]["name"], ", ", info["maintainer"]["email"], ", ", info["maintainer"]["affiliation"], "\n")
   end
   return string(res, "\n", _get_sections(db, info["section"], sections, collections))
end

# prints information about a specific collection
function _get_collection(info::Mongoc.BSON)
   res = string("\tCOLLECTION: ", join(info["section"], "."), ".", info["collection"], "\n")
   if haskey(info, "description")
      res = string(res, "\t", info["description"], "\n")
   end
   if haskey(info, "author")
      res = string(res, "\tAuthored by ", "\n", _get_contact(info["author"]))
   end
   if haskey(info, "maintainer")
      res = string(res, "\tMaintained by", "\n", _get_contact(info["maintainer"]))
   end
   return res
end

# initializes printing complete section/collection tree
function _get_sections(db::Database, sections::Array{String,1}, collections::Array{String,1})
   res = ""
   for sec in sections
      sec_c = db.mdb[sec]
      info = iterate(sec_c)[1]
      if length(info["section"]) == 1
         res = string(res, _get_section(db, info, sections, collections))
      end
   end
   return res
end

# prints subsections/collection tree of a section given by the array s
# i.e. for the section "Polytopes.Lattice", s = ["Polytopes", "Lattice"]
function _get_sections(db::Database, s::Array{Any,1}, sections::Array{String,1}, collections::Array{String,1})
   res = ""
   coll_bool = true
   for sec in sections
      sec_c = db.mdb[sec]
      info = iterate(sec_c)[1]
      if length(info["section"]) == length(s) + 1 && info["section"][1:length(s)] == s
         coll_bool = false
         res = string(res, _get_section(db, info, sections, collections))
      end
   end
   # as of now, each section either contains subsections or collections
   if coll_bool
      for coll in collections
         coll_c = db.mdb[coll]
         info = iterate(coll_c)[1]
         if info["section"] == s
            res = string(res, _get_collection(info), "\n")
         end
      end
   end
   return res
end

# prints a sorted list of the sections and collections of the Polydb
# together with information about each of these, if existent
# relying on the structure of Polydb
function info(db::Database)
   names = _get_collection_names(db)
   sections, collections = _get_meta_names(names)
   println(_get_sections(db, sections, collections))
end

end
