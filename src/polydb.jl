module Polydb

import Polymake: call_function

using Mongoc

function get_db()
   client = Mongoc.Client("mongodb://polymake:database@db.polymake.org/?authSource=admin&ssl=true")
   return client["polydb"]
end

function parse_document(bson::Mongoc.BSON)
   str = Mongoc.as_json(bson)
   call_function(:common, :deserialize_json_string, str)
end

end
