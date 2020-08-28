function get_attachment_map(obj::BigObject, str::String)
    att = Polymake.get_attachment(obj, str)
    return @convert_to Map{String, String} att
end
