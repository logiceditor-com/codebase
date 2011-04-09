--------------------------------------------------------------------------------
-- config/schema-schema_tool.lua: schema tool configuration format schema
--------------------------------------------------------------------------------

local load_tools_cli_data_schema
      = import 'pk-core/tools_cli_config.lua'
      {
        'load_tools_cli_data_schema'
      }

--------------------------------------------------------------------------------

local create_config_schema
do
  local schema_chunk = function()
  cfg:root
  {
    cfg:node "deploy_rocks"
    {
      cfg:existing_path "project_path";
      cfg:existing_path "manifest_path";
      cfg:string "cluster";
      cfg:variant "action"
      {
        variants =
        {
          ["help"] = { };
          ["check_config"] = { };
          ["dump_config"] = { };

          ["deploy_from_code"] = { };

          ["deploy_from_versions_file"] = {
            cfg:existing_path "version_file";
          };

          ["partial_deploy_from_versions_file"] = {
            cfg:existing_path "version_file";
            cfg:string "machine_name";
          };
        };
      };
      cfg:boolean "debug" { default = false };
      cfg:boolean "dry-run" { default = false };
    };
  }
  end

  create_config_schema = function()
    return load_tools_cli_data_schema(
        schema_chunk
      )
  end
end

--------------------------------------------------------------------------------

return
{
  create_config_schema = create_config_schema;
}
