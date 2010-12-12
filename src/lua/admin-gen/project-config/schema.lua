--------------------------------------------------------------------------------
-- schema.lua: admin-gen configuration file format
--------------------------------------------------------------------------------

do
  local common_tool_config_schema_chunk
    = import 'pk-tools/schema-common.lua' { 'common_tool_config_schema_chunk' }

  schema_chunk = function()
    cfg:root
    {
      common_tool_config_schema_chunk();

      cfg:node "admin_gen"
      {
        intedmediate =
        {
          cfg:path "api_schema_dir";
          cfg:path "js_dir";
        };

        cfg:variant "action"
        {
          variants =
          {
            ["help"] =
            {
              -- No parameters
            };

            ["generate_admin_api_schema"] =
            {
              -- No parameters
            };

            ["generate_js"] =
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
