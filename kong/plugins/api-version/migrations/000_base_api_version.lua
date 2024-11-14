-- `<plugin_name>/migrations/000_base_my_plugin.lua`
return {
  postgres = {
    up = [[
      CREATE TABLE IF NOT EXISTS "my_plugin_table" (
        "id"           UUID                         PRIMARY KEY,
        "created_at"   TIMESTAMP WITHOUT TIME ZONE,
        "col1"         TEXT
      );

      DO $$
      BEGIN
        CREATE INDEX IF NOT EXISTS "my_plugin_table_col1"
                                ON "my_plugin_table" ("col1");
      EXCEPTION WHEN UNDEFINED_COLUMN THEN
        -- Do nothing, accept existing state
      END$$;
    ]],
  }
}
