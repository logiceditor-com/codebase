--------------------------------------------------------------------------------
-- schema.lua: project-create configuration file format
-- This file is a part of pk-project-tools library
-- Copyright (c) Alexander Gladysh <ag@logiceditor.com>
-- Copyright (c) Dmitry Potapov <dp@logiceditor.com>
-- See file `COPYRIGHT` for the license
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
        cfg:existing_path "PROJECT_PATH" { default = "." };
        cfg:existing_path "metamanifest_path";
        cfg:path "root_project_path";
        cfg:existing_path "root_template_path" { default = "." };
        cfg:boolean "debug" { default = false };
      };

--------------------------------------------------------------------------------

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
