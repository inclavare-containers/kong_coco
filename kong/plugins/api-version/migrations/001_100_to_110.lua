return {
  postgres = {
    up = [[
      DO $$
      BEGIN
        ALTER TABLE IF EXISTS ONLY "my_plugin_table" ADD "cache_key" TEXT UNIQUE;
      EXCEPTION WHEN DUPLICATE_COLUMN THEN
        -- Do nothing, accept existing state
      END;
    $$;
    ]],
    teardown = function(connector, helpers)
      assert(connector:connect_migrations())
      assert(connector:query([[
        DO $$
        BEGIN
          ALTER TABLE IF EXISTS ONLY "my_plugin_table" DROP "col1";
        EXCEPTION WHEN UNDEFINED_COLUMN THEN
          -- Do nothing, accept existing state
        END$$;
      ]]))
    end,
  }
}