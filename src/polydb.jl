module Polydb

import Polymake: call_function

using Mongoc

struct Collection
   mcol::Mongoc.Collection
end

struct Cursor
   mcursor::Mongoc.Cursor{Mongoc.Collection}
end

struct Database
   mdb::Mongoc.Database
end

function get_db()
   client = Mongoc.Client("mongodb://polymake:database@db.polymake.org/?authSource=admin&ssl=true")
   return Database(client["polydb"])
end

function get_collection(db::Database, name::String)
   return Collection(db.mdb[name])
end

function find(c::Collection, d::Union{Dict,Array{Pair{String,T},1}}) where T<:Any
   return Cursor(Mongoc.find(c.mcol, to_BSON(d)))
end

function to_BSON(d::Union{Dict,Array{Pair{String,T},1}}) where T<:Any
   return Mongoc.BSON(to_BSON_String(d))
end

function to_BSON_String(d::Union{Dict,Array{Pair{String,T},1}}) where T<:Any
   terms = Array{String,1}(undef, length(d))
   i = 1
   for (key,val) in d
      terms[i] = pair_to_string(key,val)
      i += 1
   end
   return string("{ ", join(terms, ", "), " }")
end

function pair_to_string(key::String, val::String)
   return string("\"", key, "\" : \"", val, "\"")
end


# function pair_to_string(key::String, val::Union{Dict,Array{Pair{String,T},1}}) where T<:Any
#    return string("\"", key, "\" : ", to_BSON_String(val))
# end

function pair_to_string(key::String, val)
   return string("\"", key, "\" : ", val)
end

function parse_document(bson::Mongoc.BSON)
   str = Mongoc.as_json(bson)
   return call_function(:common, :deserialize_json_string, str)
end

#Iterator

function Base.iterate(cursor::Cursor)
   return iterate(cursor.mcursor)
end

function Base.iterate(cursor::Cursor, state::Cursor)
   return iterate(cursor.mcursor,state.mcursor)
end

function Base.iterate(cursor::Cursor, state::Nothing)
   return iterate(cursor.mcursor, state)
end

function Base.collect(cursor::Cursor)
   return collect(cursor.mcursor)
end

function Base.iterate(coll::Collection)
   return iterate(coll.mcol)
end

function Base.iterate(coll::Collection, state::Cursor)
   return iterate(coll.mcol,state.mcursor)
end

#Info

function get_collection_names(db::Database)
   opts = Mongoc.BSON("authorizedCollections" => true, "nameOnly" => true)
   return Mongoc.get_collection_names(db.mdb;options=opts)
end

function print_collection_names(db::Database)
   names = get_collection_names(db)
   for name in names
      if SubString(name, 1, 1) != "_"
         println(name)
      end
   end
end

end
