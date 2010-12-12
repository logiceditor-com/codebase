--------------------------------------------------------------------------------
-- schema.lua: dbgen configuration file format
--------------------------------------------------------------------------------

do
  local common_tool_config_schema_chunk
    = import 'pk-tools/schema-common.lua' { 'common_tool_config_schema_chunk' }

  schema_chunk = function()
    cfg:root
    {
      common_tool_config_schema_chunk();

      cfg:node "dbgen"
      {
        cfg:variant "action"
        {
          variants =
          {
            ["help"] =
            {
              -- No parameters
            };

            ["check"] =
            {
              -- No parameters
            };

            ["dottify"] =
            {
              -- No parameters
            };

            ["update_changes"] =
            {
              cfg:boolean "force" { default = false };
            };

            ["update_tables"] =
            {
              cfg:boolean "force" { default = false };
            };

            ["update_tables_test_data"] =
            {
              cfg:boolean "force" { default = false };
            };

            ["update_db"] =
            {
              cfg:boolean "force" { default = false };
            };

            ["update_data_changeset"] =
            {
              cfg:boolean "force" { default = false };
              cfg:non_empty_string "table_name";
              cfg:boolean "ignore_in_tests" { default = true };
            };
          };
        };
      };

    }
  end

  create_config_schema = function()
    return load_tools_cli_data_schema(
        schema_chunk
      )
  end
end

return
{
  create_config_schema = create_config_schema;
}
