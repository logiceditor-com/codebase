--------------------------------------------------------------------------------
-- schema.lua: apigen configuration file format
--------------------------------------------------------------------------------

local load_tools_cli_data_schema
      = import 'pk-core/tools_cli_config.lua'
      {
        'load_tools_cli_data_schema'
      }

local common_tool_config_schema_chunk
      = import 'pk-tools.project-config.schema-common'
      {
        'common_tool_config_schema_chunk'
      }

local create_config_schema

do
  local schema_chunk = function()
    cfg:root
    {
      common_tool_config_schema_chunk();

      cfg:node "apigen"
      {
        cfg:boolean "keep_tmp" { default = false; };

        cfg:variant "action"
        {
          variants =
          {
            ["help"] =
            {
              -- No parameters
            };

            ["dump_nodes"] =
            {
              cfg:path "out_filename" { default = "-" }; -- default stdout
              cfg:boolean "with_indent" { default = true };
              cfg:boolean "with_names" { default = true };
            };

            ["check"] =
            {
              -- No parameters
            };

            ["dump_urls"] =
            {
              -- No parameters
            };

            ["dump_markdown_docs"] =
            {
              -- No parameters
            };

            ["generate_documents"] =
            {
              -- No parameters
            };

            ["update_handlers"] =
            {
              -- No parameters
            };

            ["update_all"] =
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
