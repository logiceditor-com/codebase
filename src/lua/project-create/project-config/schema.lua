--------------------------------------------------------------------------------
-- schema.lua: project-create configuration file format
--------------------------------------------------------------------------------

local load_tools_cli_data_schema
      = import 'pk-core/tools_cli_config.lua'
      {
        'load_tools_cli_data_schema'
      }

local create_config_schema
do
  local schema_chunk = function()
    cfg:root
    {

--------------------------------------------------------------------------------

      cfg:node "project_create"
      {
        cfg:existing_path "metamanifest_path";
        cfg:path "root_project_path";
        cfg:boolean "debug" { default = true }; -- TODO: remove
        cfg:boolean "force" { default = true }; -- TODO: remove
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
