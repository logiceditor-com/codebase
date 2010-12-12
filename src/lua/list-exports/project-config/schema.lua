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

      cfg:node "list_exports"
      {
        cfg:variant "action"
        {
          variants =
          {
            ["help"] =
            {
              -- No parameters
            };

            ["list_all"] =
            {
              -- No parameters
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
