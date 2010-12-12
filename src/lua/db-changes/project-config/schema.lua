--------------------------------------------------------------------------------
-- schema.lua: db-changes configuration file format
--------------------------------------------------------------------------------

do
  local common_tool_config_schema_chunk
    = import 'pk-tools/schema-common.lua' { 'common_tool_config_schema_chunk' }

  schema_chunk = function()
    cfg:root
    {
      common_tool_config_schema_chunk();

      cfg:node "db_changes"
      {
        cfg:variant "action"
        {
          variants =
          {
            ["help"] =
            {
              -- No parameters
            };

            ["initialize_db"] =
            {
              cfg:non_empty_string "db_name";
              cfg:boolean "force" { default = false };
            };

            ["list_changes"] =
            {
              -- No parameters
            };

            ["upload_changes"] =
            {
              -- No parameters
            };

            ["revert_changes"] =
            {
              cfg:non_empty_string "stop_at_uuid";
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
