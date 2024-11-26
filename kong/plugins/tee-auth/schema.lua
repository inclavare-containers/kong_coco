local typedefs = require "kong.db.schema.typedefs"


return {
  name = "tee-auth",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { key_names = { description = "Describes an array of parameter names where the plugin will look for a key. The key names may only contain [a-z], [A-Z], [0-9], [_] underscore, and [-] hyphen.", type = "array",
              required = true,
              elements = typedefs.header_name,
              default = { "apikey" },
          }, },
          { tee = { description = "tee env, and so length must be at least 10", type = "array",
              required = true,
              elements = typedefs.header_name,
              default = { "tee" },
          }, },
          { response_test1 = typedefs.header_name { required = false, default = "response_test1" }, },
          { response_test2 = typedefs.header_name { required = false, default = "response_test2" }, },
          { response_test3 = typedefs.header_name { required = false, default = "response_test3" }, },
          { response_test4 = typedefs.header_name { required = false, default = "response_test4" }, },
          { response_test5 = typedefs.header_name { required = false, default = "response_test5" }, },
          { response_test6 = typedefs.header_name { required = false, default = "response_test6" }, },
          { response_test7 = typedefs.header_name { required = false, default = "response_test7" }, },
          { response_test8 = typedefs.header_name { required = false, default = "response_test8" }, },
          { response_test9 = typedefs.header_name { required = false, default = "response_test9" }, },
          { hide_credentials = { description = "An optional boolean value telling the plugin to show or hide the credential from the upstream service. If `true`, the plugin strips the credential from the request.", type = "boolean", required = true, default = false }, },
          { anonymous = { description = "An optional string (consumer UUID or username) value to use as an “anonymous” consumer if authentication fails. If empty (default null), the request will fail with an authentication failure `4xx`.", type = "string" }, },
          { key_in_header = { description = "If enabled (default), the plugin reads the request header and tries to find the key in it.", type = "boolean", required = true, default = true }, },
          { key_in_query = { description = "If enabled (default), the plugin reads the query parameter in the request and tries to find the key in it.", type = "boolean", required = true, default = true }, },
          { key_in_body = { description = "If enabled, the plugin reads the request body. Supported MIME types: `application/www-form-urlencoded`, `application/json`, and `multipart/form-data`.", type = "boolean", required = true, default = false }, },
          { run_on_preflight = { description = "A boolean value that indicates whether the plugin should run (and try to authenticate) on `OPTIONS` preflight requests. If set to `false`, then `OPTIONS` requests are always allowed.", type = "boolean", required = true, default = true }, },
        },
    }, },
  },
}
