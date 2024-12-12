local typedefs = require "kong.db.schema.typedefs"


local PLUGIN_NAME = "attest"


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
          { api = { type = "array",
              required = true,
              elements = typedefs.header_name,
              default = { "api" },
          }, },
          { ng_auth = { type = "array",
              required = true,
              elements = typedefs.header_name,
              default = { "ng_auth" },
          }, },
          { ng_evidence = typedefs.header_name { required = false, default = "ng_evidence" }, },
          { ng_tee = typedefs.header_name { required = false, default = "ng_tee" }, },
          { api_evidence = typedefs.header_name { required = false, default = "api_evidence" }, },
          { api_tee = typedefs.header_name { required = false, default = "api_tee" }, },
          { api_attest_status = typedefs.header_name { required = false, default = "api_attest_status" }, },
          { attest_result = typedefs.header_name { required = false, default = "attest_result" }, },
          { response_test1 = typedefs.header_name { required = false, default = "response_test1" }, },
          { response_test2 = typedefs.header_name { required = false, default = "response_test2" }, },
          { response_test3 = typedefs.header_name { required = false, default = "response_test3" }, },
          { response_test4 = typedefs.header_name { required = false, default = "response_test4" }, },
          { response_test5 = typedefs.header_name { required = false, default = "response_test5" }, },
          { response_test6 = typedefs.header_name { required = false, default = "response_test6" }, },
          { response_test7 = typedefs.header_name { required = false, default = "response_test7" }, },
          { response_test8 = typedefs.header_name { required = false, default = "response_test8" }, },
          { response_test9 = typedefs.header_name { required = false, default = "response_test9" }, },
          -- a standard defined field (typedef), with some customizations
          { request_header = typedefs.header_name {
            required = true,
            default = "Hello-World" } },
          { response_header = typedefs.header_name {
            required = true,
            default = "Bye-World" } },
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
