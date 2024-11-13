local typedefs = require "kong.db.schema.typedefs"


local PLUGIN_NAME = "api-version"


local schema = {
  name = PLUGIN_NAME,
  fields = {
    -- the 'fields' array is the top-level entry with fields defined by Kong
    { consumer = typedefs.no_consumer },  -- this plugin cannot be configured on a consumer (typical for auth plugins)
    { protocols = typedefs.protocols_http },
    { config = {
        -- The 'config' record is the custom part of the plugin schema
        type = "record",
        fields = {
          { api_names = { type = "array",
              required = true,
              elements = typedefs.header_name,
              default = { "API" },
          }, },
          { key_names = { type = "array",
              required = true,
              elements = typedefs.header_name,
              default = { "ehsm_id" },
          }, },
          { usr_aad = { type = "array",
              required = true,
              elements = typedefs.header_name,
              default = { "aad" },
          }, },
          { key_id = { type = "array",
              required = true,
              elements = typedefs.header_name,
              default = { "key_id" },
          }, },
          { text_to_encrypt = { type = "array",
              required = true,
              elements = typedefs.header_name,
              default = { "text_to_encrypt" },
          }, },
          { text_to_decrypt = { type = "array",
              required = true,
              elements = typedefs.header_name,
              default = { "text_to_decrypt" },
          }, },
          -- a standard defined field (typedef), with some customizations
          { request_header = typedefs.header_name {
              required = true,
              default = "Hello-World" } },
          { response_header = typedefs.header_name {
              required = true,
              default = "Bye-World" } },
          --{ key_in_header = { type = "boolean", required = true, default = true }, },
          --{ key_in_query = { type = "boolean", required = true, default = true }, },
          --{ key_in_body = { type = "boolean", required = true, default = true }, },
          { ehsm_id = typedefs.header_name { required = false, default = "ehsm_id" }, },
          { aad = typedefs.header_name { required = false, default = "aad" }, },
          { text = typedefs.header_name { required = false, default = "text" }, },
          { data_back = typedefs.header_name { required = false, default = "data_back" }, },
          { modified_response = typedefs.header_name { required = false, default = "modified_response" }, },
          { ehsm_response_in_body = typedefs.header_name { required = false, default = "ehsm_response_in_body" }, },
          { cocoas_response_in_body = typedefs.header_name { required = false, default = "cocoas_response_in_body" }, },
          { ttl = { -- self defined field
              type = "integer",
              default = 600,
              required = true,
              gt = 0, }}, -- adding a constraint for the value
        },
        entity_checks = {
          -- add some validation rules across fields
          -- the following is silly because it is always true, since they are both required
          { at_least_one_of = { "request_header", "response_header" }, },
          -- We specify that both header-names cannot be the same
          { distinct = { "request_header", "response_header"} },
        },
      },
    },
  },
}

return schema
