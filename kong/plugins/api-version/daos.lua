-- daos.lua
local typedefs = require "kong.db.schema.typedefs"


return {
 -- this plugin only results in one custom DAO, named `keyauth_credentials`:
 {
   name                  = "keyauth_credentials", -- the actual table in the database
   endpoint_key          = "key",
   primary_key           = { "id" },
   cache_key             = { "key" },
   generate_admin_api    = true,
   admin_api_name        = "key-auths",
   admin_api_nested_name = "key-auth",
   fields = {
     {
       -- a value to be inserted by the DAO itself
       -- (think of serial id and the uniqueness of such required here)
       id = typedefs.uuid,
     },
     {
       -- also interted by the DAO itself
       created_at = typedefs.auto_timestamp_s,
     },
     {
       -- a foreign key to a consumer's id
       consumer = {
         type      = "foreign",
         reference = "consumers",
         default   = ngx.null,
         on_delete = "cascade",
       },
     },
     {
       -- a unique API key
       key = {
         type      = "string",
         required  = false,
         unique    = true,
         auto      = true,
       },
     },
   },
 },
}
