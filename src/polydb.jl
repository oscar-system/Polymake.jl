module Polydb

import Polymake: call_function

using Polymake

using Mongoc

#Polymake.Polydb's types store information via
# a corresponding Mongoc type variable
struct Collection
   mcol::Mongoc.Collection
end

struct Cursor
   mcursor::Mongoc.Cursor{Mongoc.Collection}
end

struct Database
   mdb::Mongoc.Database
end

# connects to the Polydb and
# returns a Polymake.Polydb.Database instance
function get_db()
   client = Mongoc.Client("mongodb://polymake:database@db.polymake.org/?authSource=admin&ssl=true")
   return Database(client["polydb"])
end

# returns a Polymake.Polydb.Collection instance with the given name
# sections and collections in the name are connected with the '.' sign,
# i.e. names = "Polytopes.Lattice.SmoothReflexive"
function get_collection(db::Database, name::String)
   return Collection(db.mdb[name])
end

# search a collection for documents matching the criteria given by d
function find(c::Collection, d::Dict=Dict(); opts::Union{Nothing, Dict}=nothing)
   return Cursor(Mongoc.find(c.mcol, Mongoc.BSON(d); options=opts))
end

function find(c::Collection, d::Pair...)
   return Cursor(Mongoc.find(c.mcol, Mongoc.BSON(d...)))
end

# returns a Polymake.BigObject from a Mongoc.BSON document
function parse_document(bson::Mongoc.BSON)
   str = Mongoc.as_json(bson)
   return call_function(:common, :deserialize_json_string, str)
end

#Iterator

function Base.iterate(cursor::Cursor)
   a = iterate(cursor.mcursor)
   if a == nothing
      return nothing
   else
      return (parse_document(a[1]), a[2])
   end
end

function Base.iterate(cursor::Cursor, state::Nothing)
   a = iterate(cursor.mcursor, state)
   if a == nothing
      return nothing
   else
      return (parse_document(a[1]), a[2])
   end
end

#
function Base.collect(cursor::Cursor)
   result = Vector{Polymake.BigObject}()
    for doc in cursor
        push!(result, doc)
    end
    return result
end

function Base.iterate(coll::Collection)
   a =  iterate(coll.mcol)
   return (parse_document(a[1]), a[2])
end

function Base.iterate(coll::Collection, state::Mongoc.Cursor)
   a = iterate(coll.mcol,state)
   if a == nothing
      return nothing
   else
      return (parse_document(a[1]), a[2])
   end
end

#Info

# prints information about a specific Collection
# also used for the info(::Database) function
function info(coll::Collection)
   db = coll.mcol.database
   coll_c = db[string("_collectionInfo.", coll.mcol.name)]
   info = iterate(coll_c)[1]
   _print_collection(info)
end

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
   sec_bool = Array{Bool, 1}(undef, n)
   coll_bool = Array{Bool, 1}(undef, n)
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
   secs = Array{String,1}(undef, n_secs)
   colls = Array{String,1}(undef, n_colls)
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
function _print_contact(s::String)
   println(s)
end

function _print_contact(a::Array)
   for dict in a
      str = dict["name"]
      for key in ["email", "www", "affiliation"]
         if haskey(dict, key) && dict[key] != ""
            str = string(str, ", ", dict[key])
         end
      end
      println(string("\t\t", str))
   end
end

# prints information about a specific section and
# continues to print information about its content
function _print_section(db::Database, info::Mongoc.BSON, sections::Array{String,1}, collections::Array{String,1})
   println(string("SECTION: ", join(info["section"], ".")))
   println(info["description"])
   if haskey(info, "maintainer")
      println(string("Maintained by ", info["maintainer"]["name"], ", ", info["maintainer"]["email"], ", ", info["maintainer"]["affiliation"], "\n"))
   else
      println()
   end
   _print_sections(db, info["section"], sections, collections)
end

# prints information about a specific collection
function _print_collection(info::Mongoc.BSON)
   println(string("\tCOLLECTION: ", join(info["section"], "."), ".", info["collection"]))
   if haskey(info, "description")
      println(string("\t", info["description"]))
   end
   if haskey(info, "author")
      println("\tAuthored by ")
      _print_contact(info["author"])
   end
   if haskey(info, "maintainer")
      println("\tMaintained by")
      _print_contact(info["maintainer"])
   end
   println()
end

# initializes printing complete section/collection tree
function _print_sections(db::Database, sections::Array{String,1}, collections::Array{String,1})
   for sec in sections
      sec_c = db.mdb[sec]
      info = iterate(sec_c)[1]
      if length(info["section"]) == 1
         _print_section(db, info, sections, collections)
      end
   end
end

# prints subsections/collection tree of a section given by the array s
# i.e. for the section "Polytopes.Lattice", s = ["Polytopes", "Lattice"]
function _print_sections(db::Database, s::Array{Any,1}, sections::Array{String,1}, collections::Array{String,1})
   coll_bool = true
   for sec in sections
      sec_c = db.mdb[sec]
      info = iterate(sec_c)[1]
      if length(info["section"]) == length(s) + 1 && info["section"][1:length(s)] == s
         coll_bool = false
         _print_section(db, info, sections, collections)
      end
   end
   # as of now, each section either contains subsections or collections
   if coll_bool
      for coll in collections
         coll_c = db.mdb[coll]
         info = iterate(coll_c)[1]
         if info["section"] == s
            _print_collection(info)
         end
      end
   end
end

# prints a sorted list of the sections and collections of the Polydb
# together with information about each of these, if existent
# relying on the structure of Polydb
function info(db::Database)
   names = _get_collection_names(db)
   sections, collections = _get_meta_names(names)
   _print_sections(db, sections, collections)
end

end
